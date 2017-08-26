# SafeMathLib

Source file [../../contracts/SafeMathLib.sol](../../contracts/SafeMathLib.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

// BK Ok
contract SafeMathLib {
  // BK Ok
  function safeMul(uint a, uint b) constant returns (uint) {
    // BK Ok
    uint c = a * b;
    // BK Ok
    assert(a == 0 || c / a == b);
    // BK Ok
    return c;
  }

  // BK Ok
  function safeSub(uint a, uint b) constant returns (uint) {
    // BK Ok
    assert(b <= a);
    // BK Ok
    return a - b;
  }

  // BK Ok
  function safeAdd(uint a, uint b) constant returns (uint) {
    // BK Ok
    uint c = a + b;
    // BK Ok
    assert(c>=a);
    // BK Ok
    return c;
  }
}

```
