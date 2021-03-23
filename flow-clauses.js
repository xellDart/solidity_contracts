const EthereumService = require('./wallets/eth.wallets');
const deployer = require('./compiler/deployer');
const compiler = require('./compiler/compiler');
const config = require('./config');
const Web3 = require('web3');

const eth = new EthereumService(config.blockchains.eth);
const web3 = new Web3(new Web3.providers.HttpProvider(config.provider));
const compile = compiler.contract.compile('ClauseDispersions');
console.log(compile);
deployer.deploy.providers(web3);

const sendETH = async (wallet, to, amount) => {
    console.log(`Send ${amount} from ${wallet.address} to ${to}`)
    return eth.sendETH(wallet, to, amount);
}
const fundContract = async (wallet, to, amount) => eth.fundContract(wallet, to, amount);
const getETH = async (wallet) => eth.getETH(wallet);
const createWallet = async () => {
    const privateKey = await eth.createWallet();
    return eth.generateAddress(privateKey);
};

// Wallet with 2 ethers
const wallet = {
    address: '0x67A3ACEa9258eDE8974cbE7fAed8F369d3c4F020',
    private_key: '1e289addc09b56efdae0736974759e250de1b460bbf6d9de79f660ef9ef5cf2e'
};

function write(data, owner, contract) {
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, owner, contract._address).then(result => {
            resolve(result);
        }).catch(reject);
    });
}

function registerMember(member, percent, owner, contract) {
    console.log('Register: ', member.address)
    let data = contract.methods.registerMember(member.address, percent);
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, owner, contract._address).then(result => {
            resolve(result);
        }).catch(reject);
    });
}

function signMember(member, contract) {
    console.log('Sign: ', member.address)
    let data = contract.methods.sign(member.address);
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, member, contract._address).then(result => {
            resolve(result);
        }).catch(reject);
    });
}

function getMember(member, contract) {
    return contract.methods.getMember(member.address).call();
}

function executeEvent(owner, contract) {
    let data = contract.methods.executeEvent();
    return new Promise((resolve, reject) => {
        deployer.deploy.call(data, owner, contract._address).then(result => {
            resolve(result);
        }).catch(reject);
    });
}

(async () => {
    try {
        const contract = await deployer.deploy.init(compile, wallet);
        const abi = compile.contracts['Trato.sol']['Trato'].abi;
        const trato = new web3.eth.Contract(abi, contract.contractAddress);
        const { createClause, setClausePay, addCondition, setOnAll, executeCondition } = trato.methods;

        // // create new members
        // create new members
        const user1 = await createWallet();
        const user2 = await createWallet();

        // Charge users with balance for sign contract
        await sendETH(wallet, user1.address, 0.02);
        await sendETH(wallet, user2.address, 0.02);

        await registerMember(user1, 50, wallet, trato);
        await registerMember(user2, 50, wallet, trato);

        await fundContract(wallet, trato._address, 0.3)
        console.log('ContractBalance: ', await getETH({ address: trato._address }));

        console.log('Clauses-->')
        await write(createClause(web3.utils.fromAscii("type"), web3.utils.fromAscii("name"), true), wallet, trato)
        await write(setClausePay(0, web3.utils.toWei("0.1", "ether"), user1.address), wallet, trato)
        await write(addCondition(0, user2.address, web3.utils.fromAscii("uuidv4")), wallet, trato);

        //await write(createClause(web3.utils.fromAscii("type2"), web3.utils.fromAscii("name2"), true), wallet, trato)
        //await write(setClausePay(1, web3.utils.toWei("0.1", "ether"), user2.address), wallet, trato)
        //await write(addCondition(1, user1.address, web3.utils.fromAscii("uuidv4")), wallet, trato);


        // await write(setOnAll(true);, wallet, trato)
        console.log('<-- Clauses')

        await signMember(user1, trato);
        await signMember(user2, trato);

        await write(executeCondition(0, 0), wallet, trato)
        //await write(executeCondition(1, 0), wallet, trato)
        console.log('ContractBalance: ', await getETH({ address: trato._address }));
        console.log('User1 Balance: ', await getETH({ address: user1.address }));
        console.log('User2 Balance: ', await getETH({ address: user2.address }));

    } catch (err) {
        console.log(err);
    }

})()


// await sendETH({ address: '0x1C7c061fb359115371Ed36897aacD2bb443F3A97', private_key: '75a4cf012bf9d8611775c63dcd8c67149bd49856e92d1cb012f52f6857d6ff1a' }, wallet.address, 100)
