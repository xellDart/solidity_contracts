const EthereumService = require('./wallets/eth.wallets');
const deployer = require('./compiler/deployer');
const compiler = require('./compiler/compiler');
const config = require('./config');
const Web3 = require('web3');

const eth = new EthereumService(config.blockchains.eth);
const web3 = new Web3(new Web3.providers.HttpProvider(config.provider));
const compile = compiler.contract.compile('EventDispersions');
console.log(compile);
deployer.deploy.providers(web3);

const sendETH = async (wallet, to, amount) => eth.sendETH(wallet, to, amount);
const fundContract = async (wallet, to, amount) => eth.fundContract(wallet, to, amount);
const getETH = async (wallet) => eth.getETH(wallet);
const createWallet = async () => {
    const privateKey = await eth.createWallet();
    return eth.generateAddress(privateKey);
};

// Wallet with 2 ethers
const wallet = {
    address: '0x4e6F0974fd000EDd77Fd0FaF392cAcd1574EFF40',
    private_key: '1e289addc09b56efdae0736974759e250de1b460bbf6d9de79f660ef9ef5cf2e'
};

function writeInContract(data, owner, contract) {
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, owner, contract._address).then(resolve).catch(reject);
    });
}

async function registerMember(member, percent, owner, contract) {
    let data = await contract.methods.registerMember(member.address, percent);
    return new Promise((resolve, reject) =>
        deployer.deploy.call(data, owner, contract._address).then(resolve).catch(reject)
    );
}

function signMember(member, contract) {
    let data = contract.methods.sign(member.address);
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(resolve).catch(reject);
    });
}

function refund(member, contract) {
    let data = contract.methods.refund();
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(resolve).catch(reject);
    });
}

function getInvestor(contract) {
    return contract.methods.getInvestor().call();
}

function executeEvent(owner, contract) {
    let data = contract.methods.executeEvent();
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, owner, contract._address).then(resolve).catch(reject);
    });
}

deployer.deploy.init(compile, wallet).then(async contract => {

    // create new members
    const user1 = await createWallet();
    const user2 = await createWallet();

    // Charge users with balance for sign contract
    await sendETH(wallet, user1.address, 0.01);
    await sendETH(wallet, user2.address, 0.01);

    const abi = compile.contracts['Trato.sol']['Trato'].abi;
    let trato = new web3.eth.Contract(abi, contract.contractAddress);

    // Send eth to contract
    fundContract(wallet, trato._address, 0.01).then(async _ => {
        // Get contract amount
        console.log(`Initial contract balance ${await getETH({ address: trato._address })}`);
        console.log('Investor: ', await getInvestor(trato));

        //console.log('REFUND');
        //await refund(wallet, trato);

        // Create event
        let event = trato.methods.createEvent(web3.utils.fromAscii("trato_demo"));
        writeInContract(event, wallet, trato).then(async _ => {
            await registerMember(user1, 50, wallet, trato);
            await registerMember(user2, 50, wallet, trato);
            await signMember(user1, trato);
            await signMember(user2, trato);
            await executeEvent(wallet, trato);

            console.log(`Final user 1 balance ${await getETH(user1)}`);
            console.log(`Final user 2 balance ${await getETH(user2)}`)

            console.log(`Final contract balance ${await getETH({ address: trato._address })}`);
        });
    }).catch(console.log);
}).catch(console.log);

