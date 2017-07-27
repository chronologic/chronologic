pragma solidity ^0.4.11;


import '../../contracts/ReleasableToken.sol';
import '../../contracts/StandardToken.sol';


// mock class using ReleasableToken
contract ReleasableTokenMock is StandardToken,ReleasableToken  {
  string public name;

  string public symbol;

  uint8 public decimals;

  function ReleasableTokenMock(string _name, string _symbol, uint _initialSupply, uint8 _decimals) {
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    totalSupply = _initialSupply;
    decimals = _decimals;
    balances[owner] = totalSupply;
  }

}
