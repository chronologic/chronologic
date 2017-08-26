# PricingStrategy

Source file [../../contracts/PricingStrategy.sol](../../contracts/PricingStrategy.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

/**
 * Interface for defining crowdsale pricing.
 */
// BK Ok
contract PricingStrategy {

  /** Interface declaration. */
  // BK Ok
  function isPricingStrategy() public constant returns (bool) {
    // BK Ok
    return true;
  }
  
  /** Self check if all references are correctly set.
   *
   * Checks that pricing strategy matches crowdsale parameters.
   */
  // BK Ok
  function isSane(address crowdsale) public constant returns (bool) {
	// BK Ok
    require(crowdsale != 0); 
    // BK Ok
    return true;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  // BK Ok
  function calculatePrice(uint value, uint decimals) public constant returns (uint tokenAmount);
}

```
