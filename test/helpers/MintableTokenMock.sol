pragma solidity ^0.4.11;


import '../../contracts/MintableToken.sol';


// mock class using ReleasableToken
contract MintableTokenMock is MintableToken  {
  string public name;

  string public symbol;
  bool public mintable;

  uint8 public decimals;

  function MintableTokenMock(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable) {
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    totalSupply = _initialSupply;
    decimals = _decimals;
    balances[owner] = totalSupply;
    mintable = _mintable;
    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw; // Cannot create a token without supply and no minting
      }
    }
  }

  function finishMinting() onlyMintAgent canMint {
      mintingFinished = true;
  }

}
