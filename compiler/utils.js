const axios = require('axios');

const utils = {
    gas: _ => axios.get('https://ethgasstation.info/api/ethgasAPI.json')
};

module.exports = {
    utils
}
