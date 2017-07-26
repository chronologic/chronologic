'use strict';

const assertJump = require('./helpers/assertJump');
const timer = require('./helpers/timer');
var Token = artifacts.require("./DayTokenTest.sol");
contract('DayToken', function(accounts) {
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
    var _bounty = 100000000;
    var _minBalanceToSell = 8888;


    beforeEach(async() => {
        tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, _minBalanceToSell, { from: accounts[0] });
        pricingInstance = await Pricing.new(_oneTokenInWei, { from: accounts[0] });
        multisigWalletInstance = await MultisigWallet.new(_listOfOwners, _minRequired);
        finalizeAgentInstance = await FinalizeAgent.new(tokenInstance.address, multisigWalletInstance.address, _teamAddresses, _testAddresses, _testAddressTokens, _teamBonus);
        crowdsaleInstance = await Crowdsale.new(tokenInstance.address, pricingInstance.address, multisigWalletInstance.address, _startTime, _endTime, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses);
    });

    it('Creation: should return the correct totalSupply after construction', async function() {
        let totalSupply = await tokenInstance.totalSupply();

        assert.equal(totalSupply, _tokenInitialSupply);
    });

    it('Creation: should return the correct balance of admin after construction', async function() {
        let adminBalance = await tokenInstance.balanceOf.call(accounts[0], 0);

        assert.equal(adminBalance, _tokenInitialSupply);
    });

    it('Creation: sould return correct token meta information', async function() {

        let name = await tokenInstance.name.call();
        assert.strictEqual(name, _tokenName, "Name value is not as expected.");

        let decimal = await tokenInstance.decimals.call();
        assert.strictEqual(decimal.toNumber(), _tokenDecimals, "Decimals value is not as expected");

        let symbol = await tokenInstance.symbol.call();
        assert.strictEqual(symbol, _tokenSymbol, "Symbol value is not as expected");
    });

    it('Transfer: ether transfer to token address should fail.', async function() {
        try {
            await web3.eth.sendTransaction({ from: accounts[0], to: tokenInstance.address, value: web3.toWei("10", "Ether") });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });

    // it('Transfer: should return correct balances in receiver account after transfer', async function() {
    //     let tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, accounts, { gas:45123880 } );

    //     let balance0_old = await tokenInstance.balanceOf(accounts[0],1);
    //     assert.equal(balance0_old, 100000000 * Math.pow(10, decimals), "balance0_old is not 100,000,000");

    //     let balance1_old = await tokenInstance.balanceOf(accounts[1],1);
    //     assert.equal(balance1_old, 0, "balance1_old is not 0");

    //     await tokenInstance.transfer(accounts[1], 100000000 * Math.pow(10, decimals));

    //     let balance0_new = await tokenInstance.balanceOf(accounts[0],1);
    //     assert.equal(balance0_new, 0, "balance0_new is not 0");

    //     let balance1_new = await tokenInstance.balanceOf(accounts[1],1);
    //     assert.equal(balance1_new, 100000000 * Math.pow(10, decimals), "balance1_new is not 100,000,000");
    // });

    it('Transfer: should throw an error when trying to transfer more than balance', async function() {
        try {
            await tokenInstance.transfer(accounts[1], 101000000 * Math.pow(10, decimals));
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    it('Transfer: should throw an error when trying to transfer 0 balance', async function() {
        try {
            await tokenInstance.transfer(accounts[1], 0);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    it('Transfer: should throw an error when trying to transfer to himself', async function() {
        try {
            await tokenInstance.transfer(accounts[0], 100000000 * Math.pow(10, decimals));
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    it('Transfer: should throw an error since the token is not released', async function() {
        try {
            await tokenInstance.transfer(accounts[1], 100000000 * Math.pow(10, decimals));
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    // it('Transfer: should return correct balances after transfering from another account', async function() {
    //     let tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, accounts, { gas:45123880 } );
    //     await tokenInstance.approve(accounts[1], 100000000 * Math.pow(10, decimals));
    //     await tokenInstance.transferFrom(accounts[0], accounts[2], 100000000 * Math.pow(10, decimals), { from: accounts[1] });

    //     let balance0 = await tokenInstance.balanceOf(accounts[0]);
    //     assert.equal(balance0, 0);

    //     let balance1 = await tokenInstance.balanceOf(accounts[2]);
    //     assert.equal(balance1, 100000000 * Math.pow(10, decimals));

    //     let balance2 = await tokenInstance.balanceOf(accounts[1]);
    //     assert.equal(balance2, 0);
    // });

    it('Transfer: should throw an error when trying to transfer more than allowed', async function() {
        await tokenInstance.approve(accounts[1], 99 * Math.pow(10, decimals));
        try {
            await tokenInstance.transferFrom(accounts[0], accounts[2], 100 * Math.pow(10, decimals), { from: accounts[1] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    it('Approval: should return the correct allowance amount after approval', async function() {
        await tokenInstance.approve(accounts[1], 100 * Math.pow(10, decimals));
        let allowance = await tokenInstance.allowance(accounts[0], accounts[1]);

        assert.equal(allowance, 100 * Math.pow(10, decimals));
    });

    it('Approval: attempt withdrawal from acconut with no allowance (should fail)', async function() {
        try {
            await tokenInstance.transferFrom(accounts[0], accounts[2], 100 * Math.pow(10, decimals), { from: accounts[1] });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

    // it('Approval: allow accounts[1] 100 to withdraw from accounts[0]. Withdraw 60 and then approve 0 & attempt transfer.', async function() {
    //     let tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, accounts, { gas:45123880 } );
    //     await tokenInstance.approve(accounts[1], 100 * Math.pow(10, decimals), { from: accounts[0] });
    //     await tokenInstance.transferFrom(accounts[0], accounts[2], 60 * Math.pow(10, decimals), { from: accounts[1] });
    //     await tokenInstance.approve(accounts[1], 0);
    //     try {
    //         await tokenInstance.transferFrom(accounts[0], accounts[2], 40 * Math.pow(10, decimals), { from: accounts[1] });
    //     } catch (error) {
    //         return assertJump(error);
    //     }
    //     assert.fail('should have thrown before');
    // });

    // it('Approval: msg.sender approves accounts[1] of 100 & withdraws 50 & 60 (2nd tx should fail)', async function() {
    //     let tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, accounts, { gas:45123880 } );
    //     await tokenInstance.approve(accounts[1], 100 * Math.pow(10, decimals));
    //     await tokenInstance.transferFrom(accounts[0], accounts[2], 50 * Math.pow(10, decimals), { from: accounts[1] });
    //     try {
    //         await tokenInstance.transferFrom(accounts[0], accounts[2], 60 * Math.pow(10, decimals), { from: accounts[1] });
    //     } catch (error) {
    //         return assertJump(error);
    //     }
    //     assert.fail('should have thrown before');
    // });

    // it('Approval: msg.sender approves accounts[1] of 100 & withdraws 50 twice successfully.', async function() {
    //     let tokenInstance = await Token.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable, _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty, accounts, { gas:45123880 } );

    //     await tokenInstance.approve(accounts[1], 100 * Math.pow(10, decimals));
    //     let allowance_stage_1 = await tokenInstance.allowance(accounts[0], accounts[1]);
    //     assert.equal(allowance_stage_1, 100 * Math.pow(10, decimals), "Stage 1 allowance must be 100 tokens (10000000000)");

    //     await tokenInstance.transferFrom(accounts[0], accounts[2], 50 * Math.pow(10, decimals), { from: accounts[1] });
    //     let allowance_stage_2 = await tokenInstance.allowance(accounts[0], accounts[1]);
    //     assert.equal(allowance_stage_2, 50 * Math.pow(10, decimals), "Stage 2 allowance must be 50 tokens (5000000000)");

    //     await tokenInstance.transferFrom(accounts[0], accounts[2], 50 * Math.pow(10, decimals), { from: accounts[1] });
    //     let allowance_stage_3 = await tokenInstance.allowance(accounts[0], accounts[1]);
    //     assert.equal(allowance_stage_3, 0, "Stage 3 allowance must be 0 tokens");

    // });
    it('Balance: Should return correct phase count', async function() {
        let phase = await tokenInstance.getPhaseCount(0);
        assert.equal(phase, 1);
        let phase1 = await tokenInstance.getPhaseCount(1056);
        assert.equal(phase1, 13);
        let phase2 = await tokenInstance.getPhaseCount(1935);
        assert.equal(phase2, 22);
        let phase3 = await tokenInstance.getPhaseCount(2270);
        assert.equal(phase3, 26);
        let phase4 = await tokenInstance.getPhaseCount(8986);
        assert.equal(phase4, 103);
    });
    //DOUBT
    it('Balance: Should return correct day count', async function() {
        let day = (await tokenInstance.getDayCount()).valueOf();

    });
    it('Balance: Should return correct Minting Power by Address', async function() {
        let MintingPower0 = (await tokenInstance.getMintingPowerByAddress(accounts[0])).valueOf();
        assert.equal(MintingPower0, 0);
        let MintingPower1 = (await tokenInstance.getMintingPowerByAddress(accounts[1])).valueOf();
        assert.equal(MintingPower1, 10000000000000000000);
        let MintingPower2 = (await tokenInstance.getMintingPowerByAddress(accounts[27])).valueOf();
        assert.equal(MintingPower2, 9959495949594959496);
    });
    it('Balance: Should return correct Minting Power by ID', async function() {
        let MintingPower1 = (await tokenInstance.getMintingPowerById(1)).valueOf();
        assert.equal(MintingPower1, 10000000000000000000);
        let MintingPower2 = (await tokenInstance.getMintingPowerById(7)).valueOf();
        assert.equal(MintingPower2, 9989498949894989499);
    });
    it('Balance: Should return correct Balance by address', async function() {
        let balance1 = (await tokenInstance.balanceOf(accounts[1], 3)).valueOf();
        assert.isAtMost(81599839200 - balance1, 10);
        let balance2 = (await tokenInstance.balanceOf(accounts[2], 3)).valueOf();
        assert.isAtMost(81599112002 - balance2, 10);
        let balance3 = (await tokenInstance.balanceOf(accounts[25], 2)).valueOf();
        assert.isAtMost(80785920111 - balance3, 10);

    });
    it('Balance: Should return correct Balance by ID', async function() {
        let balance1 = (await tokenInstance.balanceById(1, 3)).valueOf();
        assert.isAtMost(81599839200 - balance1, 10);
        let balance2 = (await tokenInstance.balanceById(2, 3)).valueOf();
        assert.isAtMost(81599112002 - balance2, 10);
        let balance3 = (await tokenInstance.balanceById(37, 1)).valueOf();
        assert.isAtMost(79987603960 - balance3, 10);
    });
    it('Balance: Should Update all balances and provide bounty to caller', async function() {
        let call1 = (await tokenInstance.updateAllBalances(2));
        let balance1 = (await tokenInstance.balanceOf(accounts[45], -1)).valueOf(); // -1 to indicate that we want to check balance without updating it again
        assert.isAtMost(80781120361 - balance1, 10);
        let bounty = (await tokenInstance.balanceOf(accounts[0], -1)).valueOf();
        assert.equal(bounty, 100000000);
        let balance2 = (await tokenInstance.balanceOf(accounts[10], -1)).valueOf();
        assert.isAtMost(80789520018 - balance2, 10);

        let call2 = (await tokenInstance.updateAllBalances(1));
        let balance11 = (await tokenInstance.balanceOf(accounts[49], -1)).valueOf(); // -1 to indicate that we want to check balance without updating it again
        assert.isAtMost(79986178218 - balance11, 10);
        let bounty1 = (await tokenInstance.balanceOf(accounts[0], -1)).valueOf();
        assert.equal(bounty1, 200000000);
        let balance21 = (await tokenInstance.balanceOf(accounts[25], -1)).valueOf();
        assert.isAtMost(79989029703 - balance21, 10);
    });
    it('Balance: should throw an error when trying to update all balances multiple times on same day', async function() {
        let call1 = (await tokenInstance.updateAllBalances(2));
        try {
            await tokenInstance.updateAllBalances(2);

        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });

});