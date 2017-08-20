pragma solidity ^0.4.11;

import '../../contracts/AddressCappedCrowdsale.sol';

// mock class using AddressCappedCrowdsale
contract AddressCappedCrowdsaleMock is AddressCappedCrowdsale  {


function AddressCappedCrowdsaleMock(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
    uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, uint _preMinWei, 
    uint _preMaxWei, uint _minWei, uint _maxWei, uint _maxPreAddresses, uint _maxIcoAddresses)
        
    AddressCappedCrowdsale(_token, _pricingStrategy, _multisigWallet, 
     _start, _end, _minimumFundingGoal, _weiIcoCap, _preMinWei, 
     _preMaxWei, _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses) {

       owner = msg.sender;

  }


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
    //require(dayToken.latestContributerId() >= 33);
    require(weiAmount >= minWei && weiAmount <= maxWei);
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, token.decimals());
    require(tokenAmount != 0);
    // Add a contributor structure
    uint id = dayToken.addContributor(receiver, weiAmount);
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
    weiRaisedIco = safeAdd(weiRaisedIco, weiAmount);

    // Check that we did not bust the cap
    require(!isBreakingCap(weiRaisedIco));

    assignTokens(receiver, tokenAmount);

    // Pocket the money
    if(!multisigWallet.send(weiAmount)) throw;

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId, id);
  }


  /**
    * copied from base class as it is private
    */
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }


// overriding to remove onlyOwner modifier
function preallocate(address receiver, uint fullTokens, uint weiPrice)  public {

    require(getState() == State.PreFunding);
    uint tokenAmount = fullTokens * 10**uint(token.decimals());
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    require(weiAmount >= preMinWei);
    require(weiAmount <= preMaxWei);

    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    uint id = token.addContributor(receiver, tokenAmount);
    
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0, id);
  }

}
