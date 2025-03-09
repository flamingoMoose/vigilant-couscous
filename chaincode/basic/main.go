package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	flChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating federated-learning chaincode: %v", err)
	}

	if err := flChaincode.Start(); err != nil {
		log.Panicf("Error starting federated-learning chaincode: %v", err)
	}
}