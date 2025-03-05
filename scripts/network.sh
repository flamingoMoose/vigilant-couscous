#!/bin/bash

# Import environment variables
source ./.env

# Function to print the usage message
printHelp() {
  echo "Usage: "
  echo "  network.sh <Mode>"
  echo "    <Mode>"
  echo "      - 'up' - bring up the network with docker-compose"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'restart' - restart the network"
  echo "      - 'createChannel' - create and join a channel"
  echo "      - 'deployCC' - deploy the chaincode"
}

# Function to generate crypto material using cryptogen
generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. Make sure you have Fabric binaries in your PATH."
    exit 1
  fi
  
  echo "Creating Organizational Certificates"
  
  mkdir -p ./crypto-config
  
  echo "Creating crypto material for orderer org..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="./crypto-config"
  echo "Creating crypto material for org1..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="./crypto-config"
  echo "Creating crypto material for org2..."
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="./crypto-config"
}

# Function to generate the genesis block
generateGenesisBlock() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. Make sure you have Fabric binaries in your PATH."
    exit 1
  fi

  echo "Generating Genesis Block"
  
  mkdir -p ./channel-artifacts
  
  echo "Creating genesis block..."
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block -configPath ./configtx
}

# Function to bring up the network
networkUp() {
  # Create channel artifacts directory
  mkdir -p ./channel-artifacts
  
  # Check if crypto materials are already generated
  if [ ! -d "./crypto-config" ]; then
    echo "No crypto material found. Generating..."
    generateCerts
    generateGenesisBlock
  fi
  
  # Start the docker containers with explicit environment variable passing
  echo "Starting the network..."
  FABRIC_VERSION=$FABRIC_VERSION CA_VERSION=$CA_VERSION COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
  docker-compose -f ./docker/docker-compose.yaml up -d
  
  # Wait for containers to start
  sleep 5
  
  echo "Network is up"
}

# Function to bring down the network
networkDown() {
  echo "Stopping the network..."
  docker-compose -f ./docker/docker-compose.yaml down --volumes --remove-orphans
  
  # Remove volumes
  docker volume rm $(docker volume ls -q | grep peer) 2>/dev/null || true
  docker volume rm $(docker volume ls -q | grep orderer) 2>/dev/null || true
  
  # Remove crypto material if requested
  if [ "$1" = "delete" ]; then
    echo "Removing generated artifacts..."
    rm -rf ./crypto-config
    rm -rf ./channel-artifacts
  fi
  
  echo "Network is down"
}

# Function to create the channel
createChannel() {
  echo "Generating channel transaction..."
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME -configPath ./configtx
  
  echo "Creating channel..."
  # Use docker exec with direct paths inside the container
  docker exec cli bash -c "peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
  
  echo "Joining peer0.org1 to the channel..."
  docker exec cli bash -c "peer channel join -b ${CHANNEL_NAME}.block"
  
  echo "Joining peer0.org2 to the channel..."
  docker exec -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    cli bash -c "peer channel join -b ${CHANNEL_NAME}.block"
  
  echo "Channel '$CHANNEL_NAME' created successfully"
}

# Deploy chaincode
deployCC() {
  echo "Deploying chaincode is a more complex process with Fabric 2.x"
  echo "We'll implement this later with lifecycle management"
}

# Process command line arguments
if [ $# -lt 1 ]; then
  printHelp
  exit 0
fi

MODE=$1

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then
  networkDown
elif [ "${MODE}" == "restart" ]; then
  networkDown
  networkUp
elif [ "${MODE}" == "generate" ]; then
  generateCerts
  generateGenesisBlock
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
else
  printHelp
  exit 1
fi