pragma solidity ^0.4.11; 

import "./StandardToken.sol"; 
import "./UpgradeableToken.sol"; 
import "./ReleasableToken.sol"; 
import "./MintableToken.sol";
import "./SafeMathLib.sol"; 

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
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

    enum sellingStatus {NOTONSALE, SOLD, EXPIRED, ONSALE}
    /** Basic structure for a contributor with a minting Address
        * adr address of the contributor
        * initialContributionWei initial contribution of the contributor in wei
        * lastUpdatedOn day count from Minting Epoch when the account balance was last updated
        * mintingPower Initial Minting power of the address
        * totalTransferredDay Total transferred day tokens: integer. Negative value indicates transfer from
        * expiryBlockNumber Variable to mark end of Minting address sale. Set by user
        * minPriceInDay minimum price of Minting address in Day tokens. Set by user
        * status Selling status Variable for transfer Minting address.
        * sellingPriceInDay Variable for transfer Minting address. Price at which the address is actually sold
        */
    struct Contributor
    {
        address adr;
        uint256 initialContributionWei;
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
    /* Stores the id of the lastest contributor added */
    uint256 public latestContributerId;
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
    /* Bounty to be given to the person calling UpdateAllBalances() */
    uint256 public bounty;
    /* Minimum Balance in Day tokens required to sell a minting address */
    uint256 minBalanceToSell;
    /* Team address lock down period from issued time, in seconds */
    uint256 teamLockPeriodInSec;  //Initialize and set function
    /* Store id of the address after team and test addresses are assigned */
    uint public teamTestAdrEndId;
    /* Duration in secs that we consider as a day. (For test deployment purposes, if we want to decrease length of a day. default: 84600)*/
    uint256 public DayInSecs;
    address crowdsaleAddress;
    address BonusFinalizeAgentAddress;

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
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply?
        */
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, 
        uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, 
        uint256 _minBalanceToSell, uint256 _DayInSecs, uint256 _teamLockPeriodInSec) UpgradeableToken(msg.sender) {
        
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
        DayInSecs = _DayInSecs;
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
        daySinceMintingEpoch = ((block.timestamp - initialBlockTimestamp)/DayInSecs); 
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
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        return contributors[idOf[_adr]].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }

    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }


     /**
    * Returns the amount of DAY tokens minted by the address
    * @param _adr Address whose total minted is to be returned
    */
    function getTotalMinted(address _adr) public constant returns (int256) {
        uint id = idOf[_adr];
        return int(balances[_adr]) - ((int(contributors[id].initialContributionWei)+contributors[id].totalTransferredDay)); 
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
        // proceed only if not already updated today
        require(contributors[_id].lastUpdatedOn != getDayCount());
        totalSupply = safeSub(totalSupply, balances[contributors[_id].adr]);
        balances[contributors[_id].adr] = availableBalanceOf(_id);
        totalSupply = safeAdd(totalSupply, balances[contributors[_id].adr]);
        contributors[_id].lastUpdatedOn = getDayCount();
        return true; 
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address.
        * Calculates the balance on fly only if it is a minting address else simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    function balanceOf(address _adr) public constant returns (uint256 balance) {
        uint id = idOf[_adr]; 
        if(block.timestamp >= initialBlockTimestamp) {
            if (id != 0 && id <= latestContributerId) {
                return ( availableBalanceOf(id) );
            }
        }
        return balances[_adr];    
    }

    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified id.
        * Calculates the balance on fly only if it is a minting address else simply returns balance from balances[] mapping.
        * For public calls.
        * @param _id address whose balance is to be returned.
        */
    function balanceById(uint _id) public constant returns (uint256 balance) {
        address adr=contributors[_id].adr; 
        if(block.timestamp >= initialBlockTimestamp) {
            if (_id != 0 && _id <= latestContributerId) {
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
        require(block.timestamp >= initialBlockTimestamp);
        uint today = (block.timestamp - initialBlockTimestamp)/1 days;
        require(today != latestAllUpdate); 

        for (uint i = 1; i <= latestContributerId; i++) {
            if (!updateBalanceOf(i))
                UpdateFailed(i); 
        }

        latestAllUpdate = today;
        // before awarding bounty update balance if caller has minting power
        uint id = idOf[msg.sender];
        if ( id != 0 && id <= latestContributerId ) updateBalanceOf(id);
        balances[msg.sender] = safeAdd(balances[msg.sender],bounty);
        balances[this] = safeSub(balances[this], bounty);
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
    function getTotalSupply() public constant returns (uint){
        return totalSupply;
    }

    /**
        * Standard ERC20 function overidden.
        * Used to transfer day tokens from caller's address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    function transfer(address _to, uint _value) public returns (bool success) {
        if(teamIssuedTimestamp[msg.sender] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[msg.sender] >= teamLockPeriodInSec);
        }

        // Check sender account has enough balance and transfer amount is non zero
        require ( balanceOf(msg.sender) >= _value && _value != 0 ); 
         
        uint msgSenderId = idOf[msg.sender];
        if(msgSenderId != 0 && msgSenderId <= latestContributerId)
        {
            updateBalanceOf(msgSenderId);
            contributors[msgSenderId].totalTransferredDay = contributors[msgSenderId].totalTransferredDay + int(-(_value));
        }

        uint toId = idOf[_to];
        if(toId != 0 && toId <= latestContributerId)
        {
            updateBalanceOf(toId);
            contributors[toId].totalTransferredDay = contributors[toId].totalTransferredDay + int(_value);
        }

        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[msg.sender], _value); 
        Transfer(msg.sender, _to, _value);

        return true;
    }
    /**
        * Standard ERC20 Standard Token function overridden. Added Team address vesting period lock. 
        */
        function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if(teamIssuedTimestamp[_from] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[_from] >= teamLockPeriodInSec);
        }

        uint _allowance = allowed[_from][msg.sender];

        // Check from account has enough balance, transfer amount is non zero 
        // and _value is allowed to be transferred
        require ( balanceOf(_from) >= _value && _value != 0  &&  _value <= _allowance); 

        uint fromId = idOf[_from];
        if(fromId != 0 && fromId <= latestContributerId)
        {
            updateBalanceOf(fromId);
            contributors[fromId].totalTransferredDay = contributors[fromId].totalTransferredDay + int(-(_value));
        }

        uint toId = idOf[_to];
        if(toId !=0 && toId <= latestContributerId)
        {
            updateBalanceOf(toId);
            contributors[toId].totalTransferredDay = contributors[toId].totalTransferredDay + int(_value);
        }

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        
        return true;
    }

    /**
        * Transfer minting address from one user to another
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool){
        // _to should be non minting address
        require(idOf[_to] == 0 || idOf[_to] > latestContributerId);
        
        uint id = idOf[_from];
        // update balance of from address before transferring minting power
        updateBalanceOf(id);

        contributors[id].adr = _to;
        idOf[_to] = id;
        idOf[_from] = 0;
        contributors[id].initialContributionWei = 0;
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
        * @param _initialContributionWei Initial Contribution of the contributor to be added
        */
    function addContributor(address _adr, uint _initialContributionWei) returns(uint){
        uint id = ++latestContributerId;
        require(idOf[_adr] == 0);
        contributors[id].adr = _adr;
        setInitialMintingPowerOf(id);
        idOf[_adr] = id;
        contributors[id].initialContributionWei = _initialContributionWei;
        ContributorAdded(_adr, id);
        contributors[id].status = sellingStatus.NOTONSALE;
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
    /** Function to be called by any user to get the latest contributor ID.
        */
    function getLatestContributorId() constant public returns(uint id){
        return latestContributerId;
    }

    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) public returns (bool){
        if(teamIssuedTimestamp[msg.sender] != 0)
        {
            require(block.timestamp - teamIssuedTimestamp[msg.sender] >= teamLockPeriodInSec);
        }
        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);

        // update balance of sender address before checking for minimum required balance
        updateBalanceOf(id);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceinDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        balances[this] = safeAdd(balances[this], minBalanceToSell);
        balances[msg.sender] = safeSub(balances[msg.sender], minBalanceToSell);
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
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public returns(bool){
        if(contributors[_offerId].status != sellingStatus.NOTONSALE && block.number > contributors[_offerId].expiryBlockNumber )
        {
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        address soldAddress = contributors[_offerId].adr;
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        require(_offerInDay >= contributors[_offerId].minPriceinDay);
        //first get the offered DayToken in the token contract & then transfer the total sum (minBalanceToSend+_offerInDay) to the seller
        balances[this] = safeAdd(balances[this], _offerInDay);
        balances[msg.sender] = safeSub(balances[msg.sender], _offerInDay);
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) {
            //mark the offer as sold & let seller pull the proceed to his own account.
            sellingPriceInDayOf[soldAddress] = _offerInDay;
            soldAddresses[soldAddress] = true; 
        }
        return true;
    }

    /** Funtion to allow seller to get back his deposited amount of day tokens(minBalanceToSell) and offer made by buyer after successful sale.
        * Throws if sale is not successful
        * Resets all sale-related variables to 0 and status to NOTONSALE
        */
    function fetchSuccessfulSaleProceed() public  returns(bool) {
        require(soldAddresses[msg.sender] == true);
        balances[this] = safeSub(balances[this], minBalanceToSell + sellingPriceInDayOf[msg.sender]);
        balances[msg.sender] = safeAdd(balances[msg.sender], minBalanceToSell + sellingPriceInDayOf[msg.sender]);
        soldAddresses[msg.sender] = false;
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
        balances[this] = safeSub(balances[this], minBalanceToSell);
        // update balance of seller address before refunding
        updateBalanceOf(id);
        balances[msg.sender] = safeAdd(balances[msg.sender],minBalanceToSell);
        contributors[idOf[msg.sender]].status = sellingStatus.NOTONSALE;
        contributors[idOf[msg.sender]].minPriceinDay = 0;
        contributors[idOf[msg.sender]].expiryBlockNumber = 0;
        return true;
    }

    /** Function to add a team address as a contributor and store it's time issued to calculate vesting period
        * Called by BonusFinalizeAgent
        */
    function addAddressWithId(address _adr, uint id) onlyBonusFinalizeAgent returns (uint){                //VISIBILITY?
        contributors[id].adr = _adr;
        setInitialMintingPowerOf(id);
        idOf[_adr] = id;
        contributors[id].initialContributionWei = 0;
        ContributorAdded(_adr, id);
        contributors[id].status = sellingStatus.NOTONSALE;
        teamIssuedTimestamp[_adr] = block.timestamp;
        return id;
    }

    /** Function to add addresses post-ICO. Only by owner
        * @param receiver Address of the minting to be added
        * @param customerId Server side id of the customer
        */
    function postAllocate(address receiver, uint128 customerId) public onlyOwner {
        if(latestContributerId >= 3227 && latestContributerId<= 3245)
        {
            latestContributerId = teamTestAdrEndId - 1;
        }
        require(released == true);
        uint id = addContributor(receiver, 0);
        PostInvested(receiver, 0, 0, customerId, id);
    }

    function setTeamTestEndId(uint id) onlyBonusFinalizeAgent {
        teamTestAdrEndId = id;
    }
}
