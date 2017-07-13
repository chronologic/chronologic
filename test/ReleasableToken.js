'use strict';

const assertJump = require('./helpers/assertJump');
var Token = artifacts.require("./helpers/ReleasableTokenMock.sol");
var ReleaseAgent = artifacts.require("./helpers/SimpleReleaseAgent.sol");


contract('ReleasableToken', function(accounts) {

    var _tokenName = "TOSHCOIN";
    var _tokenSymbol = "TCO";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = 100000000 * Math.pow(10, _tokenDecimals);
    var _tokenMintable = true;
    var decimals = _tokenDecimals;
    it('Creation: should return the correct totalSupply after construction', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let totalSupply = await instance.totalSupply();

        assert.equal(totalSupply, _tokenInitialSupply);
    });

    it('Creation: should return the correct balance of admin after construction', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let adminBalance = await instance.balanceOf.call(accounts[0]);

        assert.equal(adminBalance, _tokenInitialSupply);
    });

    it('Creation: sould return correct token meta information', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        let name = await instance.name.call();
        assert.strictEqual(name, _tokenName, "Name value is not as expected.");

        let decimal = await instance.decimals.call();
        assert.strictEqual(decimal.toNumber(), _tokenDecimals, "Decimals value is not as expected");

        let symbol = await instance.symbol.call();
        assert.strictEqual(symbol, _tokenSymbol, "Symbol value is not as expected");
    });

    it('Transfer: ether transfer to token address should fail.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        try {
            await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: web3.toWei("10", "Ether") });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Transfer: Tokens not released yet. Token transfer should fail.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        try {
            await instance.transfer(accounts[1], _tokenInitialSupply);
            let receiverBalance = await instance.balanceOf.call(accounts[1]);
            assert.strictEqual(receiverBalance, 0, "receiver balance should still be 0.");
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Transfer: Owner seting up himself as transfer agent. Should succeed.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        await instance.setTransferAgent(accounts[0], true);
        assert.ok('Did not succeed.');
    });

    it('Transfer: Owner is a transfer agent right now. Token transfer should succeed only if he is the sender.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        await instance.setTransferAgent(accounts[0], true);
        await instance.transfer(accounts[1], _tokenInitialSupply);

        let adminBalance = await instance.balanceOf(accounts[0]);
        assert.equal(adminBalance, 0, "Admin balance should have been 0.");

        let receiverBalance = await instance.balanceOf(accounts[1]);
        assert.equal(receiverBalance, _tokenInitialSupply, "receiver balance should have been " + _tokenInitialSupply + " Tokens.");
    });

    it('Transfer: Tokens not released yet for everyone. Token transfer by the receivers should fail.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        await instance.setTransferAgent(accounts[0], true);
        await instance.transfer(accounts[1], _tokenInitialSupply);
        try {
            await instance.transfer(accounts[2], _tokenInitialSupply, { from: accounts[1] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Transfer: Owner seting up release agent. Should succeed.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let releaseAgentInstance = await ReleaseAgent.new(instance.address, { from: accounts[0] });

        await instance.setReleaseAgent(releaseAgentInstance.address);
        assert.equal(releaseAgentInstance.address, await instance.releaseAgent.call(), "Release agent has not been set properly.");

    });

    it('Transfer: Release agent releasing the token. Should succeed.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let releaseAgentInstance = await ReleaseAgent.new(instance.address, { from: accounts[0] });

        await instance.setReleaseAgent(releaseAgentInstance.address);
        await releaseAgentInstance.release();
        assert.equal(true, await instance.released.call(), "Token could not be release successfully.");

    });

    it('Transfer: Open transfer by anyone post release should succeed.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let releaseAgentInstance = await ReleaseAgent.new(instance.address, { from: accounts[0] });

        await instance.setReleaseAgent(releaseAgentInstance.address);
        await releaseAgentInstance.release();
        await instance.transfer(accounts[1], _tokenInitialSupply);
        let adminBalance = await instance.balanceOf(accounts[0]);
        assert.equal(adminBalance, 0, "Admin balance should have been 0.");

        let receiverBalance = await instance.balanceOf(accounts[1]);
        assert.equal(receiverBalance, _tokenInitialSupply, "receiver balance should have been " + _tokenInitialSupply + " Tokens.");

        await instance.transfer(accounts[2], _tokenInitialSupply - 100000, { from: accounts[1] });
        let account1Balance = await instance.balanceOf(accounts[1]);
        assert.equal(account1Balance, 100000, "Account2 balance should have been 100000.");

        let account2Balance = await instance.balanceOf(accounts[2]);
        assert.equal(account2Balance, _tokenInitialSupply - 100000, "receiver balance should have been " + (_tokenInitialSupply - 100000) + " Tokens.");
    });

    it('Transfer: Setting up release agent post token release must fail.', async function() {
        let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let releaseAgentInstance = await ReleaseAgent.new(instance.address, { from: accounts[0] });

        await instance.setReleaseAgent(releaseAgentInstance.address);
        await releaseAgentInstance.release();

        try {
            await await instance.setReleaseAgent(releaseAgentInstance.address);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });


});