pragma solidity ^0.4.11;

import '../../contracts/DayToken.sol';

// mock class using DayToken
contract DayTokenMock is DayToken  {


  function DayTokenMock(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, 
        uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, 
        uint256 _minBalanceToSell, uint256 _DayInSecs, uint256 _teamLockPeriodInSec)  
        
        DayToken(_name, _symbol, _initialSupply, _decimals, _mintable, _maxAddresses, _minMintingPower, 
         _maxMintingPower, _halvingCycle, _initialBlockTimestamp, _mintingDec, _bounty, 
         _minBalanceToSell, _DayInSecs, _teamLockPeriodInSec) {

  }

    function addContributorNew(address _adr, uint _initialContributionWei, uint _initialBalance)  returns(uint){
        uint id = ++latestContributerId;
        require(idOf[_adr] == 0);
        contributors[id].adr = _adr;
        setInitialMintingPowerOf(id);
        idOf[_adr] = id;
        balances[_adr] = _initialBalance;
        totalSupply = safeAdd(totalSupply, _initialBalance);
        contributors[id].initialContributionWei = _initialContributionWei;
        ContributorAdded(_adr, id);
        contributors[id].status = sellingStatus.NOTONSALE;
        return id;
    }

       function balanceOfWithoutUpdate(address _adr) public returns (uint){
        return balances[_adr];
    }
    function addBalance(address _adr, uint balance) public{
        balances[_adr] = balance;
    }
    function getIdOf(address _adr) public constant returns(uint){
        return idOf[_adr];
    }

}
