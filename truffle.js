require('babel-register');
require('babel-polyfill');


module.exports = {
    networks: {
        testrpc: {
            host: "localhost",
            port: 8545,
            network_id: "*"
        },
        kovan: {
            host: "localhost",
            port: 8545,
            network_id: "3",
            from: "0x00FcEf22b8e9c3741B0082a8E16DD92c2FE63A32",
            gas: 1512388
        },
        ropsten: {
            host: "localhost",
            port: 8545,
            network_id: "2",
            from: "0x00CFFD2cE294B153B2a597D9863102617adb94ED"
        },
        mainnet: {
            host: "localhost",
            port: 8545,
            network_id: "1"
        }
    }
};