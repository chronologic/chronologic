pragma solidity ^0.4.11;


import '../../contracts/SafeMathLib.sol';


contract SafeMathMock is  SafeMathLib{
  uint public result;

  function mul(uint a, uint b) {
    result = safeMul(a, b);
  }


  function add(uint a, uint b) {
    result = safeAdd(a, b);
  }

  function sub(uint a, uint b) {
    result = safeSub(a, b);
  }


}
