var Token = artifacts.require("./DayToken.sol");
var PricingStartegy = artifacts.require("./FlatPricing.sol");
//ar MultisigWallet = artifacts.require("./MultisigWalletConsenSys.sol");
var MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
var Crowdsale = artifacts.require("./AddressCappedCrowdsale.sol");
var FinalizeAgent = artifacts.require("./BonusFinalizeAgent.sol");

// GAS: 9,761,324


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

    var _tokenName = "Day";
    var _tokenSymbol = "DAY";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = tokenInSmallestUnit(0, _tokenDecimals);
    var _tokenMintable = true;
    var _maxAddresses = 7;
    var _minMintingPower = 500000000000000000;
    var _maxMintingPower = 1000000000000000000;
    var _halvingCycle = 88;
    var _initalBlockTimestamp = getUnixTimestamp('2017-08-7 09:00:00 GMT');
    var _mintingDec = 19;
    var _bounty = 100000000;

    var _minBalanceToSell = 8888;


    /**
     * Crowdsale parameters
     * =====================================
     * Here you will set your MultiSigWallet parameters where you will be collecting the contributed ethers
     * here you have to mention the list of wallet owners (none of them must be 0)
     * and the minimum approvals required to approve the transactions.
     */
    var _startTime = getUnixTimestamp('2017-07-23 09:00:00 GMT');
    var _endTime = getUnixTimestamp('2017-08-7 09:00:00 GMT');
    var _minimumFundingGoal = etherInWei(1500);
    var _cap = etherInWei(38383);
    var _preMinWei = etherInWei(33);
    var _preMaxWei = etherInWei(333);
    var _minWei = etherInWei(1);
    var _maxWei = etherInWei(333);
    var _maxPreAddresses = 33;
    var _maxIcoAddresses = 3216;


    /**
     * Flat Pricing Parameters
     * ====================================
     * Here you have to specify the rate, No. of day tokens per ether.
     */
    var _oneTokenInWei = 41666666666666666;

    /**
     * Bonus Agent parameters
     * =====================================
     * Here you will set your BonusFinalizeAgent parameters.
     */
    // set BonusFinalizeAgent parameters
    // 2% to each member. 
    // Number of entries count must match with the count of _teamAddresses members
    //var _testAddressTokens;
    var _testAddressTokens = 88;
    var _teamBonus = 5;
    // list of team mebers address respective to the above percentage.
    // alternatively you can just get all the bonus in one account & then distribute 
    // using some MultiSigWallet manually
    var _teamAddresses;
    if (network == "testrpc") {
        //_testAddressTokens = [5, 5, 5, 5, 5, 5, 5];
        _teamAddresses = [
            "0x22283B7315dd4B1741676e092279fc4F46ecC003",
            "0xf1BdA8f06191bC29F46d0ee3CBF68555A478a217",
            "0x15bac2c73532663058D3E82e9B1f8C7873Fef9e7",
            "0x3312F915B20527214A5Fc097d4E6b0E7F41CC192",
            "0x5F459fB028f7598cdaeB19461FcED31020e6534E",
            "0x72Bbe344986351A0C4E899D655E81DE8f64E9794",
            "0x6c750dA8df323D53eed6812a7AFB834B0752e94c"
        ];
    } else if (network == "ropsten") {
        // _testAddressTokens = [5, 5, 5];
        var aliceRopsten = "0x00568Fa85228C66111E3181085df48681273cD77";
        var bobRopsten = "0x00B600dE56F7570AEE3d57fe55E0462e51ca5280";
        var eveRopsten = "0x00F131eD217EC029732235A96EEEe044555CEd4d";
        _teamAddresses = [aliceRopsten, bobRopsten, eveRopsten];

    } else if (network == "mainnet") {
        // you have to manually specify this 
        // before you deploy this in mainnet
        // or else this deployment will fail
        // _testAddressTokens = [150, 150, 150];
        var member1 = 0x00;
        var member2 = 0x00;
        var member3 = 0x00;
        _teamAddresses = [member1, member2, member3];
        if (member1 == "0x00" || member2 == "0x00" || member3 == "0x00") {
            throw new Error("Team members addresses are not set properly. Please set them in migration/2_deploy_contracts.js.");
        }
    }
    var _testAddresses;
    if (network == "testrpc") {
        _testAddresses = [
            "0x22283B7315dd4B1741676e092279fc4F46ecC003",
            "0xf1BdA8f06191bC29F46d0ee3CBF68555A478a217",
            "0x15bac2c73532663058D3E82e9B1f8C7873Fef9e7",
        ];
    } else if (network == "ropsten") {
        var aliceRopsten = "0x00568Fa85228C66111E3181085df48681273cD77";
        var bobRopsten = "0x00B600dE56F7570AEE3d57fe55E0462e51ca5280";
        var eveRopsten = "0x00F131eD217EC029732235A96EEEe044555CEd4d";
        _testAddresses = [aliceRopsten, bobRopsten, eveRopsten];

    } else if (network == "mainnet") {
        // you have to manually specify this 
        // before you deploy this in mainnet
        var test1 = 0x00;
        var test2 = 0x00;
        var test3 = 0x00;
        _testAddresses = [test1, test2, test3];
        if (test1 == "0x00" || test2 == "0x00" || test3 == "0x00") {
            throw new Error("Team members addresses are not set properly. Please set them in migration/2_deploy_contracts.js.");
        }
    }

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
    var pricingInstance;
    var finalizeAgentInstance;
    var crowdsaleInstance;
    var multisigWalletInstance;

    deployer.then(function() {
        return Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell);
    }).then(function(Instance) {
        //console.log(Instance);
        tokenInstance = Instance;
        if (debug) console.log("DayToken Parameters are:");
        if (debug) console.log(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell);
        if (debug) console.log("DayToken address is: ", tokenInstance.address);
        if (showURL) console.log("Token URL is: " + getEtherScanUrl(network, tokenInstance.address, "token"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, tokenInstance.transactionHash, "tx"));
        if (showABI) console.log("DayToken ABI is: ", JSON.stringify(tokenInstance.abi));
        if (debug) console.log("===============================================");
        if (debug) console.log("\n\n");
        if (debug) console.log("*************  Deploying FlatPricing  ************** \n");
        return PricingStartegy.new(_oneTokenInWei);
    }).then(function(Instance) {
        pricingInstance = Instance;
        if (debug) console.log("FlatPricing Parameters are:");
        if (debug) console.log(_oneTokenInWei);
        if (debug) console.log("FlatPricing address is: ", pricingInstance.address);
        if (showURL) console.log("Pricing URL is: " + getEtherScanUrl(network, pricingInstance.address, "address"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, pricingInstance.transactionHash, "tx"));
        if (showABI) console.log("FlatPricing ABI is: ", JSON.stringify(pricingInstance.abi));
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
        if (debug) console.log("*************  Deploying AddressCappedCrowdsale  ************** \n");
        return Crowdsale.new(tokenInstance.address, pricingInstance.address, multisigWalletInstance.address, _startTime, _endTime, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses);
    }).then(function(Instance) {
        crowdsaleInstance = Instance;
        if (debug) console.log("AddressCappedCrowdsale Parameters are:");
        if (debug) console.log(tokenInstance.address, pricingInstance.address, multisigWalletInstance.address, _startTime, _endTime, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses);
        if (debug) console.log("AddressCappedCrowdsale address is: ", crowdsaleInstance.address);
        if (showURL) console.log("Crowdsale URL is: " + getEtherScanUrl(network, crowdsaleInstance.address, "address"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, crowdsaleInstance.transactionHash, "tx"));
        if (showABI) console.log("AddressCappedCrowdsale ABI is: ", JSON.stringify(crowdsaleInstance.abi));
        if (debug) console.log("===============================================");
        if (debug) console.log("\n\n");
        if (debug) console.log("*************  Deploying BonusFinalizeAgent  ************** \n");
        return FinalizeAgent.new(tokenInstance.address, crowdsaleInstance.address, _testAddresses, _teamAddresses, _testAddressTokens, _teamBonus);
    }).then(function(Instance) {
        finalizeAgentInstance = Instance;
        if (debug) console.log("BonusFinalizeAgent Parameters are:");
        if (debug) console.log(tokenInstance.address, crowdsaleInstance.address, _testAddresses, _teamAddresses, _testAddressTokens, _teamBonus);
        if (debug) console.log("BonusFinalizeAgent address is: ", finalizeAgentInstance.address);
        if (showURL) console.log("FinalizeAgent URL is: " + getEtherScanUrl(network, finalizeAgentInstance.address, "address"));
        if (showURL) console.log("Transaction URL is: " + getEtherScanUrl(network, finalizeAgentInstance.transactionHash, "tx"));
        if (showABI) console.log("BonusFinalizeAgent ABI is: ", JSON.stringify(finalizeAgentInstance.abi));
        if (debug) console.log("===============================================");
        if (debug) console.log("\n\n");
        console.log("\n*************  Setting up Agents  ************** \n");
        return tokenInstance.setMintAgent(crowdsaleInstance.address, true);
    }).then(function() {
        console.log("AddressCappedCrowdsale is set as Mint Agent in DayToken. Moving ahead...");
        return tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
    }).then(function() {
        console.log("BonusFinalizeAgent is set as Mint Agent in DayToken. Moving ahead...");
        return tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
    }).then(function() {
        console.log("BonusFinalizeAgent is set as Release Agent in DayToken. Moving ahead...");

        return tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
    }).then(function() {
        console.log("AddressCappedCrowdsale is set as Transfer Agent in DayToken. Moving ahead...");

        return crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
    }).then(function() {
        console.log("BonusFinalizeAgent is set as Finalize Agent in AddressCappedCrowdsale. Moving ahead...");

        return crowdsaleInstance.isFinalizerSane();
    }).then(function(status) {
        if (status == true) {
            console.log("Success: Finalizer is sane in Crowdsale application. All looks good. Moving ahead...");
        } else {
            console.log("Failure: Finalizer is NOT sane in Crowdsale application. Something is bad. Moving ahead though. Please check it manually...");
        }
        return crowdsaleInstance.isPricingSane();
    }).then(function(status) {
        if (status == true) {
            console.log("Success: Pricing is sane in Crowdsale application. All looks good. Moving ahead...");
        } else {
            console.log("Failure: Pricing is NOT sane in Crowdsale application. Something is bad. Moving ahead though. Please check it manually...");
        }
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