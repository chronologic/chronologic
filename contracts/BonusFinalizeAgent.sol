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
  //uint public teamAdrStartingId;
  uint public teamBonus;
  /** Where we move the tokens at the end of the sale. */
  address[] public teamAddresses;
  address[] public testAddresses;
  
  event testAddressAdded(address TestAddress, uint id, uint balance);
  event teamMemberId(address adr, uint contributorId);

  function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, address[] _testAddresses, uint _testAddressTokens, uint _teamBonus) {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    totalMembers = _teamAddresses.length;
    teamAddresses = _teamAddresses;
    teamBonus = _teamBonus;

    testAddresses = _testAddresses;
    testAddressTokens = _testAddressTokens;

    //if any of the address is 0 or invalid throw
    for (uint j=0;j < totalMembers;j++){
      require(_teamAddresses[j] != 0);
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

    // get the total sold tokens count.
    uint tokensSold = crowdsale.tokensSold();
    

    for (uint i=0; i < totalMembers; i++){
      allocatedBonus = safeMul(tokensSold, teamBonus) / 10000;
      token.mint(teamAddresses[i], allocatedBonus);
      uint id = token.addAddressWithId(teamAddresses[i], 3217 + i);
      teamMemberId(teamAddresses[i], id);
    }

    //Add Test Addresses
    for(uint j=0; j < testAddresses.length ; j++){
      token.mint(testAddresses[j],testAddressTokens);
      id = token.addAddressWithId(testAddresses[j],  3217 + i + j);
      testAddressAdded(testAddresses[j], id, testAddressTokens);
    }
    token.setTeamTestEndId(3217 + i +j);
    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    token.releaseTokenTransfer();
  }

}
