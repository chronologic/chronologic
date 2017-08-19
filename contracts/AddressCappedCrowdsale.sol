pragma solidity ^0.4.11;

import "./Crowdsale.sol";

/**
 * ICO crowdsale contract that is capped by Number of addresses (investors).
 *
 * - Tokens are dynamically created during the crowdsale
 *
 */
contract AddressCappedCrowdsale is Crowdsale {

    /* Maximum amount of wei this crowdsale can raise. */
    uint public weiIcoCap;

    /* Maximum Number of addresses allowed during ICO. */
    uint public maxIcoAddresses;

    /** Constructor to initialize all variables, including Crowdsale variables
    * @param _token Address of the deployed DayToken contract
    * @param _pricingStrategy Address of the deployed pricing statergy contract (FlatPricing)
    * @param _multisigWallet Address of the deployed Multisig wallet
    * @param _start unix timestamp for start of ICO
    * @param _end unix timestamp for end of ICO
    * @param _minimumFundingGoal Minimum amount to be raised in Wei
    * @param _weiIcoCap Hard cap for amount to be raised during ICO in wei
    * @param _preMinWei Minimum amount, in wei for a contribution during pre-ICO stage
    * @param _preMaxWei Maximum amount, in Wei for a contribution during pre-ICO stage
    * @param _maxWei Maximum amount, in Wei for a contribution during ICO stage
    * @param _maxPreAddresses Maximum number of addresses to be alloted during pre-ICO
    * @param _maxIcoAddresses Maximum number of addresses to be alloted (sold) during ICO
    */
    function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, uint _preMinWei,uint _minWei, uint _preMaxWei, uint _maxWei, uint _maxPreAddresses, uint _maxIcoAddresses) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, _preMinWei, _preMaxWei, _minWei, _maxWei,  _maxPreAddresses) {
        weiIcoCap = _weiIcoCap;
        maxIcoAddresses = _maxIcoAddresses;
        token = DayToken(_token);
    }

    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint weiRaisedTotal) constant returns (bool limitBroken) {
        return weiRaisedTotal > weiIcoCap;
    }

    /** Called from getStage() to confirm if number of addresses exceeds our Maximum addresses during ICO cap */
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