var Token = artifacts.require("./DayToken.sol");



var debug = true;
var showABI = true;
var showURL = true;

module.exports = function(deployer, network, accounts) {
    /**
     * 
     * ===================================
     * Set your crowdsale parameters here
     * Parameters Section Begins
     * ===================================
     * 
     */

    /**
     * Token Parameters 
     * =====================================
     * Here you can chose your token name, symbol, initial supply & decimals etc.
     */

    var _tokenName = "Feed";
    var _tokenSymbol = "FEED";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = tokenInSmallestUnit(0, _tokenDecimals);
    var _tokenMintable = true;
    var _maxAddresses = 3;
    var _minMintingPower = 500000000000000000;
    var _maxMintingPower = 1000000000000000000;
    var _halvingCycle = 88;
    var _initalBlockTimestamp = 1499644800;
    var _mintingDec = 19;
    var _bounty = 100000000;
    /**
     * 
     * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     * Parameters Section Ends
     * ===================================
     * 
     */

    var tokenInstance;

    deployer.then(function() {
        return Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty);
    }).then(function(Instance) {
        tokenInstance = Instance;
        if (debug) console.log("CrowdsaleToken Parameters are:");
        if (debug) console.log(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty);
        if (debug) console.log("CrowdsaleToken address is: ", tokenInstance.address);
        if (showURL) console.log("Token URL is: " + getEtherScanUrl(network, tokenInstance.address, "token"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, tokenInstance.transactionHash, "tx"));
        if (showABI) console.log("CrowdsaleToken ABI is: ", JSON.stringify(tokenInstance.abi));
        if (debug) console.log("===============================================");
        if (debug) console.log("\n\n");
    });

    function getEtherScanUrl(network, data, type) {
        var etherscanUrl;
        if (network == "ropsten" || network == "kovan") {
            etherscanUrl = "https://" + network + ".etherscan.io";
        } else {
            etherscanUrl = "https://etherscan.io";
        }
        if (type == "tx") {
            etherscanUrl += "/tx";
        } else if (type == "token") {
            etherscanUrl += "/token";
        } else if (type == "address") {
            etherscanUrl += "/address";
        }
        etherscanUrl = etherscanUrl + "/" + data;
        return etherscanUrl;
    }

    function etherInWei(x) {
        return web3.toBigNumber(web3.toWei(x, 'ether')).toNumber();
    }


    function tokenPriceInWeiFromTokensPerEther(x) {
        if (x == 0) return 0;
        return Math.floor(web3.toWei(1, 'ether') / x);
    }

    function getUnixTimestamp(timestamp) {
        var startTimestamp = new Date(timestamp);
        return startTimestamp.getTime() / 1000;
    }


    function tokenInSmallestUnit(tokens, _tokenDecimals) {
        return tokens * Math.pow(10, _tokenDecimals);
    }
}