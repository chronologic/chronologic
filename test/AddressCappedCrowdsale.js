'use strict';

const assertJump = require('./helpers/assertJump');
const timer = require('./helpers/timer');
var Token = artifacts.require("./DayToken.sol");
var Crowdsale = artifacts.require("./AddressCappedCrowdsale.sol");
var FinalizeAgent = artifacts.require("./BonusFinalizeAgent.sol");
var MultisigWallet = artifacts.require('./MultisigWallet.sol');
var Pricing = artifacts.require("./FlatPricing.sol");


function etherInWei(x) {
    return web3.toBigNumber(web3.toWei(x, 'ether')).toNumber();
}


function tokenPriceInWeiFromTokensPerEther(x) {
    if (x == 0) return 0;
    return Math.floor(web3.toWei(1, 'ether') / x);
}

function tokenInSmallestUnit(tokens, _tokenDecimals) {
    return Math.floor(tokens * Math.pow(10, _tokenDecimals));
}

function getUnixTimestamp(timestamp) {
    var startTimestamp = new Date(timestamp);
    return Math.floor(startTimestamp.getTime() / 1000);
}

contract('AddressCappedCrowdsale: Success Scenario', function(accounts) {

    let shouldntFail = function(err) {
        assert.isFalse(!!err);
    };

    //Token Parameters
    var _tokenName = "Etheriya";
    var _tokenSymbol = "RIYA";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = 0;
    var _tokenMintable = true;
    var decimals = _tokenDecimals;
    var _maxAddresses = 3333;
    var _minMintingPower = 5000000000000000000;
    var _maxMintingPower = 10000000000000000000;
    var _halvingCycle = 88;
    var _initalBlockTimestamp = web3.eth.getBlock(web3.eth.blockNumber).timestamp;;
    var _mintingDec = 19;
    var _bounty = etherInWei(1);
    var _minBalanceToSell = 8888;

    //Multi Sig Wallet Parameters
    var _minRequired = 2;
    var _dayLimit = 2;
    var _listOfOwners = [accounts[1], accounts[2], accounts[3]];

    //AddressCappedCrowdsale Parameters
    var _now = web3.eth.getBlock(web3.eth.blockNumber).timestamp;
    var _countdownInSeconds = 100;


    // var _startTime = _now + _countdownInSeconds;
    // var _saleDurationInSeconds = 1000;
    // var _endTime = _startTime + _saleDurationInSeconds;
    // var _minimumFundingGoal = etherInWei(13);

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

    // var _cap = etherInWei(30);
    // var _preMinWei = etherInWei(33);
    // var _preMaxWei = etherInWei(333);
    // var _minWei = etherInWei(1);
    // var _maxWei = etherInWei(333);
    // var _maxPreAddresses = 33;
    // var _maxIcoAddresses = 3216;


    //BonusFinalizeAgent Parameters
    var _teamBonus = 5;
    var _teamAddresses = [accounts[0], accounts[1], accounts[2]];
    var _testAddressTokens = 88;
    var _testAddresses = [accounts[3], accounts[4], accounts[6]];

    //Flat pricing Parameters
    var _oneTokenInWei = tokenPriceInWeiFromTokensPerEther(24);
    //console.log(_oneTokenInWei);
    var _tokenDecimals = 8;

    var tokenInstance = null;
    var pricingInstance = null;
    var finalizeAgentInstance = null;
    var multisigWalletInstance = null;
    var crowdsaleInstance = null;

    beforeEach(async() => {
        tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell, { from: accounts[0] });
        pricingInstance = await Pricing.new(_oneTokenInWei, { from: accounts[0] });
        multisigWalletInstance = await MultisigWallet.new(_listOfOwners, _minRequired);
        finalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, multisigWalletInstance.address, _teamAddresses, _testAddresses, _testAddressTokens, _teamBonus);
        console.log("I AM HERR");
        crowdsaleInstance = await Crowdsale.new(tokenInstance.address, pricingInstance.address, multisigWalletInstance.address, _startTime, _endTime, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses);
    });

    it('Setup: Crowdsale address should be set as mint agent in Token properly', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        assert.equal(await tokenInstance.mintAgents.call(crowdsaleInstance.address), true);
    });

    it('Setup: BonusFinalizeAgent address should be set as mint agent in Token properly', async function() {
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        assert.equal(await tokenInstance.mintAgents.call(finalizeAgentInstance.address), true);
    });

    it('Setup: BonusFinalizeAgent address should be set as release agent in Token properly', async function() {
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        assert.equal(await tokenInstance.releaseAgent.call(), finalizeAgentInstance.address);
    });

    it('Setup: Crowdsale address should be set as transfer agent in Token properly', async function() {
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        assert.equal(await tokenInstance.transferAgents.call(crowdsaleInstance.address), true);
    });

    it('Setup: BonusFinalizeAgent address should be set as finalize agent in Crowdsale properly', async function() {
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.finalizeAgent.call(), finalizeAgentInstance.address);
    });

    it('Sanity Check: In crowdsale the finalizer should be sane', async function() {
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true);
    });

    it('Sanity Check: In crowdsale the pricing should be sane', async function() {
        assert.equal(await crowdsaleInstance.isPricingSane(), true);
    });

    it('Contribution: Contribution should fail if the crowdsale is not open yet.', async function() {
        try {
            await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('2', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Contribution: Contribution to direct address should fail.', async function() {
        try {
            web3.eth.sendTransaction({ from: web3.eth.coinbase, to: crowdsaleInstance.address, value: web3.toWei('20', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Finalize: Finalize in prefunding state should fail.', async function() {
        try {
            await crowdsaleInstance.finalize();
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Finalize: Finalize by any non-owner in prefunding state should fail.', async function() {
        try {
            await crowdsaleInstance.finalize({ from: accounts[3] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Pre-allocate: Calling pre allocate by non-owner should fail.', async function() {
        try {
            await crowdsaleInstance.preallocate(accounts[3], tokenInSmallestUnit(50000, _tokenDecimals), tokenPriceInWeiFromTokensPerEther(2000));
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Pre-allocate: Pre allocating the tokens to offline investor must succeed', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");


        var buyer = accounts[3];
        var tokensPurchased = 50000;
        var tokenPriceInWei = tokenPriceInWeiFromTokensPerEther(2000);

        await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });
        assert.equal(web3.toBigNumber(await tokenInstance.balanceOf(buyer)).toNumber(), tokenInSmallestUnit(tokensPurchased, _tokenDecimals), "Assert 1 Failed");
        assert.equal(web3.toBigNumber(await crowdsaleInstance.tokensSold.call()).toNumber(), tokenInSmallestUnit(tokensPurchased, _tokenDecimals), "Assert 2 Failed");
        assert.equal(web3.toBigNumber(await crowdsaleInstance.weiRaised.call()).toNumber(), tokensPurchased * tokenPriceInWei, "Assert 3 Failed");
    });

    it('Update: Owner must be able to update pricing strategy', async function() {
        let oldPricingStrategy = await crowdsaleInstance.pricingStrategy.call();
        let newPricingInstance = await Pricing.new(_tranches);
        await crowdsaleInstance.setPricingStrategy(newPricingInstance.address);
        let newPricingStrategy = await crowdsaleInstance.pricingStrategy.call();
        assert.equal(newPricingStrategy, newPricingInstance.address);
    });

    it('Update: Setting up a insane pricing staretgy must fail', async function() {
        try {
            await crowdsaleInstance.setPricingStrategy(accounts[6]);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Update: Non-owner should not be able to set pricing strategy', async function() {
        try {
            let newPricingInstance = await Pricing.new(_tranches);
            await crowdsaleInstance.setPricingStrategy(newPricingInstance.address, { from: accounts[2] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Update: Owner must be able to update FinalizeAgent', async function() {
        let oldFinalizeAgent = await crowdsaleInstance.finalizeAgent.call();
        let newFinalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, crowdsaleInstance.address, _teamBonusPoints, _teamAddresses);
        await crowdsaleInstance.setFinalizeAgent(newFinalizeAgentInstance.address);
        let newFinalizeAgent = await crowdsaleInstance.finalizeAgent.call();
        assert.equal(newFinalizeAgent, newFinalizeAgentInstance.address);
    });

    it('Update: Setting up a non-sane finalize agent must fail', async function() {
        try {
            await crowdsaleInstance.setFinalizeAgent(accounts[6]);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Update: Non-owner should not be able to set finalize agent', async function() {
        try {
            let newFinalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, crowdsaleInstance.address, _teamBonusPoints, _teamAddresses);
            await crowdsaleInstance.setFinalizeAgent(newFinalizeAgentInstance.address, { from: accounts[2] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Whitelist: Owner must be able to update early participants whitelist', async function() {
        await crowdsaleInstance.setEarlyParicipantWhitelist(accounts[4], true);
        assert.equal(await crowdsaleInstance.earlyParticipantWhitelist.call(accounts[4]), true);
    });

    it('Whitelist: Non-owner should not be able to set finalize agent', async function() {
        try {
            await crowdsaleInstance.setEarlyParicipantWhitelist.call(accounts[4], true, { from: accounts[2] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Whitelist: Only whitelisted address should be able to contribute even before the funding start.', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");
        try {
            await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('2', 'ether') });
        } catch (error) {
            return assertJump(error);
        }

        await crowdsaleInstance.setEarlyParicipantWhitelist.call(accounts[3], true);
        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('2', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(3000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));
        try {
            await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('2', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });


    it('Funding: Open contribution using buy must succeed', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('2', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(3000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buy({ from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(15000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('0.001', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[4]), Math.floor(tokenInSmallestUnit(1.1, _tokenDecimals)));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12.001', 'ether'));
    });

    it('Funding: Open contribution using buyWithCustomerId must succeed', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.buyWithCustomerId(3, { from: accounts[3], value: web3.toWei('2', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(3000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buyWithCustomerId(5, { from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(15000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));

        await crowdsaleInstance.buyWithCustomerId(4, { from: accounts[4], value: web3.toWei('0.001', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[4]), Math.floor(tokenInSmallestUnit(1.1, _tokenDecimals)));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12.001', 'ether'));
    });

    it('Funding: Open contribution using investWithCustomerId must succeed', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.investWithCustomerId(accounts[3], 3, { from: accounts[3], value: web3.toWei('2', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(3000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));

        await crowdsaleInstance.investWithCustomerId(accounts[5], 5, { from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(15000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));
        await crowdsaleInstance.investWithCustomerId(accounts[4], 4, { from: accounts[4], value: web3.toWei('0.001', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[4]), Math.floor(tokenInSmallestUnit(1.1, _tokenDecimals)));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12.001', 'ether'));
    });

    it('Funding: Minimum funding target must be hit', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.buy({ from: accounts[2], value: web3.toWei('2', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[2]), tokenInSmallestUnit(3000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(15000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('0.001', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[4]), tokenInSmallestUnit(1.1, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12.001', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[5], value: web3.toWei('3.14', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(3454, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('15.141', 'ether'));

        assert.equal(await crowdsaleInstance.isMinimumGoalReached(), true);

    });

    it('Funding: Maximum funding target must be hit', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('8', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[1]), tokenInSmallestUnit(12000, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('8', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[2], value: web3.toWei('8', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[2]), tokenInSmallestUnit(10400, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('16', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('8', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(8400, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('24', 'ether'));

        // let weiRaised = await crowdsaleInstance.weiRaised.call();
        // let weiCap = await crowdsaleInstance.weiCap.call();
        // console.log("weiRaised is: " + weiRaised);
        // console.log("weiCap is: " + weiCap);
        //assert.equal(await crowdsaleInstance.isCrowdsaleFull(), true);

        try {
            await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('8', 'ether') });
        } catch (error) {
            return assertJump(error);
        }


    });



});