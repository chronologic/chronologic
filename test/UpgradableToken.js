'use strict';

const assertJump = require('./helpers/assertJump');
var Token = artifacts.require("./helpers/UpgradeableTokenMock.sol");
var newTokenContract = artifacts.require("../contracts/newToken.sol");

contract('UpgradeableToken', function(accounts) {


    var _tokenName = "TOSHCOIN";
    var _tokenSymbol = "TCO";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = 100000000 * Math.pow(10, _tokenDecimals);
    var _tokenMintable = true;
    var decimals = _tokenDecimals;
    var oldToken = null;
    var newToken = null;

    function tokenInSmallestUnit(tokens, _tokenDecimals) {
        return tokens * Math.pow(10, _tokenDecimals);
    }

    beforeEach(async() => {
        oldToken = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        newToken = await newTokenContract.new(oldToken.address);
    });

    it('Setup: Old token should be able to set new token as upgrade agent', async function() {
        await oldToken.setUpgradeAgent(newToken.address);
    });

    it('Setup: Owner should be the upgrade master', async function() {
        assert.equal(await oldToken.upgradeMaster(), accounts[0]);
    });

    it('Upgrade: upgrading in non-upgrading state should fail', async function() {
        try {
            await oldToken.upgrade(_tokenInitialSupply);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Upgrade: User must be able to upgrade properly via old token', async function() {
        await oldToken.setUpgradeAgent(newToken.address);
        assert.equal(await newToken.balanceOf(accounts[0]), 0);

        await oldToken.upgrade(_tokenInitialSupply - 1000);
        assert.equal(await newToken.balanceOf(accounts[0]), _tokenInitialSupply - 1000);
        assert.equal(await newToken.totalSupply.call(), _tokenInitialSupply - 1000);
        assert.equal(await oldToken.totalUpgraded.call(), _tokenInitialSupply - 1000);

        await oldToken.upgrade(1000);
        assert.equal(await newToken.balanceOf(accounts[0]), _tokenInitialSupply);
        assert.equal(await newToken.totalSupply.call(), _tokenInitialSupply);
        assert.equal(await oldToken.totalUpgraded.call(), _tokenInitialSupply);
    });

    it('Upgrade: upgrading 0 tokens should fail', async function() {
        await oldToken.setUpgradeAgent(newToken.address);
        try {
            await oldToken.upgrade(0);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');

    });


});