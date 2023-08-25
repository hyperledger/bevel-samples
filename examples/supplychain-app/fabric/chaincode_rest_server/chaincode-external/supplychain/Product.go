package supplychain

import (
	"bytes"
	"encoding/json"
	"examples/supplychain-app/fabric/chaincode_rest_server/chaincode-external/common"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-protos-go/peer"
)

// createProduct creates a new Product on the blockchain using the  with the supplied ID
func (s *SmartContract) createProduct(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	identity, err := common.GetInvokerIdentity(stub)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting invoker identity: %s\n", err.Error()))
	}
	log.Printf("%+v\n", identity.Cert.Subject.String())

	if !identity.CanInvoke("createProduct") {
		return peer.Response{
			Status:  403,
			Message: "You are not authorized to perform this transaction, cannot invoke createProduct",
		}
	}

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// Create ProductRequest struct from input JSON.
	argBytes := []byte(args[0])
	var request common.ProductRequest
	if err := json.Unmarshal(argBytes, &request); err != nil {
		return shim.Error(err.Error())
	}
	//Check if product  state using id as key exsists
	testProductAsBytes, err := stub.GetState(request.ID)
	if err != nil {
		return shim.Error(err.Error())
	}
	// Return 403 if item exisits
	if len(testProductAsBytes) != 0 {
		return peer.Response{
			Status:  403,
			Message: fmt.Sprintf("Existing Product %s Found", args[0]),
		}
	}

	product := common.Product{
		ID:           request.ID,
		Type:         "product",
		Name:         request.ProductName,
		Health:       "",
		Metadata:     request.Metadata,
		Location:     request.Location,
		Sold:         false,
		Recalled:     false,
		ContainerID:  "",
		Custodian:    identity.Cert.Subject.String(),
		Timestamp:    int64(s.clock.Now().UTC().Unix()),
		Participants: request.Participants,
	}

	product.Participants = append(product.Participants, identity.Cert.Subject.String())

	// Put new Product onto blockchain
	productAsBytes, _ := json.Marshal(product)
	if err := stub.PutState(product.ID, productAsBytes); err != nil {
		return shim.Error(err.Error())
	}

	response := map[string]interface{}{
		"generatedID": product.ID,
	}
	bytes, _ := json.Marshal(response)

	log.Printf("Wrote Product: %s\n", product.ID)
	return shim.Success(bytes)
}

//getAllProducts retrieves all products on the ledger
func (s *SmartContract) getAllProducts(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	//Get user identity
	identity, err := common.GetInvokerIdentity(stub)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting invoker identity: %s\n", err.Error()))
	}

	if len(args) != 0 {
		return shim.Error("Incorrect number of arguments. Expecting 0")
	}

	// Get iterator for all entries
	iterator, err := stub.GetStateByRange("", "")
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting state iterator: %s", err))
	}
	defer iterator.Close()

	// Create array
	var buffer bytes.Buffer
	buffer.WriteString("[")
	for iterator.HasNext() {
		state, iterErr := iterator.Next()
		if iterErr != nil {
			return shim.Error(fmt.Sprintf("Error accessing state: %s", err))
		}

		// Don't return products issuer isn't a party to
		var product common.Product
		err = json.Unmarshal(state.Value, &product)
		if err != nil && err.Error() != "not a Product" {
			return shim.Error(err.Error())
		}
		if product.AccessibleBy(identity) {
			if buffer.Len() != 1 {
				buffer.WriteString(",")
			}
			buffer.WriteString(string(state.Value))
		}
	}
	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
}

