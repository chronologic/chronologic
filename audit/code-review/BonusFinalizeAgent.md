# BonusFinalizeAgent

Source file [../../contracts/BonusFinalizeAgent.sol](../../contracts/BonusFinalizeAgent.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

// BK Next 3 Ok
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
// BK Ok
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  // BK Ok
  DayToken public token;
  // BK Ok
  Crowdsale public crowdsale;
  /* Total number of addresses for team members */
  // BK Ok
  uint public totalTeamAddresses;
  /* Total number of test addresses */
  // BK Ok
  uint public totalTestAddresses;

  /* Number of tokens to be assigned per test address */
  // BK Ok
  uint public testAddressTokens;
  // BK Ok
  uint public allocatedBonus;
  /* Percentage of day tokens per team address eg 5% will be passed as 500 */
  // BK Ok
  uint public teamBonus;
  /* Total number of DayTokens to be stored in the DayToken contract as bounty */
  // BK Ok
  uint public totalBountyInDay;
  /** List of team addresses */
  // BK Ok
  address[] public teamAddresses;
  /** List of test addresses*/
  // BK Ok
  address[] public testAddresses;
  /* Stores the id of the next Team contributor */
  uint public nextTeamContributorId;
  /* Stores the id of the next Test contributor */
  uint public nextTestContributorId;
  
  // BK Next 2 Ok
  event TestAddressAdded(address testAddress, uint id, uint balance);
  event TeamMemberId(address adr, uint contributorId);

  // BK Ok - Constructor
  function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, 
    address[] _testAddresses, uint _testAddressTokens, uint _teamBonus, uint _totalBountyInDay) {
    // BK Ok
    token = _token;
    // BK Ok
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    // BK Ok
    require(address(crowdsale) != 0);

    // BK Ok
    totalTeamAddresses = _teamAddresses.length;
    // BK Ok
    teamAddresses = _teamAddresses;
    // BK Ok
    teamBonus = _teamBonus;

    // BK Ok
    totalTestAddresses = _testAddresses.length;
    // BK Ok
    testAddresses = _testAddresses;
    // BK Ok
    testAddressTokens = _testAddressTokens;
    // BK Ok
    totalBountyInDay = _totalBountyInDay;

    //if any of the address is 0 or invalid throw
    // BK Ok
    for (uint j = 0; j < totalTeamAddresses; j++) {
      // BK Ok
      require(_teamAddresses[j] != 0);
    }

    // BK Ok
    nextTeamContributorId = token.totalPreIcoAddresses() + token.totalIcoAddresses() + 1;
    // BK Ok
    nextTestContributorId = token.totalPreIcoAddresses() + token.totalIcoAddresses() + 
      totalTeamAddresses + 1;
  }

  /* Can we run finalize properly */
  // BK Ok - Constant function
  function isSane() public constant returns (bool) {
    // check addresses add up
    // BK Ok
    uint totalAddresses = token.totalPreIcoAddresses() + token.totalIcoAddresses() + totalTeamAddresses + 
      totalTestAddresses + token.totalPostIcoAddresses();
    // BK Ok
    return (totalAddresses == token.maxAddresses()) && (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  // BK Ok
  function finalizeCrowdsale() {

    // if finalized is not being called from the crowdsale 
    // contract then throw
    // BK Ok
    require(msg.sender == address(crowdsale));

    // get the total sold tokens count.
    // BK Ok
    uint tokensSold = crowdsale.tokensSold();
    
    //Mint the total bounty to be given out on daily basis and store it in the DayToken contract
    // BK Ok
    if (token.updateAllBalancesEnabled()) {
      // BK Ok
      token.mint(token, totalBountyInDay);
    }

    // Calculate team bonus to allocate
    // BK Ok
    allocatedBonus = safeMul(tokensSold, teamBonus) / 10000;

    // assign addresses with tokens
    // BK Ok
    for (uint i = 0; i < totalTeamAddresses; i++) {
      // BK Ok
      token.mint(teamAddresses[i], allocatedBonus);
      // BK Ok
      token.addTeamAddress(teamAddresses[i], nextTeamContributorId);
      // BK Ok - Log event
      TeamMemberId(teamAddresses[i], nextTeamContributorId);
      // BK Ok
      nextTeamContributorId++;
    }

    //Add Test Addresses
    // BK Ok
    for (uint j = 0; j < totalTestAddresses; j++) {
      // BK Ok
      token.mint(testAddresses[j],testAddressTokens);
      // BK Ok
      token.addTeamAddress(testAddresses[j],  nextTestContributorId);
      // BK Ok - Log event
      TestAddressAdded(testAddresses[j], nextTestContributorId, testAddressTokens);
      // BK Ok
      nextTestContributorId++;
    }
    
    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    // BK Ok
    token.releaseTokenTransfer();
  }
}

```
