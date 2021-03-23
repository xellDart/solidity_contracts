const provider = /*"https://ropsten.infura.io/v3/b2e24b5841304756bc426b764be4988e"; */ 'http://127.0.0.1:7545'; 

module.exports = {
    provider,
    blockchains: {
        eth: {
            explorer: 'http://api.etherscan.io/api',
            provider,
            network: 3,
            decimals: 18
        },
        usdc: {
            explorer: 'http://api.etherscan.io/api',
            provider,
            abi: 'usdc.json',
            network: 3,
            token: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
            decimals: 6
        },
    }
}
