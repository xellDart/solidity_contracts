const api = require('./utils');

let tx;

function getContract(compile) {
    const bytecode = compile.contracts['Trato.sol']['Trato'].evm.bytecode.object;
    const abi = compile.contracts['Trato.sol']['Trato'].abi;
    return new web3.eth.Contract(abi).deploy({
        data: '0x' + bytecode,
        arguments: ['0x67A3ACEa9258eDE8974cbE7fAed8F369d3c4F020']
    });
}

function prepareDeploy(compile) {
    let deploy = getContract(compile);
    return {
        encoded: deploy.encodeABI(),
        contract: deploy
    }
}

function sign(tx, wallet) {
    const signPromise = web3.eth.accounts.signTransaction(tx, wallet.private_key);
    return new Promise((resolve, reject) => {
        signPromise.then((signedTx) => {
            const sentTx = web3.eth.sendSignedTransaction(signedTx.rawTransaction);
            sentTx.on('receipt', async receipt => {
                resolve(receipt);
            });
            sentTx.on('transactionHash', hash => {
                //console.log(hash)
            });
            sentTx.on('error', error => { })
        }).catch(reject);
    });
}

function getGas() {
    return new Promise(resolve => {
        api.utils.gas().then(response => response.data).then(data => resolve((data.fastest / 10) * 1e9))
    });
}

async function calculateGas(tx) {
    return await web3.eth.estimateGas(tx)
}

const deploy = {
    providers: provider => web3 = provider,
    call: async (contract, from, to) => {
        let nonce = await web3.eth.getTransactionCount(from.address, 'pending');
        let value = web3.utils.fromWei('0', 'ether');
        const gasPrice = await getGas();
        tx = {
            to,
            data: contract.encodeABI(),
            nonce,
            value,
            gasLimit: await contract.estimateGas({
                from: from.address, gasPrice, value,
            }),
            gasPrice
        };
        return await sign(tx, from)
    },
    init: async (compile, wallet) => {
        let nonce = await web3.eth.getTransactionCount(wallet.address, 'pending');
        let deploy = prepareDeploy(compile);
        const gasPrice = await getGas();
        tx = {
            from: wallet.address,
            gasPrice: gasPrice,
            nonce: nonce,
            value: web3.utils.fromWei('0', 'ether'),
            data: deploy.encoded
        };
        tx['gasLimit'] = await calculateGas(tx);
        return await sign(tx, wallet);
    }
}

module.exports = {
    deploy
}
