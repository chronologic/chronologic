pragma solidity ^0.4.13;

import "./SafeMathLib.sol";
import "./Haltable.sol";
import "./PricingStrategy.sol";
import "./FinalizeAgent.sol";
import "./DayToken.sol";


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
  uint public preMinWei;
  uint public preMaxWei;
  uint public minWei;
  uint public maxWei;
  
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
