# Haltable

Source file [../../contracts/Haltable.sol](../../contracts/Haltable.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;

// BK Ok
import './Ownable.sol';

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
// BK Ok
contract Haltable is Ownable {
  // BK Ok - Defaults to false
  bool public halted;

  // BK Ok - Will not work when halted
  modifier stopInEmergency {
    // BK Ok
    require(!halted);
    //if (halted) throw;
    // BK Ok
    _;
  }

  // BK Ok - Only works when halted
  modifier onlyInEmergency {
    // BK Ok
    require(halted);
    //if (!halted) throw;
    // BK Ok
    _;
  }

  // called by the owner on emergency, triggers stopped state
  // BK Ok - Only owner can execute this function to suspend services
  function halt() external onlyOwner {
    // BK Ok
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  // BK Ok - Only owner can execute this function to resume services, and can only resume if already halted
  function unhalt() external onlyOwner onlyInEmergency {
    // BK Ok
    halted = false;
  }

}

```
