pragma solidity ^0.4.11;

import "./Crowdsale.sol";
import "./DayToken.sol";
import "./SafeMathLib.sol";

/**
 * At the end of the successful crowdsale allocate % bonus of tokens to the team.
 *
 * Unlock tokens.
 *
 * BonusAllocationFinal must be set as the minting agent for the MintableToken.
 *
 */

 //TODO: Team address and test address cap? 
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  DayToken public token;
  Crowdsale public crowdsale;

  /** Total percent of tokens minted to the team at the end of the sale as base points (0.0001) */
  uint public totalMembers;
  uint public testAddressTokens;
  uint public allocatedBonus;
  mapping (address=>uint) bonusOf;
  /** Where we move the tokens at the end of the sale. */
  address[] public teamAddresses;
  address[] public testAddresses;
  
  event testAddressAdded(address TestAddress, uint id, uint balance);
  
  function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale, uint[] _bonusBasePoints, address[] _teamAddresses, address[] _testAddresses, uint _testAddressTokens) {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    //bonus & team address array size must match
    require(_bonusBasePoints.length == _teamAddresses.length);

    totalMembers = _teamAddresses.length;
    teamAddresses = _teamAddresses;
    testAddresses = _testAddresses;
    testAddressTokens = _testAddressTokens;
    
    //if any of the bonus is 0 throw
    // otherwise sum it up in totalAllocatedBonus
    for (uint i=0; i < totalMembers; i++){
      require(_bonusBasePoints[i] != 0);
      //if(_bonusBasePoints[i] == 0) throw;
    }

    //if any of the address is 0 or invalid throw
    //otherwise initialize the bonusOf array
    for (uint j=0;j < totalMembers;j++){
      require(_teamAddresses[j] != 0);
      //if(_teamAddresses[j] == 0) throw;
      bonusOf[_teamAddresses[j]] = _bonusBasePoints[j];
    }
  }

  /* Can we run finalize properly */
  function isSane() public constant returns (bool) {
    return (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() {

    // if finalized is not being called from the crowdsale 
    // contract then throw
    require(msg.sender == address(crowdsale));

    // if(msg.sender != address(crowdsale)) {
    //   throw;
    // }

    // get the total sold tokens count.
    uint tokensSold = crowdsale.tokensSold();
    

    for (uint i=0; i < totalMembers; i++){
      allocatedBonus = safeMul(tokensSold, bonusOf[teamAddresses[i]]) / 10000;
      token.mint(teamAddresses[i], allocatedBonus);
      token.addTeamAddress(teamAddresses[i], allocatedBonus);
    }

    //Add Test Addresses
    for(uint j=0; j < testAddresses.length ; j++){
      token.mint(testAddresses[j],testAddressTokens);
      uint id = token.addContributor(testAddresses[j], 0, testAddressTokens);
      testAddressAdded(testAddresses[j], id, testAddressTokens);
    }

    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    token.releaseTokenTransfer();
  }

}
