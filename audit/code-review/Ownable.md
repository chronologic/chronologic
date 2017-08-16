# Ownable

Source file [../../contracts/Ownable.sol](../../contracts/Ownable.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
// BK Ok
contract Ownable {
  // BK Ok
  address public owner;
  // BK Ok
  address public newOwner;
  // BK Ok
  event OwnershipTransferred(address indexed _from, address indexed _to);
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  // BK Ok - Constructor
  function Ownable() {
    // BK Ok
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  // BK Ok
  modifier onlyOwner {
    // BK Ok
    require(msg.sender == owner);
    // BK Ok
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to. 
   */
  // BK Ok
  function transferOwnership(address _newOwner) onlyOwner {
    // BK Ok
    newOwner = _newOwner;
  }

  // BK Ok
  function acceptOwnership() {
    // BK Ok
    require(msg.sender == newOwner);
    // BK Ok - Log event
    OwnershipTransferred(owner, newOwner);
    // BK Ok
    owner = newOwner;
  }

}

```
