/**
 * ICO crowdsale contract that is capped by Number of addresses (investors).
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
 contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address _newOwner) onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    //if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    //if (!halted) throw;
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  /** Return true if we can run finalizeCrowdsale() properly.
   *
   * This is a safety check function that doesn't allow crowdsale to begin
   * unless the finalizer has been set up properly.
   */
  function isSane() public constant returns (bool);

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale();

}
contract SafeMathLib {
  function safeMul(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}
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



/**
 * Abstract base contract for token sales.
 *
 * Handle
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */


/**
 * A crowdsale token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract StandardToken is ERC20, SafeMathLib {
  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {
    if (balances[msg.sender] >= _value 
        && _value > 0 
        && balances[_to] + _value > balances[_to]
        ) {
      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
    
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    if (balances[_from] >= _value   // From a/c has balance
        && _allowance >= _value    // Transfer approved
        && _value > 0              // Non-zero transfer
        && balances[_to] + _value > balances[_to]  // Overflow check
        ){
    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
        }
    else {
      return false;
    }
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    //if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent).
   */
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    Transfer(0, receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    // if(!mintAgents[msg.sender]) {
    //     throw;
    // }
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    //if(mintingFinished) throw;
    _;
  }
}

/**
 * A sample token that is used as a migration testing target.
 *
 * This is not an actual token, but just a stub used in testing.
 */


/**
 * Interface for defining crowdsale pricing.
 */
contract PricingStrategy {

  /** Interface declaration. */
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }
  
  /** Self check if all references are correctly set.
   *
   * Checks that pricing strategy matches crowdsale parameters.
   */
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param tokensSold - how much tokens have been sold this far
   * @param weiRaised - how much money has been raised this far
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {

    if(!released) {
        require(transferAgents[_sender]);
        // if(!transferAgents[_sender]) {
        //     throw;
        // }
    }

    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don't do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    // if(releaseState != released) {
    //     throw;
    // }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    // if(msg.sender != releaseAgent) {
    //     throw;
    // }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}


contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint256 public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {
    UpgradeState state = getUpgradeState();
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));
    // if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
    //   // Called in a bad state
    //   throw;
    // }

    // Validate input value.
    if (value == 0) throw;

    balances[msg.sender] = safeSub(balances[msg.sender],value);

    // Take tokens out from circulation
    totalSupply = safeSub(totalSupply,value);
    totalUpgraded = safeAdd(totalUpgraded,value);

    // Upgrade agent reissues the tokens
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());
    // if(!canUpgrade()) {
    //   // The token is not yet in a state that we could think upgrading
    //   throw;
    // }

    require(agent != 0x0);
    //if (agent == 0x0) throw;
    // Only a master can designate the next agent
    require(msg.sender == upgradeMaster);
    //if (msg.sender != upgradeMaster) throw;
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);
    //if (getUpgradeState() == UpgradeState.Upgrading) throw;

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    //if(!upgradeAgent.isUpgradeAgent()) throw;
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply);
    //if (upgradeAgent.originalSupply() != totalSupply) throw;

    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeMaster(address master) public {
    require(master != 0x0);
    //if (master == 0x0) throw;
    require(msg.sender == upgradeMaster);
    //if (msg.sender != upgradeMaster) throw;
    upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


contract UpgradeAgent {
  uint public originalSupply;
  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}


contract newToken is StandardToken, UpgradeAgent {

  UpgradeableToken public oldToken;

  uint public originalSupply;

  function newToken(UpgradeableToken _oldToken) {

    oldToken = _oldToken;

    // Let's not set bad old token
    require(address(oldToken) != 0);
    // if(address(oldToken) == 0) {
    //   throw;
    // }

    // Let's make sure we have something to migrate
    originalSupply = _oldToken.totalSupply();
    require(originalSupply != 0);
    // if(originalSupply == 0) {
    //   throw;
    // }
  }

  function upgradeFrom(address _from, uint256 _value) public {
    require(msg.sender == address(oldToken));
    //if (msg.sender != address(oldToken)) throw; // only upgrade from oldToken

    // Mint new tokens to the migrator
    totalSupply = safeAdd(totalSupply,_value);
    balances[_from] = safeAdd(balances[_from],_value);
    Transfer(0, _from, _value);
  }

  function() public payable {
    throw;
  }

}
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

enum sellingStatus {NOTONSALE, SOLD, EXPIRED, ONSALE}
struct Contributor
{
    address adr;
	uint256 initialContributionWei;
    //uint256 balance;
    uint256 lastUpdatedOn; //Day from Minting Epoch
    uint256 mintingPower;
    int totalTransferredWei;
    uint expiryBlockNumber;
    uint256 minPriceinDay;
    sellingStatus status;
    uint256 sellingPriceInDay;
}
mapping (address => uint) public idOf;
mapping (uint256 => Contributor) public contributors;
mapping (address => uint256) public teamIssuedTimestamp;
uint256 public latestAllUpdate;
uint256 public latestContributerId;
uint256 public maxAddresses;
uint256 public minMintingPower;
uint256 public maxMintingPower;
uint256 public halvingCycle;
uint256 public initialBlockCount;
uint256 public initialBlockTimestamp;
uint256 public mintingDec; 
uint256 public bounty;
address crowdsaleAddress;
uint256 minBalanceToSell;
uint256 teamLockPeriodInSec;  //Initialize and set function

event UpdatedTokenInformation(string newName, string newSymbol); 
event UpdateFailed(uint id); 
event UpToDate (bool status);
event MintingAdrTransferred(address from, address to);
event ContributorAdded(address adr, uint id);
event onSale(uint id, address adr, uint minPriceinDay, uint expiryBlockNumber);
event teamMemberId(address adr, uint contributorId);
event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, uint contributorId);

