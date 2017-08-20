'use strict';

const assertJump = require("./helpers/assertJump");
const timer = require("./helpers/timer");
var Token = artifacts.require("./DayTokenMock.sol");
var Crowdsale = artifacts.require("./helpers/AddressCappedCrowdsaleMock.sol");
var FinalizeAgent = artifacts.require("./BonusFinalizeAgent.sol");
var MultisigWallet = artifacts.require("./MultisigWallet.sol");
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
    var _initalBlockTimestamp = getUnixTimestamp('2017-10-7 09:00:00 GMT');
    var _mintingDec = 19;
    var _bounty = etherInWei(1);
    var _minBalanceToSell = 8888;
    var _dayInSecs = 84600;
    var _teamLockPeriodInSec = 15780000;
    //Multi Sig Wallet Parameters
    var _minRequired = 2;
    var _dayLimit = 2;
    var _listOfOwners = [accounts[1], accounts[2], accounts[3]];

    //AddressCappedCrowdsale Parameters
    var _now = web3.eth.getBlock(web3.eth.blockNumber).timestamp;
    var _countdownInSeconds = 100;


    var _startTime = _now + _countdownInSeconds;
    var _saleDurationInSeconds = 1000;
    var _endTime = _startTime + _saleDurationInSeconds;
    var _minimumFundingGoal = etherInWei(13);
    var _cap = etherInWei(35);
    var _preMinWei = etherInWei(1);
    var _preMaxWei = etherInWei(333);
    var _minWei = etherInWei(1);
    var _maxWei = etherInWei(333);
    var _maxPreAddresses = 3;
    var _maxIcoAddresses = 3;


    //BonusFinalizeAgent Parameters
    var _teamBonus = 5;
    var _teamAddresses = [accounts[4], accounts[5], accounts[6]];
    var _testAddressTokens = 88;
    var _testAddresses = [accounts[7], accounts[8], accounts[9]];
    var _totalBountyInDay = 8888;

    //Flat pricing Parameters
    var _oneTokenInWei = tokenPriceInWeiFromTokensPerEther(24);
    var _tokenDecimals = 8;

    var tokenInstance = null;
    var pricingInstance = null;
    var finalizeAgentInstance = null;
    var multisigWalletInstance = null;
    var crowdsaleInstance = null;
    var i;
    var id;
    beforeEach(async() => {
        tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply,
            _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower,
            _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell,
            _dayInSecs, _teamLockPeriodInSec, { from: accounts[0] });

        pricingInstance = await Pricing.new(_oneTokenInWei, { from: accounts[0] });

        multisigWalletInstance = await MultisigWallet.new(_listOfOwners, _minRequired);

        finalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, 
            multisigWalletInstance.address, _teamAddresses, _testAddresses, _testAddressTokens, 
            _teamBonus, _totalBountyInDay, { from: accounts[0] });

        crowdsaleInstance = await Crowdsale.new(tokenInstance.address, pricingInstance.address, 
            multisigWalletInstance.address, _startTime, _endTime, _minimumFundingGoal, _cap, _preMinWei, 
            _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses, { from: accounts[0] });

        await tokenInstance.addCrowdsaleAddress.call(crowdsaleInstance.address);
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
        var tokensPurchased = 100;
        var tokenPriceInWei = tokenPriceInWeiFromTokensPerEther(24);
        await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[1] });
        
        assert.equal(web3.toBigNumber(await tokenInstance.balanceOf(buyer)).toNumber(), tokenInSmallestUnit(tokensPurchased, _tokenDecimals), "Assert 1 Failed");
        assert.equal(web3.toBigNumber(await crowdsaleInstance.tokensSold.call()).toNumber(), tokenInSmallestUnit(tokensPurchased, _tokenDecimals), "Assert 2 Failed");
        assert.equal(web3.toBigNumber(await crowdsaleInstance.weiRaised.call()).toNumber(), tokensPurchased * tokenPriceInWei, "Assert 3 Failed");

    });
    it('Pre-allocate: Pre allocating the tokens to offline investor must fail if not within range', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        var buyer = accounts[3];
        var tokensPurchased = 20;
        var tokenPriceInWei = tokenPriceInWeiFromTokensPerEther(24);

        try {
            await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');

        buyer = accounts[5];
        tokensPurchased = 334 * 24;
await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });
        
        try {
            await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Pre-allocate: Should throw if maximum number of pre-ICO contributors is exceeded', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        var buyer = accounts[3];
        var tokensPurchased = 1000;
        var tokenPriceInWei = tokenPriceInWeiFromTokensPerEther(24);

        await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });

        buyer = accounts[5];
        tokensPurchased = 1000;

        await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });

        buyer = accounts[6];
        tokensPurchased = 1000;

        await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });

        buyer = accounts[7];
        tokensPurchased = 200;

        try {
            await crowdsaleInstance.preallocate(buyer, tokensPurchased, tokenPriceInWei, { from: accounts[0] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Update: Owner must be able to update pricing strategy', async function() {
        let oldPricingStrategy = await crowdsaleInstance.pricingStrategy.call();
        let newPricingInstance = await Pricing.new(_oneTokenInWei);
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
            let newPricingInstance = await Pricing.new(_oneTokenInWei);
            await crowdsaleInstance.setPricingStrategy(newPricingInstance.address, { from: accounts[2] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Update: Owner must be able to update FinalizeAgent', async function() {
        let oldFinalizeAgent = await crowdsaleInstance.finalizeAgent.call();
        let newFinalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, multisigWalletInstance.address, _teamAddresses, _testAddresses, _testAddressTokens, _teamBonus, _totalBountyInDay);
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
            let newFinalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, multisigWalletInstance.address, _teamAddresses, _testAddresses, _testAddressTokens, _teamBonus, _totalBountyInDay);
            await crowdsaleInstance.setFinalizeAgent(newFinalizeAgentInstance.address, { from: accounts[2] });
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
        assert.equal((await tokenInstance.balanceOf(accounts[3])).valueOf(), tokenInSmallestUnit(48, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buy({ from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal((await tokenInstance.balanceOf(accounts[5])).valueOf(), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));

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
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(48, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buyWithCustomerId(5, { from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));


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
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(48, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));

        await crowdsaleInstance.investWithCustomerId(accounts[5], 5, { from: accounts[5], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[5]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));

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
        assert.equal((await tokenInstance.balanceOf(accounts[2])).valueOf(), tokenInSmallestUnit(48, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('2', 'ether'));


        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('10', 'ether') });
        assert.equal((await tokenInstance.balanceOf(accounts[3])).valueOf(), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('12', 'ether'));



        await crowdsaleInstance.buy({ from: accounts[5], value: web3.toWei('3.14', 'ether') });
        assert.equal((await tokenInstance.balanceOf(accounts[5])).valueOf(), tokenInSmallestUnit(75.36, _tokenDecimals));
        assert.equal((web3.eth.getBalance(multisigWalletInstance.address)).valueOf(), web3.toWei('15.14', 'ether'));

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

        await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[1]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('10', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[2], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[2]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('20', 'ether'));

        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[3]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('30', 'ether'));

        try {
            await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('6', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');

    });


    it('Funding: It should throw if the same address tries to buy again', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('10', 'ether') });
        assert.equal(await tokenInstance.balanceOf(accounts[1]), tokenInSmallestUnit(240, _tokenDecimals));
        assert.equal(web3.eth.getBalance(multisigWalletInstance.address), web3.toWei('10', 'ether'));

        try {
            await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('5', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });


    it('Funding: Funding should be within range: Max and Min', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer(_countdownInSeconds);

        try {
            await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('0.2', 'ether') });
        } catch (error) {
            return assertJump(error);
        }

        try {
            await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('350', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Funding: Should throw if maximum number of ICO contributors is exceeded', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await crowdsaleInstance.buy({ from: accounts[1], value: web3.toWei('10', 'ether') });
        await crowdsaleInstance.buy({ from: accounts[2], value: web3.toWei('10', 'ether') });
        await crowdsaleInstance.buy({ from: accounts[3], value: web3.toWei('10', 'ether') });

        try {
            await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('10', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });
    it('Funding: Should throw if ICO period is over', async function() {
        await tokenInstance.setMintAgent(crowdsaleInstance.address, true);
        await tokenInstance.setMintAgent(finalizeAgentInstance.address, true);
        await tokenInstance.setReleaseAgent(finalizeAgentInstance.address);
        await tokenInstance.setTransferAgent(crowdsaleInstance.address, true);
        await crowdsaleInstance.setFinalizeAgent(finalizeAgentInstance.address);
        assert.equal(await crowdsaleInstance.isFinalizerSane(), true, "Finalizer not sane. Can't continue.");
        assert.equal(await crowdsaleInstance.isPricingSane(), true, "Pricing not sane. Can't continue.");

        await timer((_countdownInSeconds * 22));

        try {
            await crowdsaleInstance.buy({ from: accounts[4], value: web3.toWei('1', 'ether') });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });
});