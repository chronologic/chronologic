pragma solidity ^0.4.13;

contract SafeMathLib {
  function safeMul(uint a, uint b) constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) constant returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}
