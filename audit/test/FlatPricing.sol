pragma solidity ^0.4.13;

import "./PricingStrategy.sol";
import "./SafeMathLib.sol";

/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract FlatPricing is PricingStrategy, SafeMathLib {

  /* How many weis one token costs */
  uint public oneTokenInWei;

  function FlatPricing(uint _oneTokenInWei) {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;
  }

  /**
   * Calculate the current price for buy in amount.
   *
   * 
   */
  function calculatePrice(uint value, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return safeMul(value, multiplier) / oneTokenInWei;
  }

}
