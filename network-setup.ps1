# Setup Hyperledger Fabric Network using PowerShell
# This avoids Git Bash path translation issues

# Stop any existing containers
Write-Host "Stopping existing containers..."
docker-compose -f docker/docker-compose.yaml down --volumes --remove-orphans

# Clean up existing volumes
Write-Host "Cleaning up volumes..."
docker volume prune -f

# Clean up existing crypto material
Remove-Item -Path crypto-config -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path channel-artifacts -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path crypto-config -Force
New-Item -ItemType Directory -Path channel-artifacts -Force

# Generate crypto material
Write-Host "Generating crypto material..."
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output=crypto-config

# Fix directory paths in config files - replace Windows backslashes with forward slashes
Write-Host "Fixing path separators in crypto-config..."
Get-ChildItem -Path crypto-config -Recurse -File | Where-Object { $_.Extension -match "\.ya?ml|\.json|\.pem|\.crt|\.key" } | ForEach-Object {
    (Get-Content $_.FullName -Raw) -replace '\\', '/' | Set-Content $_.FullName
}

# Generate genesis block
Write-Host "Generating genesis block..."
./fabric-samples/bin/configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block -configPath ./configtx

# Generate channel tx
Write-Host "Generating channel transaction..."
./fabric-samples/bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel -configPath ./configtx

# Start the network
Write-Host "Starting the network..."
docker-compose -f docker/docker-compose.yaml up -d

# Wait longer for containers to fully start
Write-Host "Waiting for basic container startup (10 seconds)..."
Start-Sleep -Seconds 10

# Verify orderer is running and give it more time to stabilize
Write-Host "Verifying orderer container is running..."
docker ps | Select-String "orderer.example.com"
Write-Host "Giving orderer more time to stabilize (15 seconds)..."
Start-Sleep -Seconds 15

# Fix TLS certificate paths inside CLI container
Write-Host "Fixing TLS certificate paths in CLI container..."
docker exec cli mkdir -p /tmp/fixed-certs

# Fix using simpler commands to avoid quotation issues
docker exec cli bash -c 'find /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto -name "*.pem" -o -name "*.crt" > /tmp/cert_files.txt'
docker exec cli bash -c 'cat /tmp/cert_files.txt | while read file; do cp "$file" "$file.fixed"; done'
docker exec cli bash -c 'cat /tmp/cert_files.txt | while read file; do mv "$file.fixed" "$file"; done'

# Create channel with proper MSP configuration
Write-Host "Creating channel with proper MSP configuration..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 cli peer channel create -o orderer.example.com:7050 -c mychannel -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/mychannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Wait for channel creation to complete
Write-Host "Waiting for channel creation to complete..."
Start-Sleep -Seconds 5

# Join peer0.org1 to channel
Write-Host "Joining peer0.org1 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 cli peer channel join -b mychannel.block

# Join peer1.org1 to channel
Write-Host "Joining peer1.org1 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 cli peer channel join -b mychannel.block

# Join peer0.org2 to channel
Write-Host "Joining peer0.org2 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 cli peer channel join -b mychannel.block

# Join peer1.org2 to channel
Write-Host "Joining peer1.org2 to channel..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 cli peer channel join -b mychannel.block

# Verify channel membership for all peers
Write-Host "Verifying channel membership for all peers..."
Write-Host "`nVerifying peer0.org1..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 cli peer channel list

Write-Host "`nVerifying peer1.org1..."
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer1.org1.example.com:8051 cli peer channel list

Write-Host "`nVerifying peer0.org2..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 cli peer channel list

Write-Host "`nVerifying peer1.org2..."
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer1.org2.example.com:10051 cli peer channel list

Write-Host "`nNetwork setup complete!"