Account seed for testing

Flow Compile execution

```js
// Create web3 instance
const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'));
// Set type of contract to build and deploy
const CONTRACTTYPE = 'EventDispersion';
// Set wallet from deployer user
const WALLET = {
    address: '0x79C31614fCEc150Ca11e78C42bffa7c801D09a36',
    privateKey: 'd29bc4a5cf57c2539dd32f99d537b83444ecf8c231a9a364cdb3e9ab29e1c293'
};
// Compile contract
let compile = compiler.contract.compile(CONTRACTTYPE);
// Set WEB3 Provider to deployer instance
deployer.deploy.providers(web3);
// Deploy contract [compiled contract, wallet from deployer]
// @param contract contains contract address from network
deployer.deploy.init(compile, WALLET).then(contract => {
   // Get contract abi to create instance from network
    const abi = compile.contracts['Trato.sol']['Trato'].abi;
    // Init instance form deployed contract
    let trato = new web3.eth.Contract(abi, contract.contractAddress);
}).catch(console.log);
```

Interaction with contract
```js
// Create web3 instance
const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'));
// Set type of contract to interact
const CONTRACTTYPE = 'EventDispersion';
// Set wallet from deployer user
const WALLET = {
    address: '0x79C31614fCEc150Ca11e78C42bffa7c801D09a36',
    privateKey: 'd29bc4a5cf57c2539dd32f99d537b83444ecf8c231a9a364cdb3e9ab29e1c293'
};
// Compile contract
let compile = compiler.contract.compile(CONTRACTTYPE);
// Set WEB3 Provider to deployer instance
deployer.deploy.providers(web3);
const abi = compile.contracts['Trato.sol']['Trato'].abi;
// Init instance form deployed contract
let trato = new web3.eth.Contract(abi, contract.contractAddress);
// Get contract type sample
let type = await trato.methods.typeContract().call();
console.log(web3.utils.toAscii(type));

// create event with description = event_description
let data = trato.methods.createEvent(web3.utils.fromAscii("event_description")).encodeABI();
// Write on contact [0x... -> Address from contract]
deployer.deploy.call(data, WALLET, '0x......').then(async _ => {
   // Get text from provius operation
   let event = await trato.methods.getEvent().call();
        console.log(web3.utils.toAscii(event));
   }).catch(console.log);
```

Key: tr4t02020

```js
{
   "version":3,
   "id":"99ba46f4-7a31-40d0-ba4f-73c721fd4145",
   "address":"2903371e6067fdf4597005dae08993c8d7d30a70",
   "crypto":{
      "ciphertext":"7c2288152635838473c8f03fe3d58ade769f8c4c683b28b3f29d54a14749c315",
      "cipherparams":{
         "iv":"7d5864db0ef22b8757459be019920892"
      },
      "cipher":"aes-128-ctr",
      "kdf":"scrypt",
      "kdfparams":{
         "dklen":32,
         "salt":"b5fe5ff069ace04033ba08e657aa15d08fa89a2e1109917cba97113bb0d450ee",
         "n":131072,
         "r":8,
         "p":1
      },
      "mac":"634eec16eaa6478b2510cdfac8927d70c993f29a1c687323c738ed18d85413d1"
   }
}
```

Etherscan
https://ropsten.etherscan.io/address/0x2903371e6067FdF4597005daE08993C8d7D30a70