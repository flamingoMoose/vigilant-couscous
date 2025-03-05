@echo off
echo =====================================================================
echo                HYPERLEDGER FABRIC NETWORK STATUS CHECK               
echo =====================================================================

echo.
echo [1] Checking Docker containers...
docker ps --format "table {{.Names}}\t{{.Status}}"

echo.
echo [2] Checking peer0.mas channel membership...
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer channel list

echo.
echo [3] Checking peer0.ing channel membership...
docker exec -e CORE_PEER_LOCALMSPID="INGMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/users/Admin@ing.example.com/msp -e CORE_PEER_ADDRESS=peer0.ing.example.com:8051 cli peer channel list

echo.
echo [4] Checking peer0.ocbc channel membership...
docker exec -e CORE_PEER_LOCALMSPID="OCBCMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/users/Admin@ocbc.example.com/msp -e CORE_PEER_ADDRESS=peer0.ocbc.example.com:9051 cli peer channel list

echo.
echo [5] Checking peer0.dbs channel membership...
docker exec -e CORE_PEER_LOCALMSPID="DBSMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/peers/peer0.dbs.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dbs.example.com/users/Admin@dbs.example.com/msp -e CORE_PEER_ADDRESS=peer0.dbs.example.com:10051 cli peer channel list

echo.
echo [6] Checking channel information...
docker exec -e CORE_PEER_LOCALMSPID="MASMSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/users/Admin@mas.example.com/msp -e CORE_PEER_ADDRESS=peer0.mas.example.com:7051 cli peer channel getinfo -c hlftffv1

echo.
echo [7] Checking orderer status...
docker exec orderer.example.com ps -ef

echo.
echo Network status check completed!
pause