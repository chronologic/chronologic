pragma solidity ^0.4.13;

import '../../contracts/DayToken.sol';

// mock class using DayToken
contract DayTokenMock is DayToken  {


  function DayTokenMock(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint _totalPreIcoAddresses, uint _totalIcoAddresses, 
        uint _totalPostIcoAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
        bool _updateAllBalancesEnabled, uint256 _minBalanceToSell, 
        uint256 _dayInSecs, uint256 _teamLockPeriodInSec)  
        
        DayToken(_name, _symbol, _initialSupply, _decimals, 
         _mintable, _maxAddresses, _totalPreIcoAddresses, _totalIcoAddresses, 
         _totalPostIcoAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, 
         _updateAllBalancesEnabled, _minBalanceToSell, 
         _dayInSecs, _teamLockPeriodInSec) {

            owner = msg.sender;

  }

    function addContributor(uint contributorId, address _adr, uint _initialContributionDay)  {
        require(contributorId <= maxAddresses);
        require(idOf[_adr] == 0);
        contributors[contributorId].adr = _adr;
        setInitialMintingPowerOf(contributorId);
        idOf[_adr] = contributorId;
        contributors[contributorId].initialContributionDay = _initialContributionDay;
        ContributorAdded(_adr, contributorId);
        contributors[contributorId].status = sellingStatus.NOTONSALE;
    }

    function balanceOfWithoutUpdate(address _adr) public returns (uint){
        return balances[_adr];
    }
    function setBalance(address _adr, uint balance) public{
        balances[_adr] = balance;
    }
    function getIdOf(address _adr) public constant returns(uint){
        return idOf[_adr];
    }

}
