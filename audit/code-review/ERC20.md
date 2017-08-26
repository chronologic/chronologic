# ERC20

Source file [../../contracts/ERC20.sol](../../contracts/ERC20.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;
// BK Ok
import './ERC20Basic.sol';
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  // BK Ok
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  // BK Ok
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  // BK Ok
  function approve(address _spender, uint _value) returns (bool success);
  // BK Ok - Event
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

```
