const Web3 = require('web3');
const fs = require('fs'); // Importing for writing a file
const contract = require('./compile'); //Importing the function to compile smart contract

const url = process.argv[2];  // url of RPC port of quorum node
const contractPath = process.argv[3]; // path to the contract directory
const contractEntryPoint = process.argv[4]; // Smart contract entrypoint eg Main.sol
const contractName = process.argv[5]; // Smart Contract Class Nameconst initArguments = process.env.INITARGUMENTS | " ";
const initArguments = process.env.INITARGUMENTS | " ";
const unlockPassPhrase = process.env.PASSPHRASE | " "; // Passphrase to unlock the account
const timeTillUnlocked = process.env.TIMETILLUNLOCKED | 600;
const numberOfIterations = parseInt(process.env.ITERATIONS) | 200; // Number of Iterations of execution of code for calculation of gas

const web3 = new Web3(new Web3.providers.HttpProvider(`${url}`)); // Creating a provider

var transactionHash = "";  // to store transaction hash to get the transaction recipt 

const deploy = async ()=>{

    const smartContract = await contract.GetByteCode(numberOfIterations,contractPath,contractEntryPoint,contractName); // Converting smart contract to byte code, optimizing the bytecode conversion for numer of Iterations
    const accounts = await web3.eth.getAccounts(); // Get the accounts created on the quorum node
    console.log("Trying to deploy contract using account: ", accounts[0])
    const bytecode = `0x${smartContract.bytecode}`; // adding 0x prefix to the bytecode
    const gasEstimate = parseInt(smartContract.gasEstimates.creation.executionCost*numberOfIterations)+parseInt(smartContract.gasEstimates.creation.codeDepositCost); // Gas Estimation
    const payload = initArguments !== " " || initArguments !== Number(0) ?{data: bytecode, arguments: initArguments} : {data: bytecode}; // If Initial Argumants are set in ENV variable

    //TODO account unlocking
    // web3.eth.personal.unlockAccount(accounts[0], unlockPassPhrase , parseInt(timeTillUnlocked)) 
    // .then(console.log('Account unlocked!'));
    let myContract = new web3.eth.Contract(smartContract.abi); // defigning the contract using interface
    let parameter = {
        //type: "quorum", // type of the network
        from: accounts[0], // Account used to deploy the smartContract
        gasPrice: 0, // price of a unit of gas in ether
        gas: gasEstimate // available gas unit to be spent
    }

    // use the privateFor if found in arguments
    if(process.argv[6] && process.argv[6] !== "0"){ // "0" is used for the automation purposes
        parameter["privateFor"] = process.argv[6].split(','); //splitting the string of the private keys by ',' to convert it in array.
    }
    DeployContract(payload, parameter, myContract); // run deploy Contract function
    PostDeployKeeping(smartContract.abi, smartContract.bytecode) // For writing the ABI and the smartContract bytecode in build 
}

const DeployContract = async (payload, parameter, myContract) =>{
    const contractDeployer = myContract.deploy(payload);
    try {
		const tx = await contractDeployer.send(parameter);
        let address = tx.options.address;
        console.log("contract is stored at the address:",address);
        console.log("contract Name: ", contractName);
	} catch (error) {
		console.error(error);
	}
}

const PostDeployKeeping = (abi, bytecode) =>{
    try {
        fs.writeFileSync("./build/abi.json", JSON.stringify(abi, null, '\t')) // writing the ABI file
      } catch (err) {
        console.error(err)
      }
      try {
        fs.writeFileSync("./build/General.bin", bytecode) // writing binary code to the file
      } catch (err) {
        console.error(err)
      }
}

deploy(); // calling the deploy() function
