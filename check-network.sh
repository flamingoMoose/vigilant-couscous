#!/bin/bash
# Simple Hyperledger Fabric Network Status Check Script for Mac/Linux

# Color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Header
echo -e "${YELLOW}=====================================================================${NC}"
echo -e "${YELLOW}               HYPERLEDGER FABRIC NETWORK STATUS CHECK               ${NC}"
echo -e "${YELLOW}=====================================================================${NC}"

# Check if Docker is running
echo -e "\n${YELLOW}[1] Checking if Docker is running...${NC}"
if docker info > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker is running${NC}"
else
    echo -e "${RED}✗ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check all containers
echo -e "\n${YELLOW}[2] Checking container status...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E 'peer|orderer|cli'

# Check channel membership for each peer
echo -e "\n${YELLOW}[3] Checking channel membership for all peers...${NC}"

# peer0.org1
echo -e "\n${YELLOW}Checking peer0.org1...${NC}"
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    cli peer channel list

# peer0.org2
echo -e "\n${YELLOW}Checking peer0.org2...${NC}"
docker exec -e CORE_PEER_LOCALMSPID="Org2MSP" -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    cli peer channel list

# Get channel information
echo -e "\n${YELLOW}[4] Getting channel information...${NC}"
docker exec -e CORE_PEER_LOCALMSPID="Org1MSP" -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    cli peer channel getinfo -c mychannel

# Check orderer status
echo -e "\n${YELLOW}[5] Checking orderer status...${NC}"
docker exec orderer.example.com ps -ef | grep orderer

echo -e "\n${GREEN}Network status check completed!${NC}"