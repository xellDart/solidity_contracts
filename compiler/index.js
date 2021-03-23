const deployer = require('./deployer');
const compiler = require('./compiler');
const Web3 = require('web3');

const web3 = new Web3(new Web3.providers.HttpProvider('http://209.151.156.93:4545'));
const CONTRACTTYPE = 'ClauseDispersion';

// Wallet from deployer user
const WALLET = {
    address: '0xFE3B557E8Fb62b89F4916B721be55cEb828dBd73',
    privateKey: '8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'
};

let compile = compiler.contract.compile(CONTRACTTYPE);

async function getContractType(trato) {
    let type = await trato.methods.typeContract().call();
    console.log(web3.utils.toAscii(type));
}

async function createEvent(trato) {
    let data = trato.methods.addCondition(0, "0xFae5a415d3293c1A19068Bce92da97169eE5B642", web3.utils.fromAscii("uuidv4")).encodeABI();
    deployer.deploy.call(data, WALLET, trato._address).then(async result => {
        console.log(result);
    }).catch(console.log);
}

// Set WEB3 Provider
deployer.deploy.providers(web3);

deployer.deploy.init(compile, WALLET).then(contract => {
    const abi = compile.contracts['Trato.sol']['Trato'].abi;
    let trato = new web3.eth.Contract(abi, contract.contractAddress);
    // Sample call contract method
    //getContractType(trato);
    // Sample write on contract
    createEvent(trato);
}).catch(console.log);
