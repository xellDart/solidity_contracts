const fs = require('fs');
const solc = require('solc');
const path = require('path');

function withType(type) {
    const tratoPath = path.resolve(__dirname, 'contracts', `${type}.sol`);
    const source = fs.readFileSync(tratoPath, 'UTF-8');
    return source;
}

function matchImport(path) {
    if (path.startsWith('@openzeppelin'))
        return `node_modules/${path}`;
    return `contracts/${path}`;
}

function findImports(path) {
    return {
        'contents': fs.readFileSync(matchImport(path)).toString()
    }
}

const contract = {
    compile: (type) => {
        return JSON.parse(
            solc.compile(JSON.stringify({
                language: 'Solidity',
                sources: {
                    'Trato.sol': {
                        content: withType(type)
                    }
                },
                settings: {
                    outputSelection: {
                        '*': {
                            '*': ['*']
                        }
                    },
                    optimizer: {
                        "enabled": true,
                        "runs": 400,
                    }
                }
            }), { import: findImports })
        );
    }
}

module.exports = {
    contract
}