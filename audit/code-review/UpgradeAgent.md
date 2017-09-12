# UpgradeAgent

Source file [../../contracts/UpgradeAgent.sol](../../contracts/UpgradeAgent.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
// BK Ok
contract UpgradeAgent {
  // BK Ok
  uint public originalSupply;
  /** Interface marker */
  // BK Ok
  function isUpgradeAgent() public constant returns (bool) {
    // BK Ok
    return true;
  }
  // BK Ok
  function upgradeFrom(address _from, uint256 _value) public;
}

```
