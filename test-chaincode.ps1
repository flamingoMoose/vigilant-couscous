# Test Chaincode Transactions
# Run this after full-network-setup.ps1 completes successfully

# Create a new banking asset
Write-Host "Creating a new asset from MAS..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C hlftffv1 -n asset-transfer --peerAddresses peer0.mas.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt --peerAddresses peer0.ing.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -c '{"function":"CreateAsset","Args":["bond001","SGD",1000,"MAS",10000000]}'

Write-Host "Waiting for transaction completion..."
Start-Sleep -Seconds 5

# Query the specific asset
Write-Host "Querying bond001..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{"Args":["ReadAsset","bond001"]}'

# Transfer the asset to DBS
Write-Host "Transferring bond001 from MAS to DBS..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C hlftffv1 -n asset-transfer --peerAddresses peer0.mas.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt --peerAddresses peer0.ing.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -c '{"function":"TransferAsset","Args":["bond001","DBS"]}'

Write-Host "Waiting for transaction completion..."
Start-Sleep -Seconds 5

# Verify the transfer
Write-Host "Verifying transfer of bond001 to DBS..."
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{"Args":["ReadAsset","bond001"]}'

# Create an asset from OCBC
Write-Host "Creating a new asset from OCBC..."
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C hlftffv1 -n asset-transfer --peerAddresses peer0.ocbc.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt --peerAddresses peer0.ing.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -c '{"function":"CreateAsset","Args":["loan001","USD",500,"OCBC",5000000]}'

Write-Host "Waiting for transaction completion..."
Start-Sleep -Seconds 5

# Query all assets to see both transactions
Write-Host "Querying all assets to see all transactions..."
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{"Args":["GetAllAssets"]}'

Write-Host "Chaincode testing complete!"