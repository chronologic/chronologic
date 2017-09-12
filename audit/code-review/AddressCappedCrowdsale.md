# AddressCappedCrowdsale

Source file [../../contracts/AddressCappedCrowdsale.sol](../../contracts/AddressCappedCrowdsale.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

// BK Ok
import "./Crowdsale.sol";

/**
 * ICO crowdsale contract that is capped by Number of addresses (investors).
 *
 * - Tokens are dynamically created during the crowdsale
 *
 */
// BK Ok
contract AddressCappedCrowdsale is Crowdsale {

    /* Maximum amount of wei this crowdsale can raise. */
    // BK Ok
    uint public weiIcoCap;

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
    * @param _minWei Minimum amount, in Wei for a contribution during ICO stage
    * @param _maxWei Maximum amount, in Wei for a contribution during ICO stage
    */
    // BK Ok - Constructor
    function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
        address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, 
        uint _preMinWei, uint _preMaxWei, uint _minWei,  uint _maxWei) 
        
        // BK Ok
        Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, 
        _preMinWei, _preMaxWei, _minWei, _maxWei) {
        // BK Ok
        weiIcoCap = _weiIcoCap;
        // BK Ok
        token = DayToken(_token);
    }

    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    // BK Ok
    function isBreakingCap(uint weiRaisedTotal) constant returns (bool limitBroken) {
        // BK Ok
        return weiRaisedTotal > weiIcoCap;
    }

    /**
    * Dynamically create tokens and assign them to the investor.
    */
    // BK Ok
    function assignTokens(address receiver, uint tokenAmount) private {
        // BK Ok
        token.mint(receiver, tokenAmount);
    }
}
```
