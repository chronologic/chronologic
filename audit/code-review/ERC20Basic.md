# ERC20Basic

Source file [../../contracts/ERC20Basic.sol](../../contracts/ERC20Basic.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
// BK Ok
contract ERC20Basic {
  // BK Ok
  uint public totalSupply;
  // BK Ok
  function balanceOf(address who) constant returns (uint);
  // BK Ok
  function transfer(address _to, uint _value) returns (bool success);
  // BK Ok - Event
  event Transfer(address indexed from, address indexed to, uint value);
}
```
