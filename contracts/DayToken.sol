pragma solidity ^0.4.11; 

import "./StandardToken.sol"; 
import "./UpgradeableToken.sol"; 
import "./ReleasableToken.sol"; 
import "./MintableToken.sol"; 
import "./DayInterface.sol"; 
import "./SafeMathLib.sol"; 

//TODO: Add permissions: modifiers

/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract DayToken is ReleasableToken, MintableToken, UpgradeableToken, DayInterface {

    event UpdatedTokenInformation(string newName, string newSymbol); 
    event UpdateFailed(uint id); 
    event UpToDate (bool status); 
    event MintingPower(address adr, uint256 mintingPower); 
    event Balance(address adr, uint256 balance); 

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
        * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
        */
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable, uint _maxAddresses, uint256 _minMintingPower,
        uint256 _maxMintingPower, uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, address[] testAddresses) UpgradeableToken(msg.sender) {

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
        latestContributerId=0;
        latestAllUpdate=0;
        bounty=_bounty;

        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
        }

        //SET INITIAL VALUES
        uint i;
        for(i=1;i<=testAddresses.length;i++)
        {
            contributors[i].initialContribution=79200000000;
            contributors[i].balance=contributors[i].initialContribution;
            setInitialMintingPowerOf(i);
            contributors[i].totalMinted=0;
            contributors[i].totalTransferred=0;
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
    function setInitialMintingPowerOf(uint256 _id) internal returns (bool) {//Call once, initially for all contributor structures.
        if (_id <= maxAddresses) {
            //Contributor user = contributors[_id]; 
            contributors[_id].mintingPower = (maxMintingPower - (_id * (maxMintingPower - minMintingPower)/maxAddresses)); 
            return true; 
        }
        else {
            return false; 
        }
    }
     /**
        * Returns minting power of a particular address.
        * @param _adr Address whose minting power is to be returned
        */
    // DANGER! ERROR! MINTING POWER HALVED. MINTING POWER IS NOT CHANGED. SEPARATE FUNCTION?
    function getMitingPowerByAddress(address _adr) public constant returns (uint256) {
        //Contributor user = contributors[idOf[_adr]]; 
        MintingPower(contributors[idOf[_adr]].adr, contributors[idOf[_adr]].mintingPower); 
        return contributors[idOf[_adr]].mintingPower; 
    }
    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMitingPowerById(uint _id) public constant returns (uint256) {
        //Contributor user = contributors[_id]; 
        MintingPower(contributors[_id].adr, contributors[_id].mintingPower); 
        return contributors[_id].mintingPower; 
    }

    /*
    // CHECK THIS. NEEDS UPDATES
    function getTotalMinted(address _adr)returns (uint256) {
    Contributor user = contributors[idOf[_adr]]; 
    return user.balance - user.totalTransferred - user.initialContribution; 
    }
    */
  

    /**
        * Calculates and returns the balance based on the minting power, the day and the phase.
        * Can only be called internally
        * Can calculate balance based on last updated. *!MAXIMUM 3 DAYS!*. A difference of more than 3 days will lead to crashing of the contract.
        * @param _id id whose balnce is to be calculated
        */
    function availableBalanceOf(uint256 _id) internal returns (uint256) {
       // Contributor user = contributors[_id]; 
        uint256 balance = contributors[_id].balance; 
        for (uint i = contributors[_id].lastUpdatedOn; i < getDayCount(); i++) {
            balance = (balance * ((10 ** (mintingDec + 2) * (2 ** (getPhaseCount(i)-1))) + contributors[_id].mintingPower))/(2 ** (getPhaseCount(i)-1)); 
        }
        balance = balance/10 ** ((mintingDec + 2) * (getDayCount() - contributors[_id].lastUpdatedOn)); 
        return balance; 
    }
    /**
        * Updates the balance of the spcified id in its structure and also in the balamces[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
        //Contributor user = contributors[_id]; 
        contributors[_id].balance = availableBalanceOf(_id);
        totalSupply = safeSub(totalSupply, balances[contributors[_id].adr]);
        balances[contributors[_id].adr] = contributors[_id].balance; 
        totalSupply = safeAdd(totalSupply, balances[contributors[_id].adr]);
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
        if (id <= maxAddresses) {
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
        if (_id <= maxAddresses) {
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
    function updateAllBalances() public returns (bool status) {
        uint today = (block.timestamp - initialBlockTimestamp)/1 days; 
        require(today != latestAllUpdate); 
        for (uint i = 1; i <= maxAddresses; i++) {
            if (updateBalanceOf(i)) {}
            else {
                UpdateFailed(i); 
            }
        }
        latestAllUpdate = today; 
        balances[msg.sender]+= bounty; 
        totalSupply = safeAdd(totalSupply, bounty);
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
    function getTotalSupply() public returns (uint256)
    {
        return totalSupply;
    }
    /**`
        * Standard ERC20 function overidden.
        * USed to transfer day tokens from caller's address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    function transfer(address _to, uint _value) returns (bool success) {
        if (balanceOf(msg.sender) < _value) return false; 
        if (balanceOf(_to) + _value < balanceOf(_to)) return false; 
        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[msg.sender], _value); 
        Transfer(msg.sender, _to, _value); 
        contributors[idOf[msg.sender]].balance = safeSub(contributors[idOf[msg.sender]].balance,_value);
        uint id=idOf[_to];
        if(id<=maxAddresses)
        {
            contributors[idOf[_to]].balance = safeAdd(contributors[idOf[_to]].balance,_value);
        }
        return true;
    }

    /*
    function transferFrom() {

    }
    */

    /**
        * Transfer minting address from one user to another
        * Called by a minting address
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    function transferMintingAddress(address _to) public returns (bool) {
        uint id=idOf[msg.sender];
        if(id<=maxAddresses){
            if(id<=maxAddresses){
           // Contributor user = contributors[id]; 
            contributors[id].adr=_to;
            contributors[id].balance=balances[_to];
            idOf[_to]=id;
            idOf[msg.sender]=0;
            return true;
            }
            else
                return false;
        }
        else{
            return false;
        }
    }
}
