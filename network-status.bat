@echo off
echo =====================================================================
echo                HYPERLEDGER FABRIC NETWORK STATUS CHECK               
echo =====================================================================

echo.
echo [1] Checking Docker containers...
docker ps --format "table {{.Names}}\t{{.Status}}"

echo.
echo [2] Checking peer0.org1 channel membership...
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 cli peer channel list

echo.
echo [3] Checking peer0.org2 channel membership...
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 cli peer channel list

echo.
echo [4] Checking channel information...
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 cli peer channel getinfo -c mychannel

echo.
echo [5] Checking orderer status...
docker exec orderer.example.com ps -ef

echo.
echo Network status check completed!
pause