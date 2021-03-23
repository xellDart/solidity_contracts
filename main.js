const EthereumService = require('./wallets/eth.wallets');
const config = require('./config');

const eth = new EthereumService(config.blockchains.eth);

const createWallet = async () => {
    const privateKey = await eth.createWallet();
    return eth.generateAddress(privateKey);
};

const getETH = async (wallet) => eth.getETH(wallet);

const sendETH = async (wallet, to, amount) => eth.sendETH(wallet, to, amount);

module.exports = {
    createWallet,
    getETH,
    sendETH,
};

const wallet = {
    address: '0xbad985d4a374ec471b26801b09d0788e39d3f6c5',
    private_key: '6d1d530bb5a7581d25bfe8d500d6a4993bcf5a2e20bf66b354cc1bcfb3290c66'
};

sendETH(wallet, '0xFE3B557E8Fb62b89F4916B721be55cEb828dBd73', 0.101).then(console.log).catch(console.log);