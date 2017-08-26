pragma solidity ^0.4.13;

import '../../contracts/AddressCappedCrowdsale.sol';

// mock class using AddressCappedCrowdsale
contract AddressCappedCrowdsaleMock is AddressCappedCrowdsale  {


function AddressCappedCrowdsaleMock(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
    uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, uint _preMinWei, 
    uint _preMaxWei, uint _minWei, uint _maxWei)
        
    AddressCappedCrowdsale(_token, _pricingStrategy, _multisigWallet, 
     _start, _end, _minimumFundingGoal, _weiIcoCap, _preMinWei, 
     _preMaxWei, _minWei, _maxWei) {

       owner = msg.sender;
  }

}
