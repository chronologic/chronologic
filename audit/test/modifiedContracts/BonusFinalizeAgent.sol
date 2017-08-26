pragma solidity ^0.4.13;

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
  /* Total number of addresses for team members */
  uint public totalTeamAddresses;
  /* Total number of test addresses */
  uint public totalTestAddresses;

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
  /* Stores the id of the next Team contributor */
  uint public nextTeamContributorId;
  /* Stores the id of the next Test contributor */
  uint public nextTestContributorId;
  
  event TestAddressAdded(address testAddress, uint id, uint balance);
  event TeamMemberId(address adr, uint contributorId);

  function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, 
    address[] _testAddresses, uint _testAddressTokens, uint _teamBonus, uint _totalBountyInDay) {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    totalTeamAddresses = _teamAddresses.length;
    teamAddresses = _teamAddresses;
    teamBonus = _teamBonus;

    totalTestAddresses = _testAddresses.length;
    testAddresses = _testAddresses;
    testAddressTokens = _testAddressTokens;
    totalBountyInDay = _totalBountyInDay;

    //if any of the address is 0 or invalid throw
    for (uint j = 0; j < totalTeamAddresses; j++) {
      require(_teamAddresses[j] != 0);
    }

    nextTeamContributorId = token.totalPreIcoAddresses() + token.totalIcoAddresses() + 1;
    nextTestContributorId = token.totalPreIcoAddresses() + token.totalIcoAddresses() + 
      totalTeamAddresses + 1;
  }

  /* Can we run finalize properly */
  function isSane() public constant returns (bool) {
    // check addresses add up
    uint totalAddresses = token.totalPreIcoAddresses() + token.totalIcoAddresses() + totalTeamAddresses + 
      totalTestAddresses + token.totalPostIcoAddresses();
      
    return (totalAddresses == token.maxAddresses()) && 
      (token.mintAgents(address(this)) == true) && 
      (token.releaseAgent() == address(this));
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() {

    // if finalized is not being called from the crowdsale 
    // contract then throw
    require(msg.sender == address(crowdsale));

    // get the total sold tokens count.
    uint tokensSold = crowdsale.tokensSold();
    
    //Mint the total bounty to be given out on daily basis and store it in the DayToken contract
    if (token.updateAllBalancesEnabled()) {
      token.mint(token, totalBountyInDay);
    }

    // Calculate team bonus to allocate
    allocatedBonus = safeMul(tokensSold, teamBonus) / 10000;

    // BK NOTE - The following block works when the token.addContributor(...) statement is commented out
    // assign addresses with tokens
    for (uint i = 0; i < totalTeamAddresses; i++) {
      token.mint(teamAddresses[i], allocatedBonus);
      // token.addTeamAddress(teamAddresses[i], nextTeamContributorId);
      TeamMemberId(teamAddresses[i], nextTeamContributorId);
      nextTeamContributorId++;
    }

    // BK NOTE - The following block works when the token.addContributor(...) statement is commented out
    //Add Test Addresses
    for (uint j = 0; j < totalTestAddresses; j++) {
      token.mint(testAddresses[j],testAddressTokens);
      // token.addContributor(nextTestContributorId, testAddresses[j], 0);
      token.addContributorTest(nextTestContributorId, testAddresses[j], 0);
      TestAddressAdded(testAddresses[j], nextTestContributorId, testAddressTokens);
      nextTestContributorId++;
    }

    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    token.releaseTokenTransfer();
  }
}
