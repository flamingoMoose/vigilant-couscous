#!/bin/bash

# Disable Git Bash auto path conversion
export MSYS_NO_PATHCONV=1

# Helper function for running chaincode commands
run_chaincode() {
    echo -e "\n🔹 Running: $1"
    eval "$1"
    echo "✅ Done."
    sleep 3
}

# Training Round ID
ROUND_ID="round1"

# 1️⃣ Create a Training Round
run_chaincode "docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C hlftffv1 -n asset-transfer \
    --peerAddresses peer0.mas.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt \
    --peerAddresses peer0.ing.example.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt \
    --peerAddresses peer0.ocbc.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt \
    -c '{\"function\":\"CreateTrainingRound\",\"Args\":[\"$ROUND_ID\",\"MAS\",\"Federated Learning Test Round\"]}'"

# 2️⃣ Query Training Round
run_chaincode "docker exec cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{\"function\":\"GetTrainingRound\",\"Args\":[\"$ROUND_ID\"]}'"

# 3️⃣ Record Participation
run_chaincode "docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C hlftffv1 -n asset-transfer \
    --peerAddresses peer0.mas.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt \
    --peerAddresses peer0.ing.example.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt \
    --peerAddresses peer0.ocbc.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt \
    -c '{\"function\":\"RecordParticipation\",\"Args\":[\"p1\",\"$ROUND_ID\",\"MAS\",\"1710084765\",\"true\"]}'"

# 4️⃣ Get Participation Records
run_chaincode "docker exec cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{\"function\":\"GetParticipationRecordsByRound\",\"Args\":[\"$ROUND_ID\"]}'"

# 5️⃣ Record Model Contribution
run_chaincode "docker exec cli peer chaincode invoke \
    -o orderer.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C hlftffv1 -n asset-transfer \
    --peerAddresses peer0.mas.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mas.example.com/peers/peer0.mas.example.com/tls/ca.crt \
    --peerAddresses peer0.ing.example.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ing.example.com/peers/peer0.ing.example.com/tls/ca.crt \
    --peerAddresses peer0.ocbc.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ocbc.example.com/peers/peer0.ocbc.example.com/tls/ca.crt \
    -c '{\"function\":\"RecordModelContribution\",\"Args\":[\"c1\",\"$ROUND_ID\",\"MAS\",\"hash123\",\"minio://models/$ROUND_ID/mas.weights.npy\",\"{\\\"accuracy\\\":0.95}\",\"{\\\"loss\\\":\\\"0.1\\\"}\"]}'"

# 6️⃣ Get Model Contributions
run_chaincode "docker exec cli peer chaincode query -C hlftffv1 -n asset-transfer -c '{\"function\":\"GetContributionsByRound\",\"Args\":[\"$ROUND_ID\"]}'"

echo -e "\n🎉 All tests completed successfully!"