modifier onlyCrowdsale(){
    require(msg.sender==crowdsaleAddress);
    _;
}

modifier onlyContributor(uint id){
    require(id <= latestContributerId && id != 0);
    _;
}
string public name; 

string public symbol; 

uint8 public decimals; 

    /**
        * Construct the token.
        *
        * This token must be created through a team multisig wallet, so that it is owned by that wallet.
        *
        * @param _name Token name
        * @param _symbol Token symbol - should be all caps
        * @param _initialSupply How many tokens we start with
        * @param _decimals Number of decimal places
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
        */
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable, uint _maxAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, address[] testAddresses, uint256 _minBalanceToSell) UpgradeableToken(msg.sender) {
        //uint256 _maxMintingPower, uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, address[] testAddresses
        // Create any address, can be transferred
        // to team multisig via changeOwner(),
        // also remember to call setUpgradeMaster()
        owner = msg.sender; 
        name = _name; 
        symbol = _symbol; 
        totalSupply = _initialSupply; 
        decimals = _decimals; 
        // Create initially all balance on the team multisig
        balances[owner] = totalSupply; 
        maxAddresses=_maxAddresses;
        minMintingPower=_minMintingPower;
        maxMintingPower=_maxMintingPower;
        halvingCycle=_halvingCycle;
        initialBlockTimestamp=_initialBlockTimestamp;
        mintingDec=_mintingDec;
        latestContributerId=50;
        latestAllUpdate=0;
        bounty=_bounty;
        minBalanceToSell = _minBalanceToSell;
        
        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
        }
        //For Test Deployment Purposes
        uint i;
        for(i=1;i<=latestContributerId;i++)
        {
            contributors[i].initialContributionWei=79200000000;
            //contributors[i].balance=79200000000;
            if(i==1){ 
                contributors[i].mintingPower=10000000000000000000;
            }
            else{
                setInitialMintingPowerOf(i);
            }
            contributors[i].totalTransferredWei=0;
            contributors[i].adr=testAddresses[i];
            idOf[testAddresses[i]]=i;
        }
    }

    /**
        * When token is released to be transferable, enforce no new tokens can be created.
        */
    function releaseTokenTransfer() public onlyReleaseAgent {
        mintingFinished = true; 
        super.releaseTokenTransfer(); 
    }

    /**
        * Allow upgrade agent functionality kick in only if the crowdsale was success.
        */
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade(); 
    }

    /**
        * Owner can update token information here
        */
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name; 
        symbol = _symbol; 
        UpdatedTokenInformation(name, symbol); 
    }

    /**
        * Returns the current phase. 
        * Note: Phase starts with 1
        * @param _day Number of days since Minting Epoch
        */
    function getPhaseCount(uint _day) public constant returns (uint phase) {
        phase = (_day/halvingCycle) + 1; 
        return (phase); 
    }
    /**
        * Returns current day number since minting epoch.
        */
    function getDayCount() public constant returns (uint today) {
        today = ((block.timestamp - initialBlockTimestamp)/86400); 
        return today; 
    }
    /**
        * Calculates and Sets the minting power of a particular id.
        * Called before Minting Epoch by constructor
        * @param _id id of the address whose minting power is to be set.
        */
    function setInitialMintingPowerOf(uint256 _id) internal onlyContributor(_id) {
        contributors[_id].mintingPower = (maxMintingPower - ((_id-1) * (maxMintingPower - minMintingPower)/(maxAddresses-1))); 
    }
     /**
        * Returns minting power of a particular address.
        * @param _adr Address whose minting power is to be returned
        */
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        return contributors[idOf[_adr]].mintingPower/(2**(getPhaseCount(getDayCount()))); 
    }
    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount()))); 
    }

    /**
    * Returns the amount of DAY tokens minted by the address
    * @param _adr Address whose total minted is to be returned
    */
    function getTotalMinted(address _adr) public constant returns (int256) {
        uint id = idOf[_adr];
        return int(balances[_adr]) - ((int(contributors[id].initialContributionWei)+contributors[id].totalTransferredWei)); 
    }
    
    /**
        * Calculates and returns the balance based on the minting power, the day and the phase.
        * Can only be called internally
        * Can calculate balance based on last updated. *!MAXIMUM 3 DAYS!*. A difference of more than 3 days will lead to crashing of the contract.
        * @param _id id whose balnce is to be calculated
        */
    function availableBalanceOf(uint256 _id) internal returns (uint256) {
        uint256 balance = balances[contributors[_id].adr]; 
        for (uint i = contributors[_id].lastUpdatedOn; i < getDayCount(); i++) {
            balance = (balance * ((10 ** (mintingDec + 2) * (2 ** (getPhaseCount(i)-1))) + contributors[_id].mintingPower))/(2 ** (getPhaseCount(i)-1)); 
        }
        balance = balance/10 ** ((mintingDec + 2) * (getDayCount() - contributors[_id].lastUpdatedOn)); 
        return balance; 
    }

    /**
        * Updates the balance of the spcified id in its structure and also in the balances[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
        totalSupply = safeSub(totalSupply, balances[contributors[_id].adr]);
        balances[contributors[_id].adr] = availableBalanceOf(_id);
        totalSupply = safeAdd(totalSupply, balances[contributors[_id].adr]);
        contributors[_id].lastUpdatedOn = getDayCount();
        return true; 
    }

    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address after updating it.
        * Updates the balance only if it is a minitng address else, simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    function balanceOf(address _adr) public constant returns (uint256 balance) {
        uint id = idOf[_adr]; 
        if (id <= latestContributerId) {
            require(updateBalanceOf(id));
        }
        return balances[_adr];    
    }

    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified id after updating it.
        * Updates the balance only if it is a minitng address else, simply returns balance from balances[] mapping.
        * For public calls.
        * @param _id address whose balance is to be returned.
        */
    function balanceById(uint _id) public constant returns (uint256 balance) {
        if (_id <= latestContributerId) {
            address adr=contributors[_id].adr; 
            require(updateBalanceOf(_id)); 
        }
        return balances[adr]; 
    }

    /**
        * Updates balances of all minitng addresses.
        * Returns true/false based on success of update
        * To be called daily. 
        * Rewards caller with bounty as DAY tokens.
        * For public calls.
        * Logs the ids whose balance could not be updated
        */
    function updateAllBalances() public {
        uint today =(block.timestamp - initialBlockTimestamp)/1 days;
        require(today != latestAllUpdate); 
        for (uint i = 1; i <= latestContributerId; i++) {
            if (updateBalanceOf(i)) {}
            else {
                UpdateFailed(i); 
            }
        }
        latestAllUpdate = today; 
        mint(msg.sender, bounty);
        UpToDate(true); 
    }

    /**
        * Used to set bounty reward for caller of updateAllBalances
        * Can be called only by owner
        * @param _bounty bounty to be set.
        */
    function setBounty(uint256 _bounty) onlyOwner{
        bounty = _bounty;
    }

    /**
        * Returns totalSupply of DAY tokens.
        */
    function getTotalSupply() public constant returns (uint256){
        return totalSupply;
    }

    /**
        * Standard ERC20 function overidden.
        * USed to transfer day tokens from caller's address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    function transfer(address _to, uint _value) public returns (bool success) {
        if(teamIssuedTimestamp[msg.sender] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[msg.sender] >= 15780000);
        }
        require (!(balanceOf(msg.sender) < _value || _value==0)); 
        require (!(balanceOf(_to) + _value < balanceOf(_to))); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[msg.sender], _value); 
        Transfer(msg.sender, _to, _value); 
        if(idOf[msg.sender]<=latestContributerId)
        {
            balances[msg.sender] = safeSub(balances[msg.sender],_value);
            contributors[idOf[msg.sender]].totalTransferredWei = int(-(_value));
        }
        if(idOf[_to]<=latestContributerId)
        {
            contributors[idOf[_to]].totalTransferredWei = int(_value);
            balances[msg.sender] = safeAdd(balances[msg.sender],_value);
        }
        return true;
    }
    /**
        * Transfe 


        */
   function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
       if(teamIssuedTimestamp[_from] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[_from] >= 15780000);
        }
        uint _allowance = allowed[_from][msg.sender];
        require (!(balanceOf(_from) >= _value   // From a/c has balance
                    && _allowance >= _value    // Transfer approved
                    && _value > 0              // Non-zero transfer
                    && balanceOf(_to) + _value > balanceOf(_to)  // Overflow check
                )); 
        balances[_to] = safeAdd(balances[_to],_value);
        balances[_from] = safeSub(balances[_from],_value);
        allowed[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        if(idOf[_from]<=latestContributerId)
        {
            balances[_from] = safeSub(balances[_from],_value);
            contributors[idOf[_from]].totalTransferredWei = int(-(_value));
        }
        if(idOf[_to]<=latestContributerId)
        {
            contributors[idOf[_to]].totalTransferredWei = int(_value);
            balances[_to] = safeAdd(balances[_to],_value);
        }
    }

    /**
        * Transfer minting address from one user to another
        * Called by a minting address
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool){
        uint id = idOf[_from];
        contributors[id].adr = _to;
        idOf[_to] = id;
        idOf[_from] = 0;
        contributors[id].initialContributionWei = 0;
        //contributors[id].balance = balances[_to];
        contributors[id].lastUpdatedOn = getDayCount();
        contributors[id].totalTransferredWei = int(balances[_to]);
        contributors[id].expiryBlockNumber = 0;
        contributors[id].status = sellingStatus.NOTONSALE;
        MintingAdrTransferred(_from,_to);
        return true;
    }

    /** 
        * Add any contributor structure (For every kind of contributors: Team/Pre-ICO/ICO/Test)
        * Can only be added by Crowdsale.
        * @param _adr Address of the contributor to be added  
        * @param _initialContributionWei Initial Contribution of the contributor to be added
        * @param _initialBalance  Initial balance in wei of the contributor to be added
        */
    function addContributor(address _adr, uint _initialContributionWei, uint256 _initialBalance) onlyCrowdsale returns(uint){
        uint id = ++latestContributerId;
        contributors[id].adr = _adr;
        contributors[id].lastUpdatedOn = 0; //IS THIS NECESSARY
        setInitialMintingPowerOf(id);
        contributors[id].totalTransferredWei = 0; //IS THIS NECESSARY
        idOf[_adr] = id;
        contributors[id].initialContributionWei = _initialContributionWei;
        balances[_adr] = _initialBalance;
        ContributorAdded(_adr, id);
        contributors[id].status = sellingStatus.NOTONSALE;
        contributors[id].minPriceinDay = 0; //IS THIS NECESSARY
        contributors[id].expiryBlockNumber = 0; //IS THIS NECESSARY
        return id;
    }

    /** Function to be called once to add the deployed Crowdsale Contract
        */
    function addCrowdsaleAddress(address _adr) onlyOwner{
        crowdsaleAddress = _adr;
    }

    /** Function to be called by any user to give the latest contributor ID.
        */
    function getLatestContributorId() constant public returns(uint id){
        return latestContributerId;
    }
    // CHANGE IT ALL 

    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) onlyContributor(idOf[msg.sender]) returns (bool){
        if(teamIssuedTimestamp[msg.sender] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[msg.sender] >= teamLockPeriodInSec);
        }
        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceinDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        transfer(this, minBalanceToSell); //CONFIRM THIS CAREFully
        contributors[id].lastUpdatedOn = getDayCount();
        return true;
    }

    /** Function to be called by any user to get a list of all on sale addresses
        */
    function getOnSaleAddresses() constant public {
      for(uint i=1; i <= latestContributerId; i++)
      {
        if(contributors[i].expiryBlockNumber!=0 && block.number > contributors[i].expiryBlockNumber )
        {
            contributors[i].status = sellingStatus.EXPIRED;
        }
        if(contributors[i].status == sellingStatus.ONSALE)
        {
            onSale(i, contributors[i].adr, contributors[i].minPriceinDay, contributors[i].expiryBlockNumber);
        }
      }
    }

    /** Function to be called by any user to buy a onsale address by offering an amount
        * @param _offerId ID number of the address to be bought by the buyer
        * @param _offerInDay Offer given by the buyer in number of DAY tokens
        */
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public {
        if(contributors[_offerId].status != sellingStatus.NOTONSALE && block.number > contributors[_offerId].expiryBlockNumber )
        {
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        require(_offerInDay >= contributors[_offerId].minPriceinDay);
        //first get the offered DayToken in the token contract & then transfer the total sum (minBalanceToSend+_offerInDay) to the seller
        transfer(this, _offerInDay);
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) 
        {
            //mark the offer as sold & let seller pull the proceed to his own account.
            contributors[_offerId].status = sellingStatus.SOLD;
            contributors[_offerId].sellingPriceInDay = _offerInDay;
        }
        
    }

    function fetchSuccessfulSaleProceed() onlyContributor(idOf[msg.sender]) public  returns(bool) {
        //allow the seller to pull the net balance (minBalanceToSend+_offerInDay) to his own account back
        // throw if there is no offer from the sender or no successfull offer from sender
        require(contributors[idOf[msg.sender]].status == sellingStatus.SOLD);
        balances[this] -= minBalanceToSell + contributors[idOf[msg.sender]].sellingPriceInDay;
        balances[msg.sender] += minBalanceToSell + contributors[idOf[msg.sender]].sellingPriceInDay;
        contributors[idOf[msg.sender]].lastUpdatedOn = getDayCount();
        contributors[idOf[msg.sender]].status = sellingStatus.NOTONSALE;
        contributors[idOf[msg.sender]].minPriceinDay = 0;
        contributors[idOf[msg.sender]].sellingPriceInDay = 0;
        contributors[idOf[msg.sender]].expiryBlockNumber = 0;
        return true;
                
    }

    function refundFailedAuctionAmount() onlyContributor(idOf[msg.sender]) public returns(bool){
        uint id = idOf[msg.sender];
        if(block.number > contributors[id].expiryBlockNumber && contributors[id].status == sellingStatus.ONSALE)
        {
            contributors[id].status = sellingStatus.EXPIRED;
        }
        require(contributors[id].status == sellingStatus.EXPIRED);
        balances[this] -= minBalanceToSell;
        balances[msg.sender] += minBalanceToSell;
        contributors[idOf[msg.sender]].lastUpdatedOn = getDayCount();
        contributors[idOf[msg.sender]].status = sellingStatus.NOTONSALE;
        contributors[idOf[msg.sender]].minPriceinDay = 0;
        contributors[idOf[msg.sender]].sellingPriceInDay = 0;
        contributors[idOf[msg.sender]].expiryBlockNumber = 0;
        return true;
    }

    function addTeamAddress(address _adr, uint256 _initialBalance) public onlyOwner {
        uint id = addContributor(_adr, 0, _initialBalance);
        teamIssuedTimestamp[_adr] = block.timestamp;
        teamMemberId(_adr, id);
    }


    function postAllocate(address receiver, uint128 customerId) public onlyOwner {
        require(released == true);
        uint id = addContributor(receiver, 0, 0);
        PostInvested(receiver, 0, 0, customerId, id);
    }
}
 contract Crowdsale is Haltable, DayToken{

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  /* The token we are selling */
  DayToken public token;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* tokens will be transfered from this address */
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  uint public minimumFundingGoal;

  /* the UNIX timestamp start date of the crowdsale */
  uint public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint public weiRaised = 0;

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* How much wei we have returned back to the contract after a failed crowdfund. */
  uint public loadedRefund = 0;

  /* How much wei we have given back to investors.*/
  uint public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  /* Do we need to have unique contributor id for each customer */
  bool public requireCustomerId;

  /* Maximum number of addresses on sale for Pre-ICO */
  uint public maxPreAddresses;

  /* Min and Max contribution during pre-ICO and during ICO   */
  uint preMinWei;
  uint preMaxWei;
  uint minWei;
  uint maxWei;


  /**
    * Do we verify that contributor has been cleared on the server side (accredited investors only).
    * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted terms on sale (on the web).
    */
  bool public requiredSignedAddress;

  /* Server side address that signed allowed contributors (Ethereum addresses) that can participate the crowdsale */
  address public signerAddress;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public earlyParticipantWhitelist;

  /** This is for manul testing for the interaction from owner wallet. You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
  uint public ownerTestValue;

  /** State machine
   *
   * - Preparing: All contract initialization calls and variables have not been set yet
   * - Prefunding: We have not passed start time yet
   * - Funding: Active crowdsale
   * - Success: Minimum funding goal reached
   * - Failure: Minimum funding goal not reached before ending time
   * - Finalized: The finalized has been called and succesfully executed
   * - Refunding: Refunds are loaded on the contract for reclaim.
   */
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, uint contributorId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // The rules were changed what kind of investments we accept
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _preMinWei, uint _preMaxWei, uint _minWei, uint _maxWei, uint _maxPreAddresses) {

    owner = msg.sender;

    token = DayToken(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
   
    require(_start != 0);


    startsAt = _start;

    require(_end != 0);


    endsAt = _end;

    // Don't mess the dates
    require(startsAt < endsAt);

    //The token minting of the addresses shouldn't start before ICO ends.
    require(endsAt <= initialBlockTimestamp);

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;

    preMinWei = _preMinWei;
    preMaxWei = _preMaxWei;
    minWei = _minWei;
    maxWei = _maxWei;
    maxPreAddresses = _maxPreAddresses;
  }

  /**
   * Don't expect to just send in money and get tokens.
   */
  function() payable {
    throw;
  }

  /**
   * Make an investment.
   *
   * Crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   * @param customerId (optional) UUID v4 to track the successful payments on the server side
   *
   */
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

    // Determine if it's a good time to accept investment from this participant
    if(getState() == State.Funding) {
      // Retail participants can only come in when the crowdsale is running
      // pass
    } else {
      // Unwanted state
      throw;
    }
    uint weiAmount = msg.value;
    
    DayToken dayToken = DayToken(token);

    require(weiAmount >= minWei && weiAmount <= maxWei);
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, receiver, token.decimals());
    

    require(tokenAmount != 0);
    uint id = dayToken.addContributor(receiver, weiAmount, tokenAmount);

    if(investedAmountOf[receiver] == 0) {
        // A new investor
        investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    // Update totals
    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    // Check that we did not bust the cap
    require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));
    // if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
    //   throw;
    // }

    assignTokens(receiver, tokenAmount);

    // Pocket the money
    if(!multisigWallet.send(weiAmount)) throw;

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId, id);
  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * Investor count is not handled; it is assumed this goes for multiple investors
   * and the token distribution happens outside the smart contract flow.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param fullTokens tokens as full tokens - decimal places added internally
   * @param weiPrice Price of a single full token in wei
   *
   */
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**uint(token.decimals());
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    require(weiAmount >= preMinWei);

    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    DayToken dayToken = DayToken(token);
    uint id = dayToken.addContributor(receiver, weiAmount, tokenAmount);
    
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0, id);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  // function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
  //    bytes32 hash = sha256(addr);
  //    if (ecrecover(hash, v, r, s) != signerAddress) throw;
  //    require(customerId != 0);
  //    //if(customerId == 0) throw;  // UUIDv4 sanity check
  //    investInternal(addr, customerId);
  // }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    require(!requiredSignedAddress);
    //if(requiredSignedAddress) throw; // Crowdsale allows only server-side signed participants
    
    require(customerId != 0);
    //if(customerId == 0) throw;  // UUIDv4 sanity check
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    require(!requireCustomerId);
    //if(requireCustomerId) throw; // Crowdsale needs to track partipants for thank you email
    
    require(!requiredSignedAddress);
    //if(requiredSignedAddress) throw; // Crowdsale allows only server-side signed participants
    investInternal(addr, 0);
  }

  /**
   * Invest to tokens, recognize the payer and clear his address.
   *
   */
  
  // function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
  //   investWithSignedAddress(msg.sender, customerId, v, r, s);
  // }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    invest(msg.sender);
  }

  /**
   * Finalize a succcesful crowdsale.
   *
   * The owner can trigger a call the contract that provides post-crowdsale actions, like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

    // Already finalized
    require(!finalized);
    // if(finalized) {
    //   throw;
    // }

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   *
   * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
   */
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

    // Don't allow setting bad agent
    require(finalizeAgent.isFinalizeAgent());
    // if(!finalizeAgent.isFinalizeAgent()) {
    //   throw;
    // }
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

  /**
   * Set policy if all investors must be cleared on the server side first.
   *
   * This is e.g. for the accredited investor clearing.
   *
   */
  // function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
  //   requiredSignedAddress = value;
  //   signerAddress = _signerAddress;
  //   InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  // }

  /**
   * Allow addresses to do early participation.
   *
   * TODO: Fix spelling error in the name
   */
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

  /**
   * Allow crowdsale owner to close early or extend the crowdsale.
   *
   * This is useful e.g. for a manual soft cap implementation:
   * - after X amount is reached determine manual closing
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   *
   */
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw; // Don't change past
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   *
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

    // Don't allow setting bad agent
    require(pricingStrategy.isPricingStrategy());
    // if(!pricingStrategy.isPricingStrategy()) {
    //   throw;
    // }
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {

    // Change
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value != 0);
    //if(msg.value == 0) throw;
    loadedRefund = safeAdd(loadedRefund,msg.value);
  }

  /**
   * Investors can claim refund.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    //if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded,weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

  /**
   * @return true if the crowdsale has raised enough money to be a succes
   */
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

  /**
   * Check if the contract relationship looks good.
   */
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

  /**
   * Crowdfund state machine management.
   *
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   */
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt && latestContributerId <= maxPreAddresses) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

  /** Interface marker. */
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

  //
  // Modifiers
  //

  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    require(getState() == state);
    //if(getState() != state) throw;
    _;
  }


  //
  // Abstract functions
  //

  /**
   * Check if the current invested breaks our cap rules.
   *
   *
   * The child contract must define their own cap setting rules.
   * We allow a lot of flexibility through different capping strategies (ETH, token count)
   * Called from invest().
   *
   * @param weiAmount The amount of wei the investor tries to invest in the current transaction
   * @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
   * @param weiRaisedTotal What would be our total raised balance after this transaction
   * @param tokensSoldTotal What would be our total sold tokens count after this transaction
   *
   * @return true if taking this investment would break our cap rules
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);
  /**
   * Check if the current crowdsale is full and we can no longer sell any tokens.
   */
  function isCrowdsaleFull() public constant returns (bool);

  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  function assignTokens(address receiver, uint tokenAmount) private;
}
contract AddressCappedCrowdsale is Crowdsale {

    /* Maximum amount of wei this crowdsale can raise. */
    uint public weiCap;
    uint maxIcoAddresses;

    function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiCap, uint _preMinWei, uint _preMaxWei, uint _minWei, uint _maxWei, uint _maxPreAddresses, uint _maxIcoAddresses) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, _preMinWei, _preMaxWei,  _minWei,  _maxWei,  _maxPreAddresses) {
        weiCap = _weiCap;
        maxIcoAddresses = _maxIcoAddresses;
    }
        /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
        return weiRaisedTotal > weiCap;
    }

    function isCrowdsaleFull() public constant returns (bool) {
        return latestContributerId > maxIcoAddresses;
    }

    /**
    * Dynamically create tokens and assign them to the investor.
    */
    function assignTokens(address receiver, uint tokenAmount) private {
        MintableToken mintableToken = MintableToken(token);
        mintableToken.mint(receiver, tokenAmount);
    }
}
