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
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-mas.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-ing.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-ocbc.yaml --output=crypto-config
./fabric-samples/bin/cryptogen generate --config=./organizations/cryptogen/crypto-config-dbs.yaml --output=crypto-config

# Fix directory paths in config files - replace Windows backslashes with forward slashes
Write-Host "Fixing path separators in crypto-config..."
Get-ChildItem -Path crypto-config -Recurse -File | Where-Object { $_.Extension -match "\.ya?ml|\.json|\.pem|\.crt|\.key" } | ForEach-Object {
    (Get-Content $_.FullName -Raw) -replace '\\', '/' | Set-Content $_.FullName
}

# Generate genesis block
Write-Host "Generating genesis block..."
./fabric-samples/bin/configtxgen -profile BankingOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block -configPath ./configtx

# Generate channel tx
Write-Host "Generating channel transaction..."
./fabric-samples/bin/configtxgen -profile BankingChannel -outputCreateChannelTx ./channel-artifacts/hlftffv1.tx -channelID hlftffv1 -configPath ./configtx

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
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer channel create -o orderer.example.com:7050 -c hlftffv1 -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/hlftffv1.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Wait for channel creation to complete
Write-Host "Waiting for channel creation to complete..."
Start-Sleep -Seconds 5

# Join peer0.mas to channel
Write-Host "Joining peer0.mas to channel..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer channel join -b hlftffv1.block

# Join peer0.ing to channel
Write-Host "Joining peer0.ing to channel..."
docker exec -e CORE_PEER_LOCALMSPID="INGMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/users/Admin@ing.example.com/msp -e CORE_PEER_ADDRESS=peer0.ing.example.com:8051 cli peer channel join -b hlftffv1.block

# Join peer0.ocbc to channel
Write-Host "Joining peer0.ocbc to channel..."
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 cli peer channel join -b hlftffv1.block

# Join peer0.dbs to channel
Write-Host "Joining peer0.dbs to channel..."
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 cli peer channel join -b hlftffv1.block

# Verify channel membership for all peers
Write-Host "Verifying channel membership for all peers..."
Write-Host "`nVerifying peer0.mas..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer channel list

Write-Host "`nVerifying peer0.ing..."
docker exec -e CORE_PEER_LOCALMSPID="INGMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/users/Admin@ing.example.com/msp -e CORE_PEER_ADDRESS=peer0.ing.example.com:8051 cli peer channel list

Write-Host "`nVerifying peer0.ocbc..."
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 cli peer channel list

Write-Host "`nVerifying peer0.dbs..."
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 cli peer channel list

docker network create fabric_network
Write-Host "`nNetwork setup complete!"