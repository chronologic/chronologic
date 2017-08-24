pragma solidity ^0.4.13; 



contract SafeMathLib {
  function safeMul(uint a, uint b) constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) constant returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
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


////////////////// >>>>> Token Contracts <<<<< ///////////////////

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed _from, address indexed _to, uint _value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


    

/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
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
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}



/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. 
   * If false we are are in transfer lock up period.
   */
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. 
   * These are crowdsale contracts and possible the team multisig itself. 
   */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   */
  modifier canTransfer(address _sender) {

    if (!released) {
        require(transferAgents[_sender]);
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
   * Can be called only from the release agent that is the final ICO contract. 
   * It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
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


 

/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {
  uint public originalSupply;
  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}

/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. 
   * This can be the same as team multisig wallet, as what it is with its default value. 
   */
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
   * Somebody has upgraded some of their tokens.
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
    // Validate input value.
    require(value!=0);

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
    require(agent != 0x0);
    // Only a master can designate the next agent
    require(msg.sender == upgradeMaster);
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
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
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}




/**
 * A crowdsale token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and 
 * further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) 
 *   or uncapped (crowdsale contract can mint new tokens)
 */
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

    enum sellingStatus {NOTONSALE, EXPIRED, ONSALE}

    /** Basic structure for a contributor with a minting Address
     * adr address of the contributor
     * initialContributionDay initial contribution of the contributor in wei
     * lastUpdatedOn day count from Minting Epoch when the account balance was last updated
     * mintingPower Initial Minting power of the address
     * totalTransferredDay Total transferred day tokens: integer. Negative value indicates transfer from
     * expiryBlockNumber Variable to mark end of Minting address sale. Set by user
     * minPriceInDay minimum price of Minting address in Day tokens. Set by user
     * status Selling status Variable for transfer Minting address.
     * sellingPriceInDay Variable for transfer Minting address. Price at which the address is actually sold
     */ 
    struct Contributor {
        address adr;
        uint256 initialContributionDay;
        uint256 lastUpdatedOn; //Day from Minting Epoch
        uint256 mintingPower;
        int totalTransferredDay;
        uint expiryBlockNumber;
        uint256 minPriceinDay;
        sellingStatus status;
        uint256 sellingPriceInDay;
    }

    /* Mapping to store id of each minting address */
    mapping (address => uint) public idOf;
    /* Mapping from id of each minting address to their respective structures */
    mapping (uint256 => Contributor) public contributors;
    /* mapping to store unix timestamp of when the minting address is issued to each team member */
    mapping (address => uint256) public teamIssuedTimestamp;
    mapping (address => bool) public soldAddresses;
    mapping (address => uint256) public sellingPriceInDayOf;

    /* Stores number of days since minting epoch when all the balances are updated */
    uint256 public latestAllUpdate;

    /* Stores the id of the next Pre ICO contributor */
    uint256 public nextPreIcoContributorId;
    /* Maximum number of addresses for Pre ICO */
    uint256 public totalPreIcoAddresses;

    /* Stores the id of the next ICO contributor */
    uint256 public nextIcoContributorId;
    /* Maximum number of addresses for ICO */
    uint256 public totalIcoAddresses;

    /* Stores the id of the next Post ICO contributor (for auctionable addresses) */
    uint256 public nextPostIcoContributorId;
    /* Maximum number of addresses for Post ICO (Auction) */
    uint256 public totalPostIcoAddresses;

    /* Maximum number of address: total. (3333) */
    uint256 public maxAddresses;

    /* Min Minting power with 19 decimals: 0.5% : 5000000000000000000 */
    uint256 public minMintingPower;
    /* Max Minting power with 19 decimals: 1% : 10000000000000000000 */
    uint256 public maxMintingPower;
    /* Halving cycle in days (88) */
    uint256 public halvingCycle; 
    /* Unix timestamp when minting is to be started */
    uint256 public initialBlockTimestamp;
    /* number of decimals in minting power */
    uint256 public mintingDec; 
    /* Enable calling UpdateAllBalances() */
    bool public updateAllBalancesEnabled;
    /* Bounty to be given to the person calling UpdateAllBalances() */
    uint256 public bounty;
    /* Minimum Balance in Day tokens required to sell a minting address */
    uint256 public minBalanceToSell;
    /* Team address lock down period from issued time, in seconds */
    uint256 public teamLockPeriodInSec;  //Initialize and set function
    /* Duration in secs that we consider as a day. (For test deployment purposes, 
       if we want to decrease length of a day. default: 84600)*/
    uint256 public DayInSecs;
    address crowdsaleAddress;
    address BonusFinalizeAgentAddress;

    event UpdatedTokenInformation(string newName, string newSymbol); 
    event UpdateFailed(uint id); 
    event UpToDate (bool status);
    event MintingAdrTransferred(address from, address to);
    event ContributorAdded(address adr, uint id);
    event OnSale(uint id, address adr, uint minPriceinDay, uint expiryBlockNumber);
    event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, uint contributorId);
    
    modifier onlyCrowdsale(){
        require(msg.sender==crowdsaleAddress);
        _;
    }

    modifier onlyCrowdsaleOrOwner(){
        require(msg.sender==crowdsaleAddress || msg.sender==owner);
        _;
    }

    modifier onlyContributor(uint id){
        require(isValidContributorId(id));
        _;
    }

    modifier onlyBonusFinalizeAgent(){
        require(msg.sender == BonusFinalizeAgentAddress);
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
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply?
        */
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint _totalPreIcoAddresses, uint _totalIcoAddresses, 
        uint _totalPostIcoAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
        bool _updateAllBalancesEnabled, uint256 _minBalanceToSell, 
        uint256 _dayInSecs, uint256 _teamLockPeriodInSec) 
        UpgradeableToken(msg.sender) {
        
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
        maxAddresses = _maxAddresses;
        totalPreIcoAddresses = _totalPreIcoAddresses;
        totalIcoAddresses = _totalIcoAddresses;
        totalPostIcoAddresses = _totalPostIcoAddresses;
        // starts with 1
        nextPreIcoContributorId = 1;
        // calculate first contributor id for ICO phase
        nextIcoContributorId = totalPreIcoAddresses + 1;
        // calculate first contributor id to be auctioned post ICO
        nextPostIcoContributorId = maxAddresses - totalPostIcoAddresses + 1;
        minMintingPower = _minMintingPower;
        maxMintingPower = _maxMintingPower;
        halvingCycle = _halvingCycle;
        // setting future date far far away, year 2020, 
        // call setInitialBlockTimestamp to set proper timestamp
        initialBlockTimestamp = 1577836800;
        // use setMintingDec to change this
        mintingDec = 19;
        latestAllUpdate = 0;
        updateAllBalancesEnabled = _updateAllBalancesEnabled;
        minBalanceToSell = _minBalanceToSell;
        DayInSecs = _dayInSecs;
        teamLockPeriodInSec = _teamLockPeriodInSec;
        
        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
        }
    }

    /**
    * Used to set timestamp at which minting power of TimeMints is activated
    * Can be called only by owner
    * @param _initialBlockTimestamp timestamp to be set.
    */
    function setInitialBlockTimestamp(uint _initialBlockTimestamp) onlyOwner {
        initialBlockTimestamp = _initialBlockTimestamp;
    }

    /**
    * check if mintining power is activated and Day token and Timemint transfer is enabled
    */
    function isDayTokenActivated() returns (bool isActivated) {
        return (block.timestamp >= initialBlockTimestamp);
    }


    /**
    * to check if an id is a valid contributor
    * @param _id contributor id to check.
    */
    function isValidContributorId(uint _id) returns (bool isValidContributor) {
        return (_id > 0 && _id <= maxAddresses && contributors[_id].adr != 0 
            && idOf[contributors[_id].adr] == _id); // cross checking
    }

    /**
    * to check if an address is a valid contributor
    * @param _address  contributor address to check.
    */
    function isValidContributorAddress(address _address) returns (bool isValidContributor) {
        return isValidContributorId(idOf[_address]);
    }


    /**
    * In case of Team address check if lock-in period is over (returns true for all non team addresses)
    * @param _address team address to check lock in period for.
    */
    function isTeamLockInPeriodOverIfTeamAddress(address _address) returns (bool isLockInPeriodOver) {
        isLockInPeriodOver = true;
        if (teamIssuedTimestamp[_address] != 0) {
                if (block.timestamp - teamIssuedTimestamp[_address] < teamLockPeriodInSec)
                    isLockInPeriodOver = false;
        }

        return isLockInPeriodOver;
    }

    /**
    * Used to set mintingDec
    * Can be called only by owner
    * @param _mintingDec bounty to be set.
    */
    function setMintingDec(uint256 _mintingDec) onlyOwner {
        mintingDec = _mintingDec;
    }

    /* increment  nextPreIcoContributorId */
    function incrementPreIcoContributorId() {
        nextPreIcoContributorId++;
    }

    /* increment  nextIcoContributorId */
    function incrementIcoContributorId() {
        nextIcoContributorId++;
    }

    /* increment  nextPostIcoContributorId */
    function incrementPostIcoContributorId() {
        nextPostIcoContributorId++;
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
        * Returns current day number since minting epoch 
        * or zero if initialBlockTimestamp is in future or its DayZero.
        */
    function getDayCount() public constant returns (uint daySinceMintingEpoch) {
        daySinceMintingEpoch = 0;
        if (isDayTokenActivated())
            daySinceMintingEpoch = (block.timestamp - initialBlockTimestamp)/DayInSecs; 

        return daySinceMintingEpoch; 
    }
    /**
        * Calculates and Sets the minting power of a particular id.
        * Called before Minting Epoch by constructor
        * @param _id id of the address whose minting power is to be set.
        */
    function setInitialMintingPowerOf(uint256 _id) internal onlyContributor(_id) {
        contributors[_id].mintingPower = 
            (maxMintingPower - ((_id-1) * (maxMintingPower - minMintingPower)/(maxAddresses-1))); 
    }

    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }

    /**
        * Returns minting power of a particular address.
        * @param _adr Address whose minting power is to be returned
        */
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        return getMintingPowerById(idOf[_adr]);
    }


     /**
        * Returns the amount of DAY tokens minted by the address
        * @param _adr Address whose total minted is to be returned
        */
    function getTotalMinted(address _adr) public constant returns (uint256) {
        uint id = idOf[_adr];
        return uint(int(balances[_adr]) - ((int(contributors[id].initialContributionDay)+contributors[id].totalTransferredDay))); 
    }

    /**
        * Calculates and returns the balance based on the minting power, day and phase.
        * Can only be called internally
        * Can calculate balance based on last updated.
        * @param _id id whose balnce is to be calculated
        */
    function availableBalanceOf(uint256 _id) internal returns (uint256) {
        uint256 balance = balances[contributors[_id].adr]; 
        for (uint i = contributors[_id].lastUpdatedOn + 1; i <= getDayCount(); i++) {
            balance = balance + ( contributors[_id].mintingPower * balance ) / ( 10**(mintingDec + 2) * 2**(getPhaseCount(i)-1) );
        } 
        return balance; 
    }

    /**
        * Updates the balance of the specified id in its structure and also in the balances[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
        // check if its contributor
        if (isValidContributorId(_id)) {
            // proceed only if not already updated today
            if (contributors[_id].lastUpdatedOn != getDayCount()) {
                totalSupply = safeSub(totalSupply, balances[contributors[_id].adr]);
                balances[contributors[_id].adr] = availableBalanceOf(_id);
                totalSupply = safeAdd(totalSupply, balances[contributors[_id].adr]);
                contributors[_id].lastUpdatedOn = getDayCount();
                return true; 
            }
        }
        return false;
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    function balanceOf(address _adr) public constant returns (uint256 balance) {
        uint id = idOf[_adr]; 
        if (isDayTokenActivated()) {
            if (isValidContributorId(id)) {
                return ( availableBalanceOf(id) );
            }
        }
        return balances[_adr];    
    }

    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified id.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _id address whose balance is to be returned.
        */
    function balanceById(uint _id) public constant returns (uint256 balance) {
        address adr = contributors[_id].adr; 
        if (isDayTokenActivated()) {
            if (isValidContributorId(_id)) {
                return ( availableBalanceOf(_id) );
            }
        }
        return balances[adr]; 
    }

    /**
        * Updates balances of all minting addresses.
        * Returns true/false based on success of update
        * To be called daily. 
        * Rewards caller with bounty as DAY tokens.
        * For public calls.
        * Logs the ids whose balance could not be updated
        */
    function updateAllBalances() public {
        require(updateAllBalancesEnabled);
        require(isDayTokenActivated());
        uint today = getDayCount();
        require(today != latestAllUpdate); 

        for (uint i = 1; i <= maxAddresses; i++) {
            if (!updateBalanceOf(i))
                UpdateFailed(i); 
        }

        latestAllUpdate = today;
        // award bounty
        balances[msg.sender] = safeAdd(balances[msg.sender],bounty);
        balances[this] = safeSub(balances[this], bounty);
        UpToDate(true); 
    }

    /**
        * Used to set bounty reward for caller of updateAllBalances
        * Can be called only by owner
        * @param _bounty bounty to be set.
        */
    function setBounty(uint256 _bounty) onlyOwner {
        bounty = _bounty;
    }

    /**
        * Returns totalSupply of DAY tokens.
        */
    function getTotalSupply() public constant returns (uint) {
        return totalSupply;
    }

    /**
        * Standard ERC20 function overidden.
        * Used to transfer day tokens from caller's address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());
        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        // Check sender account has enough balance and transfer amount is non zero
        require ( balanceOf(msg.sender) >= _value && _value != 0 ); 
         
        uint msgSenderId = idOf[msg.sender];
        if (isValidContributorId(msgSenderId))
        {
            updateBalanceOf(msgSenderId);
            contributors[msgSenderId].totalTransferredDay = contributors[msgSenderId].totalTransferredDay + int(-(_value));
        }

        uint toId = idOf[_to];
        if (isValidContributorId(toId))
        {
            updateBalanceOf(toId);
            contributors[toId].totalTransferredDay = contributors[toId].totalTransferredDay + int(_value);
        }

        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[_to], _value); 
        Transfer(msg.sender, _to, _value);

        return true;
    }
    /**
        * Standard ERC20 Standard Token function overridden. Added Team address vesting period lock. 
        */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());

        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(_from));

        uint _allowance = allowed[_from][msg.sender];

        // Check from account has enough balance, transfer amount is non zero 
        // and _value is allowed to be transferred
        require ( balanceOf(_from) >= _value && _value != 0  &&  _value <= _allowance); 

        uint fromId = idOf[_from];
        if (isValidContributorId(fromId))
        {
            updateBalanceOf(fromId);
            contributors[fromId].totalTransferredDay = contributors[fromId].totalTransferredDay + int(-(_value));
        }

        uint toId = idOf[_to];
        if (isValidContributorId(toId))
        {
            updateBalanceOf(toId);
            contributors[toId].totalTransferredDay = contributors[toId].totalTransferredDay + int(_value);
        }

        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    
        Transfer(_from, _to, _value);
        
        return true;
    }

    /**
        * Transfer minting address from one user to another
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool) {
        require(isDayTokenActivated());

        // _to should be non minting address
        require(idOf[_to] == 0);
        
        uint id = idOf[_from];
        // update balance of from address before transferring minting power
        updateBalanceOf(id);

        contributors[id].adr = _to;
        idOf[_to] = id;
        idOf[_from] = 0;
        contributors[id].initialContributionDay = 0;
        // needed as id is assigned to new address
        contributors[id].lastUpdatedOn = getDayCount();
        contributors[id].totalTransferredDay = int(balances[_to]);
        contributors[id].expiryBlockNumber = 0;
        contributors[id].status = sellingStatus.NOTONSALE;
        MintingAdrTransferred(_from, _to);
        return true;
    }

    /** 
        * Add any contributor structure (For every kind of contributors: Team/Pre-ICO/ICO/Test)
        * @param _adr Address of the contributor to be added  
        * @param _initialContributionDay Initial Contribution of the contributor to be added
        */
  function addContributor(uint contributorId, address _adr, uint _initialContributionDay) onlyCrowdsaleOrOwner {
        require(contributorId <= maxAddresses);
        require(idOf[_adr] == 0);
        contributors[contributorId].adr = _adr;
        setInitialMintingPowerOf(contributorId);
        idOf[_adr] = contributorId;
        contributors[contributorId].initialContributionDay = _initialContributionDay;
        ContributorAdded(_adr, contributorId);
        contributors[contributorId].status = sellingStatus.NOTONSALE;
    }

    /** Function to be called once to add the deployed Crowdsale Contract
        */
    function addCrowdsaleAddress(address _adr) onlyOwner {
        crowdsaleAddress = _adr;
    }

    /** Function to be called once to add the deployed BonusFinalizeAgent Contract
        */
    function setBonusFinalizeAgentAddress(address adr) onlyOwner {
        BonusFinalizeAgentAddress = adr;
    }

    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) public returns (bool) {
        require(isDayTokenActivated());

        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);

        // update balance of sender address before checking for minimum required balance
        updateBalanceOf(id);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceinDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        balances[msg.sender] = safeSub(balances[msg.sender], minBalanceToSell);
        balances[this] = safeAdd(balances[this], minBalanceToSell);
        return true;
    }

    /** Function to be called by any user to get a list of all on sale addresses
        */
    function getOnSaleAddresses() constant public {
        for(uint i=1; i <= maxAddresses; i++)
        {
            if (contributors[i].adr != 0) {
                if(contributors[i].expiryBlockNumber!=0 && block.number > contributors[i].expiryBlockNumber ){
                    contributors[i].status = sellingStatus.EXPIRED;
                }
                if(contributors[i].status == sellingStatus.ONSALE){
                    OnSale(i, contributors[i].adr, contributors[i].minPriceinDay, contributors[i].expiryBlockNumber);
                }
            }
        }
    }

    /** Function to be called by any user to buy a onsale address by offering an amount
        * @param _offerId ID number of the address to be bought by the buyer
        * @param _offerInDay Offer given by the buyer in number of DAY tokens
        */
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public returns(bool){
        if(contributors[_offerId].status != sellingStatus.NOTONSALE 
            && block.number > contributors[_offerId].expiryBlockNumber)
        {
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        address soldAddress = contributors[_offerId].adr;
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        require(_offerInDay >= contributors[_offerId].minPriceinDay);
        // first get the offered DayToken in the token contract & 
        // then transfer the total sum (minBalanceToSend+_offerInDay) to the seller
        balances[msg.sender] = safeSub(balances[msg.sender], _offerInDay);
        balances[this] = safeAdd(balances[this], _offerInDay);
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) {
            //mark the offer as sold & let seller pull the proceed to their own account.
            sellingPriceInDayOf[soldAddress] = _offerInDay;
            soldAddresses[soldAddress] = true; 
        }
        return true;
    }

    /** Function to allow seller to get back their deposited amount of day tokens(minBalanceToSell) and 
        * offer made by buyer after successful sale.
        * Throws if sale is not successful
        * Resets all sale-related variables to 0 and status to NOTONSALE
        */
    function fetchSuccessfulSaleProceed() public  returns(bool) {
        require(soldAddresses[msg.sender] == true);
        uint saleProceed = safeAdd(minBalanceToSell, sellingPriceInDayOf[msg.sender]);
        balances[this] = safeSub(balances[this], saleProceed);
        balances[msg.sender] = safeAdd(balances[msg.sender], saleProceed);
        soldAddresses[msg.sender] = false;
        return true;
                
    }

    /** Function that lets a seller get their deposited day tokens (minBalanceToSell) back, if no buyer turns up.
        * Allowed only after expiryBlockNumber
        * Throws if any other state other than EXPIRED
        */
    function refundFailedAuctionAmount() onlyContributor(idOf[msg.sender]) public returns(bool){
        uint id = idOf[msg.sender];
        if(block.number > contributors[id].expiryBlockNumber && contributors[id].status == sellingStatus.ONSALE)
        {
            contributors[id].status = sellingStatus.EXPIRED;
        }
        require(contributors[id].status == sellingStatus.EXPIRED);
        balances[this] = safeSub(balances[this], minBalanceToSell);
        // update balance of seller address before refunding
        updateBalanceOf(id);
        balances[msg.sender] = safeAdd(balances[msg.sender],minBalanceToSell);
        contributors[id].status = sellingStatus.NOTONSALE;
        contributors[id].minPriceinDay = 0;
        contributors[id].expiryBlockNumber = 0;
        return true;
    }

    /** Function to add a team address as a contributor and store it's time issued to calculate vesting period
        * Called by BonusFinalizeAgent
        */
    function addTeamAddress(address _adr, uint id) onlyBonusFinalizeAgent {
        addContributor(id, _adr, 0);
        teamIssuedTimestamp[_adr] = block.timestamp;
    }

    /** Function to add reserved aution addresses post-ICO. Only by owner
        * @param receiver Address of the minting to be added
        * @param customerId Server side id of the customer
        */
    function postAllocate(address receiver, uint128 customerId) public onlyOwner {
        require(released == true);
        require(nextPostIcoContributorId <= maxAddresses);
        addContributor(nextPostIcoContributorId, receiver, 0);
        PostInvested(receiver, 0, 0, customerId, nextPostIcoContributorId);
        //increment counter
        nextPostIcoContributorId++;
    }

    /** Function to add Remaining ICO addresses post-ICO. Only by owner
        * @param receiver Address of the minting to be added
        * @param customerId Server side id of the customer
        */
    function postAllocateRemainingIcoAddresses(address receiver, uint128 customerId) public onlyOwner {
        require(released == true);
        require(nextIcoContributorId <= totalPreIcoAddresses + totalIcoAddresses);
        addContributor(nextIcoContributorId, receiver, 0);
        PostInvested(receiver, 0, 0, customerId, nextIcoContributorId);
        //increment counter
        nextIcoContributorId++;
    }


    /** Function to add Remaining Pre ICO addresses post-ICO. Only by owner
        * @param receiver Address of the minting to be added
        * @param customerId Server side id of the customer
        */
    function postAllocateRemainingPreIcoAddresses(address receiver, uint128 customerId) public onlyOwner {
        require(released == true);
        require(nextPreIcoContributorId <= totalPreIcoAddresses);
        addContributor(nextPreIcoContributorId, receiver, 0);
        PostInvested(receiver, 0, 0, customerId, nextPreIcoContributorId);
        //increment counter
        nextPreIcoContributorId++;
    }
    
}




