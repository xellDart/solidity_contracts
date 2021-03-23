const EthereumService = require('./wallets/eth.wallets');
const deployer = require('./compiler/deployer');
const compiler = require('./compiler/compiler');
const config = require('./config');
const BigNumber = require('bignumber.js');
const Web3 = require('web3');

const eth = new EthereumService(config.blockchains.eth);
const web3 = new Web3(new Web3.providers.HttpProvider(config.provider));
const compile = compiler.contract.compile('TimeDispersions');
console.log(compile);
deployer.deploy.providers(web3);

Number.prototype.round = function(places) {
    return +(Math.round(this + "e+" + places)  + "e-" + places);
  }

const sendETH = async (wallet, to, amount) => eth.sendETH(wallet, to, amount);
const fundContract = async (wallet, to, amount) => eth.fundContract(wallet, to, amount);
const getETH = async (wallet) => eth.getETH(wallet);
const createWallet = async () => {
    const privateKey = await eth.createWallet();
    return eth.generateAddress(privateKey);
};


function getInvestor(contract) {
    return contract.methods.getInvestor().call();
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

function setEnd(quantity, unit, member, contract) {
    let data = contract.methods.setEnd(quantity, web3.utils.fromAscii(unit));
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(resolve).catch(reject);
    });
}

function setLapseds(laps, every, unit, member, contract) {
    let data = contract.methods.setLapseds(laps, every, web3.utils.fromAscii(unit));
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(resolve).catch(reject);
    });
}

function pay(member, contract) {
    let data = contract.methods.dispersions();
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(resolve).catch(reject);
    });
}


// Wallet with 2 ethers
const wallet = {
    address: '0x6B69f8252f13b88754e3355363F1F3A8687CA894',
    private_key: '955941d352157e3a32227d231b6b808f93d4b1cefc7f87a6cdb40be6f9651715'
};

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
    fundContract(wallet, trato._address, 1).then(async _ => {
        // Get contract amount
        console.log(`Initial contract balance ${await getETH({ address: trato._address })}`);
        console.log('Investor: ', await getInvestor(trato));

        await setEnd(2, "month", wallet, trato);
        let times = new Array(4).fill( (100 / 4).toFixed(2) * 1e2);

        await setLapseds(times, 15, "day", wallet, trato);

        console.log(trato._address);

        await registerMember(user1, 50, wallet, trato);
        await registerMember(user2, 50, wallet, trato);
        await signMember(user1, trato);
        await signMember(user2, trato);

        console.log('Start: ', await trato.methods.getStart().call());
        console.log('End: ', await trato.methods.getEnd().call());
        console.log('Next payment: ', await trato.methods.getNextPayment().call());

        console.log(`Initial user 1 balance ${await getETH(user1)}`);
        console.log(`Initial user 2 balance ${await getETH(user2)}`);


        console.log('Pay 1');
        await pay(wallet, trato);
        console.log('Next payment: ', await trato.methods.getNextPayment().call());
        console.log(`User 1 balance ${await getETH(user1)}`);
        console.log(`User 2 balance ${await getETH(user2)}`);
        
        console.log('Pay 2');
        await pay(wallet, trato);
        console.log('Next payment: ', await trato.methods.getNextPayment().call());
        console.log(`User 1 balance ${await getETH(user1)}`);
        console.log(`User 2 balance ${await getETH(user2)}`);
        // Break by Stages.FINISH
        console.log('Pay 3');
        await pay(wallet, trato);
        console.log('Next payment: ', await trato.methods.getNextPayment().call());
        console.log(`User 1 balance ${await getETH(user1)}`);
        console.log(`User 2 balance ${await getETH(user2)}`);
        
        console.log('Pay 4');
        await pay(wallet, trato);
        console.log('Next payment: ', await trato.methods.getNextPayment().call());
        console.log(`User 1 balance ${await getETH(user1)}`);
        console.log(`User 2 balance ${await getETH(user2)}`);

        console.log(`Final contract balance ${await getETH({ address: trato._address })}`);
    }).catch(console.log);

}).catch(console.log);

