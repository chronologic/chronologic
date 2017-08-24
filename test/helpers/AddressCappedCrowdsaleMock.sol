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


  /**
    * copied from base class as it is private
    */
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }


// overriding to remove onlyOwner modifier
 function preallocate(address receiver, uint fullTokens, uint weiPrice) public {
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

}
