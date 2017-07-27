'use strict';

const assertJump = require('./helpers/assertJump');
var pricingContract = artifacts.require("../contracts/FlatPricing.sol");

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

contract('FlatPricing', function(accounts) {
    var _oneTokenInWei = 41666666666666666;
    console.log(_oneTokenInWei);
    var _tokenDecimals = 8;
    var pricing = null;

    //console.log(_tranches);

    beforeEach(async() => {
        pricing = await pricingContract.new(_oneTokenInWei, { from: accounts[0] });
    });

    it('Creation: Pricing must be able to initialized properly.', async function() {
        assert.equal(await pricing.oneTokenInWei.call(), _oneTokenInWei);
    });

    it('Calculation: Pricing must be calculated properly.', async function() {
        var value;
        var weiRaised;
        var tokensSold;
        var buyer = accounts[2];
        var slab = 0;

        value = etherInWei(1);
        weiRaised = 0;
        tokensSold = 0;
        buyer = accounts[2];
        slab = 0;

        assert.equal(web3.toBigNumber(await pricing.calculatePrice(value, weiRaised, tokensSold, buyer, _tokenDecimals)).toNumber(), Math.floor(tokenInSmallestUnit(value / _oneTokenInWei, _tokenDecimals)));

        value = etherInWei(1);
        weiRaised = etherInWei(2);
        tokensSold = tokenInSmallestUnit(3000, _tokenDecimals);
        buyer = accounts[2];
        slab = 0;

        assert.equal(web3.toBigNumber(await pricing.calculatePrice(value, weiRaised, tokensSold, buyer, _tokenDecimals)).toNumber(), Math.floor(tokenInSmallestUnit(value / _oneTokenInWei, _tokenDecimals)));

        value = etherInWei(3);
        weiRaised = etherInWei(7);
        tokensSold = tokenInSmallestUnit(10100, _tokenDecimals);
        buyer = accounts[2];
        slab = 1;

        assert.equal(web3.toBigNumber(await pricing.calculatePrice(value, weiRaised, tokensSold, buyer, _tokenDecimals)).toNumber(), Math.floor(tokenInSmallestUnit(value / _oneTokenInWei, _tokenDecimals)));
    });

    it('Transfer: ether transfer to pricing address should fail.', async function() {

        try {
            await web3.eth.sendTransaction({ from: accounts[0], to: pricing.address, value: web3.toWei("10", "Ether") });
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown exception before');
    });




});