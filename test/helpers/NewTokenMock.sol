pragma solidity ^0.4.11;

import '../../contracts/SafeMathLib.sol';
import '../../contracts/UpgradeableToken.sol';
import '../../contracts/MintableToken.sol';

/**
 * A sample token that is used as a migration testing target.
 *
 * This is not an actual token, but just a stub used in testing.
 */
contract NewTokenMock is StandardToken, UpgradeAgent {

  UpgradeableToken public oldToken;

  uint public originalSupply;

  function newTokenMock(UpgradeableToken _oldToken) {

    oldToken = _oldToken;

    // Let's not set bad old token
    require(address(oldToken) != 0);
  

    // Let's make sure we have something to migrate
    originalSupply = _oldToken.totalSupply();
    require(originalSupply != 0);

  }

  function upgradeFrom(address _from, uint256 _value) public {
    require(msg.sender == address(oldToken));

    // Mint new tokens to the migrator
    totalSupply = safeAdd(totalSupply,_value);
    balances[_from] = safeAdd(balances[_from],_value);
    Transfer(0, _from, _value);
  }

  function() public payable {
    throw;
  }

}