////////////////// >>>>> Pricing Contracts <<<<< ///////////////////



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
    require(crowdsale != 0); 
    return true;
  }

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   *
   * @param value - What is the value of the transaction send in as wei
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint decimals) public constant returns (uint tokenAmount);
}



/**
 * Fixed crowdsale pricing - everybody gets the same price.
 */
contract FlatPricing is PricingStrategy, SafeMathLib {

  /* How many weis one token costs */
  uint public oneTokenInWei;

  function FlatPricing(uint _oneTokenInWei) {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;
  }

  /**
   * Calculate the current price for buy in amount.
   *
   * 
   */
  function calculatePrice(uint value, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return safeMul(value, multiplier) / oneTokenInWei;
  }

}


////////////////// >>>>> Wallet Contract <<<<< ///////////////////


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            throw;
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}


////////////////// >>>>> Crowdsale Contracts <<<<< ///////////////////



/**
 * Finalize agent defines what happens at the end of succeseful crowdsale.
 *
 * - Allocate tokens for founders, bounties and community
 * - Make tokens transferable
 * - etc.
 */
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
contract Crowdsale is Haltable, SafeMathLib {

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

  /* Wei Funding raised during ICO period */
  uint public weiRaisedIco = 0;

  /* Min and Max contribution during pre-ICO and during ICO   */
  uint preMinWei;
  uint preMaxWei;
  uint minWei;
  uint maxWei;
  
  /**
    * Do we verify that contributor has been cleared on the server side (accredited investors only).
    * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted 
    * terms on sale (on the web).
    */
  bool public requiredSignedAddress;

  /* Server side address that signed allowed contributors (Ethereum addresses) that can participate in 
  the crowdsale */
  address public signerAddress;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** This is for manual testing for the interaction from owner wallet. 
    * You can set it to any value and inspect this in blockchain explorer to 
    * see that crowdsale interaction works. 
    */
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
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, 
    uint contributorId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // The rules were changed what kind of investments we accept
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);


  // Crowdsale end time has been changed
  event EndsAtChanged(uint endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
    uint _start, uint _end, uint _minimumFundingGoal, uint _preMinWei, uint _preMaxWei, 
    uint _minWei, uint _maxWei) {

    owner = msg.sender;

    token = DayToken(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    require(multisigWallet != 0);
    
    require(_start != 0);
    startsAt = _start;

    require(_end != 0);
    endsAt = _end;

    // Don't mess the dates
    require(startsAt < endsAt);

    //The token minting of the addresses shouldn't start before ICO ends.
    require(endsAt <= token.initialBlockTimestamp());

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;

    preMinWei = _preMinWei;
    preMaxWei = _preMaxWei;
    minWei = _minWei;
    maxWei = _maxWei;
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
    // Retail participants can only come in when the crowdsale is running
    require(getState() == State.Funding);
    uint weiAmount = msg.value;
    
    require(weiAmount >= minWei && weiAmount <= maxWei);
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, token.decimals());
    require(tokenAmount != 0);
    uint contributorId = 0;

    // if investor not already a contributor and minting addresses are still there, add as contributor
    if (!token.isValidContributorAddress(receiver) && 
        token.nextIcoContributorId() <= token.totalPreIcoAddresses() + token.totalIcoAddresses()) {
      contributorId = token.nextIcoContributorId();
      token.addContributor(contributorId, receiver, tokenAmount);
      // increment counter
      token.incrementIcoContributorId();
    }

    if (investedAmountOf[receiver] == 0) {
        // A new investor
        investorCount++;
    }

    // Update investor
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    // Update totals
    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);
    weiRaisedIco = safeAdd(weiRaisedIco, weiAmount);

    // Check that we did not bust the cap
    require(!isBreakingCap(weiRaisedIco));

    assignTokens(receiver, tokenAmount);

    // Pocket the money
    require(multisigWallet.send(weiAmount));

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId, contributorId);

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
  function preallocate(address receiver, uint fullTokens, uint weiPrice) onlyOwner public {
    require(getState() == State.PreFunding || getState() == State.Funding);
    require(!token.isValidContributorAddress(receiver) && 
      token.nextPreIcoContributorId() <= token.totalPreIcoAddresses());

    uint tokenAmount = fullTokens * 10**uint(token.decimals());
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    require(weiAmount >= preMinWei);
    require(weiAmount <= preMaxWei);

    weiRaised = safeAdd(weiRaised, weiAmount);
    tokensSold = safeAdd(tokensSold, tokenAmount);

    token.addContributor(token.nextPreIcoContributorId(), receiver, tokenAmount);

    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0, token.nextPreIcoContributorId());

    //increment counter
    token.incrementPreIcoContributorId();
  }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    require(!requiredSignedAddress);
    
    require(customerId != 0);
    
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  function invest(address addr) public payable {
    require(!requireCustomerId);
    
    require(!requiredSignedAddress);
    
    investInternal(addr, 0);
  }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate in the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function buy() public payable {
    invest(msg.sender);
  }

  /**
   * The default entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  function () public payable {
    invest(msg.sender);
  }

  /**
   * Finalize a succcesful crowdsale.
   * The owner can trigger a call to the contract that provides post-crowdsale actions, 
   * like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

    // Already finalized
    require(!finalized);

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    if (address(finalizeAgent) != 0) {
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
   * Allow crowdsale owner to close early or extend the crowdsale.
   *
   * This is useful e.g. for a manual soft cap implementation:
   * - after X amount is reached determine manual closing
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   */
  function setEndsAt(uint time) onlyOwner {
    require(now <= time);
    endsAt = time;
    EndsAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

    // Don't allow setting bad agent
    require(pricingStrategy.isPricingStrategy());
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {
    // Change Multisig wallet address
    require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);
    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal 
   * was not reached.
   */
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value != 0);
    loadedRefund = safeAdd(loadedRefund, msg.value);
  }

  /**
   * Investors can claim refund.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded,weiValue);
    Refund(msg.sender, weiValue);
    require(msg.sender.send(weiValue));
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
    if (finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt) return State.Funding;
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
    _;
  }


  //
  // Abstract functions
  //

  /**
   * Check if the current invested breaks our cap rules.
   *
   * The child contract must define their own cap setting rules.
   * We allow a lot of flexibility through different capping strategies (ETH, token count)
   * Called from invest().
   * @return true if taking this investment would break our cap rules
   */
  function isBreakingCap(uint weiRaisedTotal) constant returns (bool limitBroken);


  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  function assignTokens(address receiver, uint tokenAmount) private;
}



