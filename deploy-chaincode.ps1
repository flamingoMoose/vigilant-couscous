# Better chaincode deployment that works with your existing chaincode file
# Run after network setup is complete

# Check that the network is running
Write-Host "Checking that the network is running..."
$CONTAINERS = docker ps --format "{{.Names}}" | Select-String -Pattern "peer0|orderer"
if ($CONTAINERS.Count -lt 5) {
    Write-Host "Error: Network containers are not all running. Please run network setup first."
    exit 1
}

# Verify chaincode file exists
if (-not (Test-Path -Path chaincode/basic/asset-transfer.go)) {
    Write-Host "Error: Chaincode file not found at chaincode/basic/asset-transfer.go"
    exit 1
}

# Create a proper chaincode structure with dependencies
Write-Host "Creating chaincode structure with dependencies..."
docker exec cli bash -c "mkdir -p /opt/gopath/src/github.com/asset-transfer/"

# Copy the chaincode
Write-Host "Copying chaincode to container..."
docker cp chaincode/basic/asset-transfer.go cli:/opt/gopath/src/github.com/asset-transfer/

# Create a go.mod file with dependencies
$GO_MOD_CONTENT = @"
module github.com/asset-transfer

go 1.18

require github.com/hyperledger/fabric-contract-api-go v1.2.1

require (
	github.com/go-openapi/jsonpointer v0.19.5 // indirect
	github.com/go-openapi/jsonreference v0.20.0 // indirect
	github.com/go-openapi/spec v0.20.8 // indirect
	github.com/go-openapi/swag v0.21.1 // indirect
	github.com/gobuffalo/envy v1.10.1 // indirect
	github.com/gobuffalo/packd v1.0.1 // indirect
	github.com/gobuffalo/packr v1.30.1 // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/hyperledger/fabric-chaincode-go v0.0.0-20230228194215-b84622ba6a7a // indirect
	github.com/hyperledger/fabric-protos-go v0.3.0 // indirect
	github.com/joho/godotenv v1.4.0 // indirect
	github.com/josharian/intern v1.0.0 // indirect
	github.com/mailru/easyjson v0.7.7 // indirect
	github.com/rogpeppe/go-internal v1.8.1 // indirect
	github.com/xeipuuv/gojsonpointer v0.0.0-20190905194746-02993c407bfb // indirect
	github.com/xeipuuv/gojsonreference v0.0.0-20180127040603-bd5ef7bd5415 // indirect
	github.com/xeipuuv/gojsonschema v1.2.0 // indirect
	golang.org/x/net v0.7.0 // indirect
	golang.org/x/sys v0.5.0 // indirect
	golang.org/x/text v0.7.0 // indirect
	google.golang.org/genproto v0.0.0-20230110181048-76db0878b65f // indirect
	google.golang.org/grpc v1.53.0 // indirect
	google.golang.org/protobuf v1.28.1 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
)
"@

# Create go.mod file
Write-Host "Creating go.mod with dependencies..."
docker exec cli bash -c "echo '$GO_MOD_CONTENT' > /opt/gopath/src/github.com/asset-transfer/go.mod"

# Download dependencies and verify go.mod setup
Write-Host "Downloading Go dependencies..."
docker exec -w /opt/gopath/src/github.com/asset-transfer cli bash -c "go mod tidy"
docker exec -w /opt/gopath/src/github.com/asset-transfer cli bash -c "go mod verify"

# Package the chaincode
Write-Host "Packaging chaincode..."
docker exec -w /opt/gopath/src cli bash -c "peer lifecycle chaincode package asset-transfer.tar.gz --path github.com/asset-transfer --lang golang --label asset-transfer_1.0"

# Install on all peers
Write-Host "Installing on peer0.mas..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 -w /opt/gopath/src cli peer lifecycle chaincode install asset-transfer.tar.gz

Write-Host "Installing on peer0.ing..."
docker exec -e CORE_PEER_LOCALMSPID="INGMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/users/Admin@ing.example.com/msp -e CORE_PEER_ADDRESS=peer0.ing.example.com:8051 -w /opt/gopath/src cli peer lifecycle chaincode install asset-transfer.tar.gz

Write-Host "Installing on peer0.ocbc..."
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 -w /opt/gopath/src cli peer lifecycle chaincode install asset-transfer.tar.gz

Write-Host "Installing on peer0.dbs..."
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 -w /opt/gopath/src cli peer lifecycle chaincode install asset-transfer.tar.gz

# Get package ID
Write-Host "Retrieving package ID..."
$QUERY_INSTALLED = docker exec cli peer lifecycle chaincode queryinstalled
Write-Host $QUERY_INSTALLED

# Use a more robust method to extract the package ID
$PACKAGE_ID = $null
$MATCH = [regex]::Match($QUERY_INSTALLED, "Package ID: (asset-transfer_1.0:[a-zA-Z0-9]+)")
if ($MATCH.Success) {
    $PACKAGE_ID = $MATCH.Groups[1].Value
}

if (-not $PACKAGE_ID) {
    Write-Host "Error: Could not get package ID. Please check the chaincode installation."
    exit 1
}

Write-Host "Package ID: $PACKAGE_ID"

# Approve from each organization
Write-Host "Approving from MASMSP..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID hlftffv1 --name asset-transfer --version 1.0 --package-id $PACKAGE_ID --sequence 1 --init-required

Write-Host "Approving from INGMSP..."
docker exec -e CORE_PEER_LOCALMSPID="INGMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/users/Admin@ing.example.com/msp -e CORE_PEER_ADDRESS=peer0.ing.example.com:8051 cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID hlftffv1 --name asset-transfer --version 1.0 --package-id $PACKAGE_ID --sequence 1 --init-required

Write-Host "Approving from OCBCMSP..."
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID hlftffv1 --name asset-transfer --version 1.0 --package-id $PACKAGE_ID --sequence 1 --init-required

Write-Host "Approving from DBSMSP..."
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID hlftffv1 --name asset-transfer --version 1.0 --package-id $PACKAGE_ID --sequence 1 --init-required

# Check commit readiness
Write-Host "Checking commit readiness..."
docker exec cli peer lifecycle chaincode checkcommitreadiness --channelID hlftffv1 --name asset-transfer --version 1.0 --sequence 1 --output json --init-required

# Commit to channel
Write-Host "Committing chaincode definition..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID hlftffv1 --name asset-transfer --version 1.0 --sequence 1 --init-required --peerAddresses peer0.mas.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt --peerAddresses peer0.ing.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt

# Initialize chaincode
Write-Host "Initializing chaincode..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --isInit -C hlftffv1 -n asset-transfer --peerAddresses peer0.mas.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt --peerAddresses peer0.ing.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'

# Wait for transaction to be committed
Write-Host "Waiting for initialization to complete..."
Start-Sleep -Seconds 5

# Query all assets to verify initialization
Write-Host "Querying all assets to verify initialization..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{"Args":["GetAllAssets"]}'

Write-Host "`nChaincode deployment complete!"