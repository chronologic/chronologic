'use strict';

const assertJump = require('./helpers/assertJump');
var Token = artifacts.require("./helpers/MintableTokenMock.sol");
var ReleaseAgent = artifacts.require("./helpers/SimpleReleaseAgent.sol");


contract('MintableToken', function(accounts) {


    var _tokenName = "TOSHCOIN";
    var _tokenSymbol = "TCO";
    var _tokenDecimals = 8;
    var _tokenInitialSupply = 100000000 * Math.pow(10, _tokenDecimals);
    var _tokenMintable = true;
    var decimals = _tokenDecimals;
    var instance = null;

    function tokenInSmallestUnit(tokens, _tokenDecimals) {
        return tokens * Math.pow(10, _tokenDecimals);
    }

    beforeEach(async() => {
        instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, { from: accounts[0] });
    });

    it('Creation: should return the correct totalSupply after construction', async function() {
        let totalSupply = await instance.totalSupply();
        assert.equal(totalSupply, _tokenInitialSupply);
    });

    it('Creation: should return the correct balance of admin after construction', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        let adminBalance = await instance.balanceOf.call(accounts[0]);

        assert.equal(adminBalance, _tokenInitialSupply);
    });

    it('Creation: sould return correct token meta information', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        let name = await instance.name.call();
        assert.strictEqual(name, _tokenName, "Name value is not as expected.");

        let decimal = await instance.decimals.call();
        assert.strictEqual(decimal.toNumber(), _tokenDecimals, "Decimals value is not as expected");

        let symbol = await instance.symbol.call();
        assert.strictEqual(symbol, _tokenSymbol, "Symbol value is not as expected");

        let mintable = await instance.mintable.call();
        assert.equal(mintable, _tokenMintable, "Mintable value is not as expected");
    });

    it('Transfer: ether transfer to token address should fail.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        try {
            await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: web3.toWei("10", "Ether") });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Mint: Minting by owner should fail be default.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        try {
            await instance.mint(accounts[1], 100 * Math.pow(10, _tokenDecimals));
            let receiverBalance = await instance.balanceOf(accounts[1]);
            assert.equal(receiverBalance, 0, "receiver balance should still be 0.");
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    it('Mint: Owner seting up himself as mint agent. Should succeed.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });
        await instance.setMintAgent(accounts[0], true);

        //reading variable mintAgents array
        let mintAgentStatus = await instance.mintAgents.call(accounts[0]);
        assert.equal(mintAgentStatus, true, "Owner could not be set as mint agent.");
    });

    it('Mint: Token minting should succeed only if owner is the minting agent.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        await instance.setMintAgent(accounts[0], true);
        let mintAgentStatus = await instance.mintAgents.call(accounts[0]);
        assert.equal(mintAgentStatus, true, "Owner could not be set as mint agent.");
        await instance.mint(accounts[1], 100 * Math.pow(10, _tokenDecimals));
        let receiverBalance = await instance.balanceOf(accounts[1]);
        assert.equal(receiverBalance, 100 * Math.pow(10, _tokenDecimals), "Receiver balance should have been " + tokenInSmallestUnit(100) + ".");
    });

    it('Mint: Mint agent must be able to close miniting.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        await instance.setMintAgent(accounts[1], true);
        await instance.mint(accounts[2], 100 * Math.pow(10, _tokenDecimals), { from: accounts[1] });

        let receiverBalance = await instance.balanceOf(accounts[2]);
        assert.equal(receiverBalance, 100 * Math.pow(10, _tokenDecimals), "Receiver balance should have been " + tokenInSmallestUnit(100) + ".");
        await instance.finishMinting({ from: accounts[1] });
        let mintingFinished = await instance.mintingFinished.call();
        assert.equal(mintingFinished, true, "Miniting could not be finished by the mint agent (owner).");
    });

    it('Mint: Mint agent must close miniting & then he himself must not be able to mint anymore.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        await instance.setMintAgent(accounts[1], true);
        await instance.mint(accounts[2], 100 * Math.pow(10, _tokenDecimals), { from: accounts[1] });

        let receiverBalance = await instance.balanceOf(accounts[2]);
        assert.equal(receiverBalance, 100 * Math.pow(10, _tokenDecimals), "Receiver balance should have been " + tokenInSmallestUnit(100) + ".");
        await instance.finishMinting({ from: accounts[1] });
        let mintingFinished = await instance.mintingFinished.call();
        assert.equal(mintingFinished, true, "Miniting could not be finished by the mint agent (owner).");

        try {
            await instance.mint(accounts[2], 100 * Math.pow(10, _tokenDecimals), { from: accounts[1] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');

    });

    it('Mint: FinishMinting call from non-mint-agents should fail.', async function() {
        //let instance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, { from: accounts[0] });

        await instance.setMintAgent(accounts[1], true);
        await instance.mint(accounts[2], 100 * Math.pow(10, _tokenDecimals), { from: accounts[1] });

        let receiverBalance = await instance.balanceOf(accounts[2]);
        assert.equal(receiverBalance, 100 * Math.pow(10, _tokenDecimals), "Receiver balance should have been " + tokenInSmallestUnit(100) + ".");
        try {
            await instance.finishMinting({ from: accounts[3] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');

    });


});