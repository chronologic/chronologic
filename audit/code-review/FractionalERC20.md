# FractionalERC20

Source file [../../contracts/FractionalERC20.sol](../../contracts/FractionalERC20.sol).

<br />

<hr />

```javascript
pragma solidity ^0.4.11;

import './ERC20.sol';

/**
 * A token that defines fractional units as decimals.
 */
contract FractionalERC20 is ERC20 {
  uint8 public decimals;
}

```
