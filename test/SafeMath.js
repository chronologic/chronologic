const assertJump = require('./helpers/assertJump');
var SafeMathMock = artifacts.require("./helpers/SafeMathMock.sol");
var SafeMathLib = artifacts.require("./SafeMathLib.sol");


contract('SafeMath', function(accounts) {

    let safeMath;
    before(async function() {
        safeMath = await SafeMathMock.new();
    });

    it("mul: multiplies correctly", async function() {
        let a = 5678;
        let b = 1234;
        let mult = await safeMath.mul(a, b);
        let result = await safeMath.result();
        assert.equal(result, a * b);
    });


    it("add: adds correctly", async function() {
        let a = 5678;
        let b = 1234;
        let add = await safeMath.add(a, b);
        let result = await safeMath.result();

        assert.equal(result, a + b);
    });


    it("sub: subtracts correctly", async function() {
        let a = 5678;
        let b = 1234;
        let subtract = await safeMath.sub(a, b);
        let result = await safeMath.result();

        assert.equal(result, a - b);
    });


    it("sub: should throw an error if subtraction result would be negative", async function() {
        let a = 1234;
        let b = 5678;
        try {
            let subtract = await safeMath.sub(a, b);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });


    it("add: should throw an error on addition overflow", async function() {
        let a = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        let b = 1;
        try {
            let add = await safeMath.add(a, b);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });



    it("mul: should throw an error on multiplication overflow", async function() {
        let a = 115792089237316195423570985008687907853269984665640564039457584007913129639933;
        let b = 2;
        try {
            let multiply = await safeMath.mul(a, b);
        } catch (error) {
            return assertJump(error);
        }
        assert.fail('should have thrown before');
    });



});