pragma solidity ^0.4.11;

import "./Crowdsale.sol";

/**
 * ICO crowdsale contract that is capped by Number of addresses (investors).
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract AddressCappedCrowdsale is Crowdsale {

    /* Maximum amount of wei this crowdsale can raise. */
    uint public weiIcoCap;
    uint public maxIcoAddresses;

    function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, uint _preMinWei, uint _preMaxWei, uint _minWei, uint _maxWei, uint _maxPreAddresses, uint _maxIcoAddresses) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, _preMinWei, _preMaxWei,  _minWei,  _maxWei,  _maxPreAddresses) {
        weiIcoCap = _weiIcoCap;
        maxIcoAddresses = _maxIcoAddresses;
        token = DayToken(_token);

    }
    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
        return weiRaisedTotal > weiIcoCap;
    }

    function isCrowdsaleFull() public constant returns (bool) {
        return token.latestContributerId() > maxIcoAddresses;
    }

    /**
    * Dynamically create tokens and assign them to the investor.
    */
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }
}