/**
 * ICO crowdsale contract that is capped by Number of addresses (investors).
 *
 * - Tokens are dynamically created during the crowdsale
 *
 */
contract AddressCappedCrowdsale is Crowdsale {

    /* Maximum amount of wei this crowdsale can raise. */
    uint public weiIcoCap;

    /** Constructor to initialize all variables, including Crowdsale variables
    * @param _token Address of the deployed DayToken contract
    * @param _pricingStrategy Address of the deployed pricing statergy contract (FlatPricing)
    * @param _multisigWallet Address of the deployed Multisig wallet
    * @param _start unix timestamp for start of ICO
    * @param _end unix timestamp for end of ICO
    * @param _minimumFundingGoal Minimum amount to be raised in Wei
    * @param _weiIcoCap Hard cap for amount to be raised during ICO in wei
    * @param _preMinWei Minimum amount, in wei for a contribution during pre-ICO stage
    * @param _preMaxWei Maximum amount, in Wei for a contribution during pre-ICO stage
    * @param _minWei Minimum amount, in Wei for a contribution during ICO stage
    * @param _maxWei Maximum amount, in Wei for a contribution during ICO stage
    */
    function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
        address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, 
        uint _preMinWei, uint _preMaxWei, uint _minWei,  uint _maxWei) 
        
        Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, 
        _preMinWei, _preMaxWei, _minWei, _maxWei) {  
        weiIcoCap = _weiIcoCap;
        token = DayToken(_token);
    }

    /**
    * Called from invest() to confirm if the curret investment does not break our cap rule.
    */
    function isBreakingCap(uint weiRaisedTotal) constant returns (bool limitBroken) {
        return weiRaisedTotal > weiIcoCap;
    }

    /**
    * Dynamically create tokens and assign them to the investor.
    */
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }
}


////////////////// >>>>> FinalizeAgent Contracts <<<<< ///////////////////


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
    return (totalAddresses == token.maxAddresses()) && (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
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

    // assign addresses with tokens
    for (uint i = 0; i < totalTeamAddresses; i++) {
      token.mint(teamAddresses[i], allocatedBonus);
      token.addTeamAddress(teamAddresses[i], nextTeamContributorId);
      TeamMemberId(teamAddresses[i], nextTeamContributorId);
      nextTeamContributorId++;
    }

    //Add Test Addresses
    for (uint j = 0; j < totalTestAddresses; j++) {
      token.mint(testAddresses[j],testAddressTokens);
      token.addTeamAddress(testAddresses[j],  nextTestContributorId);
      TestAddressAdded(testAddresses[j], nextTestContributorId, testAddressTokens);
      nextTestContributorId++;
    }
    
    // Make token transferable
    // realease them in the wild
    // Hell yeah!!! we did it.
    token.releaseTokenTransfer();
  }
}


  