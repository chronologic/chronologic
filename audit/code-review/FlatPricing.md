# FlatPricing

Source file [../../contracts/FlatPricing.sol](../../contracts/FlatPricing.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

import "./PricingStrategy.sol";
import "./SafeMathLib.sol";

/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
// BK Ok
contract FlatPricing is PricingStrategy, SafeMathLib {

  /* How many weis one token costs */
  // BK Ok
  uint public oneTokenInWei;

  // BK Ok
  function FlatPricing(uint _oneTokenInWei) {
    // BK Ok
    require(_oneTokenInWei > 0);
    // BK Ok
    oneTokenInWei = _oneTokenInWei;
  }

  /**
   * Calculate the current price for buy in amount.
   *
   * 
   */
  // BK NOTE - `value` is the `msg.value`, the ETH send with the transaction
  // BK NOTE - If `oneTokenInWei` is 0.01 * 10 ** decimals (100 tokens per ETH, or 0.01 ETH per token)
  // BK NOTE - result = msg.value * 10 ** decimals / 0.01 * 10 ** decimals
  // BK NOTE - result = msg.value / 0.01
  // BK NOTE - So if 1 ETH is sent, result = 100 
  // BK Ok
  function calculatePrice(uint value, uint decimals) public constant returns (uint) {
    // BK Ok
    uint multiplier = 10 ** decimals;
    // BK Ok
    return safeMul(value, multiplier) / oneTokenInWei;
  }

}

```
