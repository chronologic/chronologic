pragma solidity ^0.4.11;


import '../../contracts/UpgradeableToken.sol';
import '../../contracts/StandardToken.sol';


// mock class using ReleasableToken
contract UpgradeableTokenMock is StandardToken,UpgradeableToken  {
  string public name;

  string public symbol;

  uint8 public decimals;

  function UpgradeableTokenMock(string _name, string _symbol, uint _initialSupply, uint8 _decimals) 
  UpgradeableToken (msg.sender){
    
    name = _name;
    symbol = _symbol;
    totalSupply = _initialSupply;
    decimals = _decimals;
    balances[msg.sender] = totalSupply;
  }

}