//getSingleProducts retrieves all products on the ledger
func (s *SmartContract) getSingleProduct(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	//get user identity
	identity, err := common.GetInvokerIdentity(stub)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting invoker identity: %s\n", err.Error()))
	}

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	//get single state using id as key
	productAsBytes, err := stub.GetState(args[0])
	if err != nil {
		return shim.Error(err.Error())
	}
	// Return 404 if result's empty
	if len(productAsBytes) == 0 {
		return peer.Response{
			Status:  404,
			Message: fmt.Sprintf("Product %s Not Found", args[0]),
		}
	}

	//check to see if result is a product or not and unmarsal if so
	var product common.Product
	err = json.Unmarshal(productAsBytes, &product)
	if err != nil {
		return peer.Response{
			Status:  400,
			Message: fmt.Sprintf("Error: %s ", err),
		}
	}
	//check if user is allowed to see this product
	if !product.AccessibleBy(identity) {
		return peer.Response{
			Status:  404,
			Message: fmt.Sprintf("Product %s Not Found", args[0]),
		}
	}
	return shim.Success(productAsBytes)
}

//getContainerlessProducts retrieves all products on the ledger where containerID is empty
func (s *SmartContract) getContainerlessProducts(stub shim.ChaincodeStubInterface) peer.Response {
	//Get user identity
	identity, err := common.GetInvokerIdentity(stub)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting invoker identity: %s\n", err.Error()))
	}

	queryString := "{\"selector\":{\"docType\":\"product\",\"containerID\":\"\"}}"
	// Get iterator for all entries
	iterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting query iterator: %s", err.Error()))
	}
	defer iterator.Close()

	// Create array
	var buffer bytes.Buffer
	buffer.WriteString("[")
	for iterator.HasNext() {
		state, iterErr := iterator.Next()
		if iterErr != nil {
			return shim.Error(fmt.Sprintf("Error accessing state: %s", err))
		}

		// Don't return products issuer isn't a party to
		var product common.Product
		err = json.Unmarshal(state.Value, &product)
		if err != nil {
			log.Printf("Error unmarshalling product: %s", err)
			return shim.Error(fmt.Sprintf("Error unmarshalling product: %s", err))
		}
		log.Printf("%+v\n", product)
		log.Printf("%+v\n", identity.Cert.Subject.String())
		if product.AccessibleBy(identity) {
			if buffer.Len() != 1 {
				buffer.WriteString(",")
			}
			buffer.WriteString(string(state.Value))
		}
	}
	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
}

//updateCustodian claims current user as the custodian
func (s *SmartContract) updateProductCustodian(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	//get user identity
	identity, err := common.GetInvokerIdentity(stub)
	if err != nil {
		shim.Error(fmt.Sprintf("Error getting invoker identity: %s\n", err.Error()))
	}

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}
	trackingID := args[0]
	newLocation := args[1]
	newCustodian := identity.Cert.Subject.String()
	//get state by id as key
	existingsBytes, _ := stub.GetState(trackingID)

	// return 404 is not found
	if len(existingsBytes) == 0 {
		return peer.Response{
			Status:  404,
			Message: fmt.Sprintf("Item with trackingID %s not found", trackingID),
		}
	}

	//try to unmarshal as container
	var product common.Product
	err = json.Unmarshal(existingsBytes, &product)
	if err != nil {
		return shim.Error(err.Error())
	}
	//Ensure user is a participant
	if !(product.AccessibleBy(identity)) {
		return peer.Response{
			Status:  403,
			Message: "You are not authorized to perform this transaction, product not accesible by identity",
		}
	}
	//Ensure new custodian isnt the same as old one
	if newCustodian == product.Custodian {
		return peer.Response{
			Status:  403,
			Message: "You are already custodian",
		}
	}

	//make sure user cant claim a product separately from the container
	if product.ContainerID != "" {
		containerBytes, _ := stub.GetState(product.ContainerID)
		var container common.Container
		err = json.Unmarshal(containerBytes, &container)
		if err != nil {
			return shim.Error(err.Error())
		}
		if container.Custodian != newCustodian {
			return peer.Response{
				Status:  403,
				Message: "Product needs to be unpackaged before claiming a new owner",
			}
		}
	}

	//change custodian
	product.Custodian = newCustodian
	product.Location = newLocation
	product.Timestamp = int64(s.clock.Now().UTC().Unix())

	newBytes, _ := json.Marshal(product)

	if err := stub.PutState(trackingID, newBytes); err != nil {
		return shim.Error(err.Error())
	}

	log.Printf("Updated state: %s\n", trackingID)
	return shim.Success([]byte(trackingID))

}
