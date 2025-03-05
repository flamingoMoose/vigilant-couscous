#!/bin/bash
# Hyperledger Fabric Network Setup Script for Mac/Linux

# Exit on first error
set -e

# Display commands being run
set -x

# Clean up existing resources
echo "Stopping existing containers..."
docker-compose -f docker/docker-compose.yaml down --volumes --remove-orphans

# Clean up existing volumes
echo "Cleaning up volumes..."
docker volume prune -f

# Clean up existing crypto material
echo "Cleaning up crypto materials..."
rm -rf crypto-config
rm -rf channel-artifacts
mkdir -p crypto-config
mkdir -p channel-artifacts

# Generate crypto material
echo "Generating crypto material..."
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output=crypto-config

# Fix any Windows line endings if files were checked out on Windows
find crypto-config -type f -exec dos2unix {} \; 2>/dev/null || true

# Generate genesis block
echo "Generating genesis block..."
./fabric-samples/bin/configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block -configPath ./configtx

# Generate channel tx
echo "Generating channel transaction..."
./fabric-samples/bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel -configPath ./configtx

# Start the network
echo "Starting the network..."
docker-compose -f docker/docker-compose.yaml up -d

# Wait for basic container startup
echo "Waiting for basic container startup (10 seconds)..."
sleep 10

# Verify orderer container is running
echo "Verifying orderer container is running..."
docker ps | grep orderer.example.com
echo "Giving orderer more time to stabilize (15 seconds)..."
sleep 15

# Fix TLS certificate paths inside CLI container
echo "Fixing TLS certificate paths in CLI container..."
docker exec cli mkdir -p /tmp/fixed-certs
docker exec cli bash -c 'find /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto -name "*.pem" -o -name "*.crt" > /tmp/cert_files.txt'
docker exec cli bash -c 'cat /tmp/cert_files.txt | while read file; do cp "$file" "$file.fixed"; done'
docker exec cli bash -c 'cat /tmp/cert_files.txt | while read file; do mv "$file.fixed" "$file"; done'

# Create channel with proper MSP configuration
echo "Creating channel with proper MSP configuration..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  cli peer channel create -o orderer.example.com:7050 -c mychannel \
  -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/mychannel.tx \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Wait for channel creation to complete
echo "Waiting for channel creation to complete..."
sleep 5

# Join peer0.org1 to channel
echo "Joining peer0.org1 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  cli peer channel join -b mychannel.block

# Join peer1.org1 to channel
echo "Joining peer1.org1 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 \
  cli peer channel join -b mychannel.block

# Join peer0.org2 to channel
echo "Joining peer0.org2 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
  cli peer channel join -b mychannel.block

# Join peer1.org2 to channel
echo "Joining peer1.org2 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 \
  cli peer channel join -b mychannel.block

# Verify channel membership
echo "Verifying channel membership for peer0.org1..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  cli peer channel list

echo "Network setup complete!"