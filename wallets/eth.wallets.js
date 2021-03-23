const axios = require('axios');
const bip39 = require('bip39');
const eth_hd = require('eth-hd-wallet');
const Web3 = require('web3');

module.exports = class EthereumService {

    constructor(config) {
        this.explorer = config.explorer;
        this.precission = Number(`1e${config.decimals}`);
        this.web3 = new Web3(config.provider);
        this.network = config.network;
    }

    async createWallet() {
        const mnemonic = bip39.generateMnemonic();
        const wallet = eth_hd.EthHdWallet.fromMnemonic(mnemonic);
        return wallet._hdKey._hdkey.privateExtendedKey;
    }

    async generateAddress(privKey) {
        const wallet = new eth_hd.EthHdWallet(privKey);
        const [address] = wallet.generateAddresses(1);
        return {
            address,
            private_key: wallet.getPrivateKey(address).toString('hex')
        }
    }

    async getETH(wallet) {
        return (await this.web3.eth.getBalance(wallet.address)) / this.precission
    }

    async getUSDC(address) {
        return axios.get(`${this.explorer}?module=account&action=tokenbalance&contractaddress=${this.token}&address=${address.address}&tag=latest&apikey=EYJEJPR2Y1IKJTWWU4EIMC57IDEDTT21Q7`)
            .then(result => result.data)
            .then(data => data.result ? data.result / this.precission : 0);
    }

    async _sign(tx, privateKey) {
        const signPromise = this.web3.eth.accounts.signTransaction(tx, privateKey);
        return new Promise((resolve, reject) => {
            signPromise.then((signedTx) => {
                const sentTx = this.web3.eth.sendSignedTransaction(signedTx.rawTransaction);
                sentTx.on('receipt', hash => {
                    resolve(hash)
                });
                sentTx.on('error', error => reject(error))
            }).catch(reject);
        });
    }

    async _calculateGas(tx) {
        return await this.web3.eth.estimateGas(tx)
    }

    async sendUSDC(wallet, to, amount, gwei) {
        const gasPrice = gwei * 1e9;
        const nonce = await this.web3.eth.getTransactionCount(wallet.address, 'pending');

        let contractABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, `tokens/${this.abi}`), 'utf-8'));
        let contract = new this.web3.eth.Contract(contractABI, this.token, {
            from: wallet.address
        });

        let amountSent = this.web3.utils.toBN(amount * this.precission);
        let data = contract.methods.transfer(to, amountSent).encodeABI();

        const tx = {
            from: wallet.address,
            nonce: nonce,
            gasPrice: gasPrice,
            to: this.token,
            value: web3.utils.fromWei('0', 'ether'),
            data: data,
            chainId: this.network
        };

        tx.gasLimit = await this._calculateGas(tx);
        const fee = (tx.gasLimit * gasPrice) / 1e18;
        if (fee > await this.getETH(wallet)) throw new Error('Fee is bigger than balance');

        return {
            hash: await this.sign(tx, addresses[0].private_key),
            fee: this.gasLimit * gasPrice
        }

    }

    async fundContract(wallet, to, amount, gwei = 32) {
        const gasPrice = gwei * 1e9;

        const nonce = await this.web3.eth.getTransactionCount(wallet.address, 'pending');
        let amountSent = this.web3.utils.toBN(amount * this.precission);

        const tx = {
            to: to,
            nonce: nonce,
            value: amountSent,
            gasPrice: gasPrice,
            gasLimit: 90000,
            chainId: this.network
        }

        const fee = (tx.gasLimit * gasPrice) / 1e18;
        if (fee > amount) throw new Error('Fee is bigger than balance');
        tx.value = this.web3.utils.toBN(amount * this.precission);

        return {
            hash: await this._sign(tx, wallet.private_key),
            fee
        }
    }

    async sendETH(wallet, to, amount, gwei = 32) {
        const gasPrice = gwei * 1e9;

        const nonce = await this.web3.eth.getTransactionCount(wallet.address, 'pending');
        let amountSent = this.web3.utils.toBN(amount * this.precission);

        const tx = {
            to: to,
            nonce: nonce,
            value: amountSent,
            gasPrice: gasPrice,
            chainId: this.network
        }

        tx.gasLimit = await this._calculateGas(tx);

        const fee = (tx.gasLimit * gasPrice) / 1e18;
        if (fee > amount) throw new Error('Fee is bigger than balance');
        tx.value = this.web3.utils.toBN(amount * this.precission);

        return {
            hash: await this._sign(tx, wallet.private_key),
            fee
        }
    }
}
