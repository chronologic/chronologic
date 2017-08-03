'use strict';

const assertJump = require('./helpers/assertJump');
var Token = artifacts.require("./helpers/DayToken.sol");
var bonusContract = artifacts.require("../contracts/BonusFinalizeAgent.sol");

function etherInWei(x) {
    return web3.toBigNumber(web3.toWei(x, 'ether')).toNumber();
}


function tokenPriceInWeiFromTokensPerEther(x) {
    if (x == 0) return 0;
    return Math.floor(web3.toWei(1, 'ether') / x);
}

function tokenInSmallestUnit(tokens, _tokenDecimals) {
    return tokens * Math.pow(10, _tokenDecimals);
}

function getUnixTimestamp(timestamp) {
    var startTimestamp = new Date(timestamp);
    return startTimestamp.getTime() / 1000;
}

contract('BonusFinalizeAgent', function(accounts) {
    var _teamBonus = 5;
    var _teamAddresses = [accounts[0], accounts[1], accounts[2]];
    var _testAddressTokens = 88;
    var _testAddresses = [accounts[3], accounts[4], accounts[6]];
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
    var _totalBountyInDay = 8888;
    var _minBalanceToSell = 8888;
    var DayToken = null;
    var bonusAgent = null;

    beforeEach(async() => {
        DayToken = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell, { from: accounts[0] });
        bonusAgent = await bonusContract.new(DayToken.address, accounts[5], _teamAddresses, _testAddresses, _testAddressTokens, _teamBonus, _totalBountyInDay);
    });

    it('Creation: BonusFinalizeAgent must be able to initialized properly.', async function() {
        assert.equal(await bonusAgent.token.call(), DayToken.address);
        assert.equal(await bonusAgent.crowdsale.call(), accounts[5]);
        assert.equal(await bonusAgent.teamAddresses.call(0), accounts[0]);
        assert.equal(await bonusAgent.teamAddresses.call(1), accounts[1]);
        assert.equal(await bonusAgent.teamAddresses.call(2), accounts[2]);
        assert.equal(await bonusAgent.testAddresses.call(0), accounts[3]);
        assert.equal(await bonusAgent.testAddresses.call(1), accounts[4]);
        assert.equal(await bonusAgent.testAddresses.call(2), accounts[6]);
        assert.equal(web3.toBigNumber(await bonusAgent.testAddressTokens.call()).toNumber(), _testAddressTokens);
        assert.equal(web3.toBigNumber(await bonusAgent.teamBonus.call()).toNumber(), _teamBonus);
    });

    it('Creation: Irregular initialization must fail.', async function() {
        try {
            bonusAgent2 = await bonusContract.new(DayToken.address, accounts[5], [200, 300, 200, 300], [accounts[0], accounts[1], accounts[2], accounts[3], accounts[4]]);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });


});