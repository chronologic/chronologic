var Token = artifacts.require("./DayToken.sol");
var MultiSigWallet = artifacts.require("./MultiSigWallet.sol");

var debug = true;
var showABI = false;
var showURL = false;

module.exports = function(deployer, network, accounts) {

    /**
     * 
     * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     * Parameters Section Starts
     * ===================================
     * 
     */

    /**
     * Token Parameters 
     * =====================================
     * Here you can chose your token name, symbol, initial supply & decimals etc.
     */

    var _tokenName = "Day";
    var _tokenSymbol = "DAY";
    var _tokenDecimals = 18;
    var _tokenInitialSupply = 0;
    var _tokenMintable = true;

    var _maxAddresses = 7;
    var _firstTeamContributorId = 4;
    var _totalTeamContributorIds = 2;
    var _totalPostIcoContributorIds = 2;

    var _minMintingPower = 500000000000000000;
    var _maxMintingPower = 1000000000000000000;
    var _halvingCycle = 88;

    var _DayInSecs = 84600;
    var _minBalanceToSell = 8888;
    var _teamLockPeriodInSec = 15780000;

    // /**
    //  * MultiSigWallet parameters
    //  * =====================================
    //  * Here you will set your MultiSigWallet parameters where you will be collecting the contributed ethers
    //  * here you have to mention the list of wallet owners (none of them must be 0)
    //  * and the minimum approvals required to approve the transactions.
    //  */
    var _minRequired = 2;

    var _listOfOwners;
    if (network == "testrpc") {
        _listOfOwners = [accounts[1], accounts[2], accounts[3]];
    } else if (network == "ropsten") {
        var aliceRopsten = "0x00568Fa85228C66111E3181085df48681273cD77";
        var bobRopsten = "0x00B600dE56F7570AEE3d57fe55E0462e51ca5280";
        var eveRopsten = "0x00F131eD217EC029732235A96EEEe044555CEd4d";
        _listOfOwners = [aliceRopsten, bobRopsten, eveRopsten];
    } else if (network == "mainnet") {
        // you have to manually specify this 
        // before you deploy this in mainnet
        // or else this deployment will fail
        var member1 = "0x00";
        var member2 = "0x00";
        var member3 = "0x00";
        _listOfOwners = [member1, member2, member3];
        if (member1 == "0x00" || member2 == "0x00" || member3 == "0x00") {
            throw new Error("MultiSigWallet members are not set properly. Please set them in migration/2_deploy_contracts.js.");
        }
    }

    /**
     * 
     * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     * Parameters Section Ends
     * ===================================
     * 
     */

    var tokenInstance;
    var multisigWalletInstance;

    deployer.then(function() {

        return Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, 
            _maxAddresses, _firstTeamContributorId, _totalTeamContributorIds, _totalPostIcoContributorIds, 
            _minMintingPower, _maxMintingPower, _halvingCycle, _minBalanceToSell, _DayInSecs, _teamLockPeriodInSec);

    }).then(function(Instance) {
        //console.log(Instance);
        tokenInstance = Instance;
        if (debug) console.log("DayToken Parameters are:");
        if (debug) console.log(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, 
            _maxAddresses, _firstTeamContributorId, _totalTeamContributorIds, _totalPostIcoContributorIds, 
            _minMintingPower, _maxMintingPower, _halvingCycle, _minBalanceToSell, _DayInSecs, _teamLockPeriodInSec);
        if (debug) console.log("DayToken address is: ", tokenInstance.address);
        if (showURL) console.log("Token URL is: " + getEtherScanUrl(network, tokenInstance.address, "token"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, tokenInstance.transactionHash, "tx"));
        if (showABI) console.log("DayToken ABI is: ", JSON.stringify(tokenInstance.abi));
        if (debug) console.log("===============================================");
        if (debug) console.log("\n\n");
        if (debug) console.log("*************  Deploying MultiSigWallet by Zeppelin  ************** \n");
        return MultiSigWallet.new(_listOfOwners, _minRequired);
    }).then(function(Instance) {
        multisigWalletInstance = Instance;
        if (debug) console.log("MultiSigWallet Parameters are:");
        if (debug) console.log(_listOfOwners, _minRequired);
        if (debug) console.log("MultiSigWallet address is: ", multisigWalletInstance.address);
        if (showURL) console.log("Wallet URL is: " + getEtherScanUrl(network, multisigWalletInstance.address, "address"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, multisigWalletInstance.transactionHash, "tx"));
        if (showABI) console.log("MultiSigWallet ABI is: ", JSON.stringify(multisigWalletInstance.abi));
        if (debug) console.log("\n\n");
        console.log("\n*************  Setting up Agents  ************** \n");
        return tokenInstance.setMintAgent(tokenInstance.address, true);
    }).then(function() {
        console.log("DayToken itself is set as Mint Agent. Moving ahead...");
        return tokenInstance.setReleaseAgent(tokenInstance.address);
    }).then(function() {
        console.log("DayToken itself is set as Release Agent. Moving ahead...");
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