pragma solidity ^0.4.11;

import "./Crowdsale.sol";
import "./DayToken.sol";
import "./SafeMathLib.sol";

/**
 * At the end of the successful crowdsale allocate % bonus of tokens to the team.
 * After assigning addresses to team members, assign test addresses 
 * Mint total bounty and store it in the DayToken contract
 * Unlock tokens.
 *
 * BonusAllocationFinal must be set as the minting agent for the MintableToken.
 *
 */

 //TODO: Team address and test address cap? 
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  DayToken public token;
  Crowdsale public crowdsale;
  /* Total number of team members */
  uint public totalMembers;
  /* Number of tokens to be assigned per test address */
  uint public testAddressTokens;
  uint public allocatedBonus;
  /* Percentage of day tokens per team address eg 5% will be passed as 500 */
  uint public teamBonus;
  /* Total number of DayTokens to be stored in the DayToken contract as bounty */
  uint public totalBountyInDay;
  /** List of team addresses */
  address[] public teamAddresses;
  /** List of test addresses*/
  address[] public testAddresses;
  
  event testAddressAdded(address TestAddress, uint id, uint balance);
  event teamMemberId(address adr, uint contributorId);

  function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, address[] _testAddresses, uint _testAddressTokens, uint _teamBonus, uint _totalBountyInDay) {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    totalMembers = _teamAddresses.length;
    teamAddresses = _teamAddresses;
    teamBonus = _teamBonus;

    testAddresses = _testAddresses;
    testAddressTokens = _testAddressTokens;
    totalBountyInDay = _totalBountyInDay;

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
    
    //Mint the total bounty to be given out on daily basis and store it in the DayToken contract
    token.mint(token, totalBountyInDay);

    // Calculate team bonus and assign them the addresses with tokens
    for (uint i=0; i < totalMembers; i++){
      allocatedBonus = safeMul(tokensSold, teamBonus) / 10000;
      token.mint(teamAddresses[i], allocatedBonus);
      uint id = token.addAddressWithId(teamAddresses[i], 3228 + i);
      teamMemberId(teamAddresses[i], id);
    }

    //Add Test Addresses
    for(uint j=0; j < testAddresses.length ; j++){
      token.mint(testAddresses[j],testAddressTokens);
      id = token.addAddressWithId(testAddresses[j],  3228 + i + j);
      testAddressAdded(testAddresses[j], id, testAddressTokens);
    }
    
    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    token.releaseTokenTransfer();
  }
}
