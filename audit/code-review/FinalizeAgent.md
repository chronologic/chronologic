# FinalizeAgent

Source file [../../contracts/FinalizeAgent.sol](../../contracts/FinalizeAgent.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

/**
 * Finalize agent defines what happens at the end of succeseful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
// BK Ok
contract FinalizeAgent {

  // BK Ok
  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn't allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  // BK Ok
  function isSane() public constant returns (bool);

  /** Called once by crowdsale finalize() if the sale was success. */
  // BK Ok
  function finalizeCrowdsale();

}

```
