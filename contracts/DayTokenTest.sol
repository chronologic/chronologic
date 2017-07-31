pragma solidity ^0.4.11; 

import "./StandardToken.sol"; 
import "./UpgradeableToken.sol"; 
import "./ReleasableToken.sol"; 
import "./MintableToken.sol";
import "./SafeMathLib.sol"; 

//TODO: Set daytoken as minting agent and canmint. Set latest contributer to 0
//todo:
// Mint all bounty
// Slabs
// Transfer minitng address me total Wei transferred
// Hard code number of address in each stage

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
contract DayTokenTest is  ReleasableToken, MintableToken, UpgradeableToken {

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
address BonusFinalizeAgentAddress;
uint256 minBalanceToSell;
uint256 teamLockPeriodInSec;  //Initialize and set function
uint public teamTestAdrEndId;

event UpdatedTokenInformation(string newName, string newSymbol); 
event UpdateFailed(uint id); 
event UpToDate (bool status);
event MintingAdrTransferred(address from, address to);
event ContributorAdded(address adr, uint id);
event onSale(uint id, address adr, uint minPriceinDay, uint expiryBlockNumber);
event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, uint contributorId);

modifier onlyCrowdsale(){
    require(msg.sender==crowdsaleAddress);
    _;
}

modifier onlyContributor(uint id){
    require(id <= latestContributerId && id != 0);
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
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
        */
    function DayTokenTest(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable, uint _maxAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, uint256 _minBalanceToSell) UpgradeableToken(msg.sender) {
        
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
        minMintingPower = _minMintingPower;
        maxMintingPower = _maxMintingPower;
        halvingCycle = _halvingCycle;
        initialBlockTimestamp = _initialBlockTimestamp;
        mintingDec = _mintingDec;
        latestContributerId = 0;
        latestAllUpdate = 0;
        bounty = _bounty;
        minBalanceToSell = _minBalanceToSell;
        
        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
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
    function getDayCount() public constant returns (uint daySinceMintingEpoch) {
        daySinceMintingEpoch = ((block.timestamp - initialBlockTimestamp)/86400); 
        return daySinceMintingEpoch; 
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
    function getMintingPowerByAddress(address _adr,uint256 _day) public constant returns (uint256 mintingPower) {
        return contributors[idOf[_adr]].mintingPower/(2**(getPhaseCount(_day)-1)); 
    }

    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMintingPowerById(uint _id, uint256 _day) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(_day)-1)); 
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
    function availableBalanceOf(uint256 _id, uint day) constant returns (uint256) {
        uint256 balance = balances[contributors[_id].adr]; 
        for (uint i = contributors[_id].lastUpdatedOn; i < day; i++) {
            balance = (balance * ((10 ** (mintingDec + 2) * (2 ** (getPhaseCount(i)-1))) + contributors[_id].mintingPower))/(2 ** (getPhaseCount(i)-1)); 
        }
        balance = balance/10 ** ((mintingDec + 2) * (day - contributors[_id].lastUpdatedOn)); 
        return balance; 
    }

    /**
        * Updates the balance of the spcified id in its structure and also in the balances[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    function updateBalanceOf(uint256 _id,uint day) internal returns (bool success) {
        totalSupply = safeSub(totalSupply, balances[contributors[_id].adr]);
        balances[contributors[_id].adr] = availableBalanceOf(_id, day);
        totalSupply = safeAdd(totalSupply, balances[contributors[_id].adr]);
        contributors[_id].lastUpdatedOn = day;
        return true; 
    }

    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address after updating it.
        * Updates the balance only if it is a minitng address else, simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    function balanceOf(address _adr, int day) public constant returns (uint256 balance) {
        uint id = idOf[_adr]; 
        if(day <0 )
        {
            return balances[_adr];
        }
        if (id <= latestContributerId) {
            require(updateBalanceOf(id, uint(day)));
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
    function balanceById(uint _id, int day) public constant returns (uint256 balance) {
       
        if(day <0 )
        {
            return balances[contributors[_id].adr];
        }
        if (_id <= latestContributerId) {
            require(updateBalanceOf(_id, uint(day)));
        }
        return balances[contributors[_id].adr];
    }

    /**
        * Updates balances of all minitng addresses.
        * Returns true/false based on success of update
        * To be called daily. 
        * Rewards caller with bounty as DAY tokens.
        * For public calls.
        * Logs the ids whose balance could not be updated
        */
    function updateAllBalances(uint day) public {
        //require(block.timestamp >= initialBlockTimestamp);
        uint today = day;
        require(today != latestAllUpdate); 
        for (uint i = 1; i <= latestContributerId; i++) {
            if (updateBalanceOf(i, day)) {}
            else {
                UpdateFailed(i); 
            }
        }
        latestAllUpdate = today; 
        //mint(msg.sender, bounty); //TO BE CHANGED
        balances[msg.sender] += bounty;
        balances[this] -= bounty;
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
        require (!(balanceOf(msg.sender) < _value || _value == 0)); 
        require (!(balanceOf(_to) + _value < balanceOf(_to))); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[msg.sender], _value); 
        Transfer(msg.sender, _to, _value); 
        if(idOf[msg.sender] <= latestContributerId)
        {
            balances[msg.sender] = safeSub(balances[msg.sender],_value);
            contributors[idOf[msg.sender]].totalTransferredWei = int(-(_value));
            contributors[idOf[msg.sender]].lastUpdatedOn = getDayCount();
        }
        if(idOf[_to]<=latestContributerId)
        {
            contributors[idOf[_to]].totalTransferredWei = int(_value);
            balances[msg.sender] = safeAdd(balances[msg.sender],_value);
            contributors[idOf[_to]].lastUpdatedOn = getDayCount();
        }
        return true;
    }
    /**
        * Standard ERC20 Standard Tken function over-written. Added Team address vesting period lock. 
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
        if(idOf[_from] <= latestContributerId)
        {
            balances[_from] = safeSub(balances[_from],_value);
            contributors[idOf[_from]].totalTransferredWei = int(-(_value));
            contributors[idOf[_from]].lastUpdatedOn = getDayCount();
        }
        if(idOf[_to]<=latestContributerId)
        {
            contributors[idOf[_to]].totalTransferredWei = int(_value);
            balances[_to] = safeAdd(balances[_to],_value);
            contributors[idOf[_to]].lastUpdatedOn = getDayCount();
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
    function addContributor(address _adr, uint _initialContributionWei, uint _initialBalance)  returns(uint){
        uint id = ++latestContributerId;
        require(idOf[_adr] == 0);
        contributors[id].adr = _adr;
        contributors[id].lastUpdatedOn = 0; //IS THIS NECESSARY
        setInitialMintingPowerOf(id);
        contributors[id].totalTransferredWei = 0; //IS THIS NECESSARY
        idOf[_adr] = id;
        contributors[id].initialContributionWei = _initialContributionWei;
        //balances[_adr] = _initialBalance;
        balances[_adr] = _initialBalance;
        totalSupply += _initialBalance;
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

    /** Function to be called once to add the deployed BonusFinalizeAgent Contract
        */
    function setBonusFinalizeAgentAddress(address adr) onlyOwner {
        BonusFinalizeAgentAddress = adr;
    }
    /** Function to be called by any user to give the latest contributor ID.
        */
    function getLatestContributorId() constant public returns(uint id){
        return latestContributerId;
    }
   
    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) constant returns (bool){
        // if(teamIssuedTimestamp[msg.sender] != 0)
        // {
        //     require(block.timestamp - teamIssuedTimestamp[msg.sender] >= teamLockPeriodInSec);
        // }
        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceinDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        //transfer(this, minBalanceToSell);
        balances[this] += minBalanceToSell;
        balances[msg.sender] -= minBalanceToSell;
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
    
    /** Funtion to allow seller to get back his deposited amount of day tokens(minBalanceToSell) and offer made by buyer after successful sale.
        * Throws if sale is not successful
        * Resets all slae-related variables to 0 and status to NOTONSALE
        */
    function fetchSuccessfulSaleProceed() onlyContributor(idOf[msg.sender]) public  returns(bool) {
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

    /** Function that lets a seller get his deposited day tokens (minBalanceToSell) back, if no buyer turns up.
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
        balances[this] -= minBalanceToSell;
        balances[msg.sender] += minBalanceToSell;
        contributors[idOf[msg.sender]].lastUpdatedOn = getDayCount();
        contributors[idOf[msg.sender]].status = sellingStatus.NOTONSALE;
        contributors[idOf[msg.sender]].minPriceinDay = 0;
        contributors[idOf[msg.sender]].sellingPriceInDay = 0;
        contributors[idOf[msg.sender]].expiryBlockNumber = 0;
        return true;
    }

    /** Function to add a team address as a contributor and store it's time issued to calculate vesting period
        * Called by BonusFinalizeAgent
        */
    function addAddressWithId(address _adr, uint id) onlyBonusFinalizeAgent returns (uint){                //VISIBILITY?
        contributors[id].adr = _adr;
        contributors[id].lastUpdatedOn = 0; //IS THIS NECESSARY
        setInitialMintingPowerOf(id);
        contributors[id].totalTransferredWei = 0; //IS THIS NECESSARY
        idOf[_adr] = id;
        contributors[id].initialContributionWei = 0;
        ContributorAdded(_adr, id);
        contributors[id].status = sellingStatus.NOTONSALE;
        contributors[id].minPriceinDay = 0; //IS THIS NECESSARY
        contributors[id].expiryBlockNumber = 0; //IS THIS NECESSARY  
        teamIssuedTimestamp[_adr] = block.timestamp;
        return id;
    }

    /** Function to add addresses post-ICO. Only by owner
        * @param receiver Address of the minting to be added
        * @param customerId Server side id of the customer
        */
    function postAllocate(address receiver, uint128 customerId) public onlyOwner {
        if(latestContributerId == 3216)
        {
            latestContributerId = teamTestAdrEndId - 1;
        }
        require(released == true);
        uint id = addContributor(receiver, 0, 0);
        PostInvested(receiver, 0, 0, customerId, id);
    }

    function setTeamTestEndId(uint id) onlyBonusFinalizeAgent {
        teamTestAdrEndId = id;
    }

  
}
