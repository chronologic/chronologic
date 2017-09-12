# Crowdsale

Source file [../../contracts/Crowdsale.sol](../../contracts/Crowdsale.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.13;

// BK Next 5 Ok
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
// BK Ok
contract Crowdsale is Haltable, SafeMathLib{

  /* Max investment count when we are still allowed to change the multisig address */
  // BK Ok
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  /* The token we are selling */
  // BK Ok
  DayToken public token;

  /* How we are going to price our offering */
  // BK Ok
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  // BK Ok
  FinalizeAgent public finalizeAgent;

  /* tokens will be transfered from this address */
  // BK Ok
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  // BK Ok
  uint public minimumFundingGoal;

  /* the UNIX timestamp start date of the crowdsale */
  // BK Ok
  uint public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  // BK Ok
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  // BK Ok
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  // BK Ok
  uint public weiRaised = 0;

  /* How many distinct addresses have invested */
  // BK Ok
  uint public investorCount = 0;

  /* How much wei we have returned back to the contract after a failed crowdfund. */
  // BK Ok
  uint public loadedRefund = 0;

  /* How much wei we have given back to investors.*/
  // BK Ok
  uint public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  // BK Ok
  bool public finalized;

  /* Do we need to have unique contributor id for each customer */
  // BK Ok
  bool public requireCustomerId;

  /* Wei Funding raised during ICO period */
  // BK Ok
  uint public weiRaisedIco = 0;

  /* Min and Max contribution during pre-ICO and during ICO   */
  // BK Next 4 Ok
  uint preMinWei;
  uint preMaxWei;
  uint minWei;
  uint maxWei;
  
  /**
    * Do we verify that contributor has been cleared on the server side (accredited investors only).
    * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted 
    * terms on sale (on the web).
    */
  // BK Ok - Always set to false
  bool public requiredSignedAddress;

  /* Server side address that signed allowed contributors (Ethereum addresses) that can participate in 
  the crowdsale */
  // BK Ok - Never used
  address public signerAddress;

  /** How much ETH each address has invested to this crowdsale */
  // BK Ok
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  // BK Ok
  mapping (address => uint256) public tokenAmountOf;

  /** This is for manual testing for the interaction from owner wallet. 
    * You can set it to any value and inspect this in blockchain explorer to 
    * see that crowdsale interaction works. 
    */
  // BK Ok - Never used
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
  // BK Ok
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  // A new investment was made
  // BK Ok
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, 
    uint contributorId);

  // Refund was processed for a contributor
  // BK Ok
  event Refund(address investor, uint weiAmount);

  // The rules were changed what kind of investments we accept
  // BK Ok
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);


  // Crowdsale end time has been changed
  // BK Ok
  event EndsAtChanged(uint endsAt);

  // BK Ok - Constructor
  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
    uint _start, uint _end, uint _minimumFundingGoal, uint _preMinWei, uint _preMaxWei, 
    uint _minWei, uint _maxWei) {

    // BK Ok
    owner = msg.sender;

    // BK Ok
    token = DayToken(_token);

    // BK Ok
    setPricingStrategy(_pricingStrategy);

    // BK Ok
    multisigWallet = _multisigWallet;
    // BK Ok
    require(multisigWallet != 0);

    // BK Ok
    require(_start != 0);
    // BK Ok
    startsAt = _start;

    // BK Ok
    require(_end != 0);
    // BK Ok
    endsAt = _end;

    // Don't mess the dates
    // BK Ok
    require(startsAt < endsAt);

    //The token minting of the addresses shouldn't start before ICO ends.
    // BK Ok
    require(endsAt <= token.initialBlockTimestamp());

    // Minimum funding goal can be zero
    // BK Ok
    minimumFundingGoal = _minimumFundingGoal;

    // BK Next 5 Ok
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
  // BK Ok
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

    // Determine if it's a good time to accept investment from this participant
    // Retail participants can only come in when the crowdsale is running
    // BK Ok
    require(getState() == State.Funding);
    // BK Ok
    uint weiAmount = msg.value;
  
    // BK Ok
    require(weiAmount >= minWei && weiAmount <= maxWei);
    // BK Ok
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, token.decimals());
    // BK Ok
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

    // BK Ok
    if (investedAmountOf[receiver] == 0) {
        // A new investor
        // BK Ok
        investorCount++;
    }

    // Update investor
    // BK Ok
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    // BK Ok
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    // Update totals
    // BK Ok
    weiRaised = safeAdd(weiRaised,weiAmount);
    // BK Ok
    tokensSold = safeAdd(tokensSold,tokenAmount);
    // BK Ok
    weiRaisedIco = safeAdd(weiRaisedIco, weiAmount);

    // Check that we did not bust the cap
    // BK Ok
    require(!isBreakingCap(weiRaisedIco));

    // BK Ok
    assignTokens(receiver, tokenAmount);

    // Pocket the money
    // BK Ok
    require(multisigWallet.send(weiAmount));

    // Tell us invest was success
    // BK Ok - Log event
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
  // BK Ok
  function preallocate(address receiver, uint fullTokens, uint weiPrice) onlyOwner public {
    require(getState() == State.PreFunding || getState() == State.Funding);
    require(!token.isValidContributorAddress(receiver) && 
      token.nextPreIcoContributorId() <= token.totalPreIcoAddresses());

    // BK Ok
    uint tokenAmount = fullTokens * 10**uint(token.decimals());
    // BK Ok
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    // BK Ok
    require(weiAmount >= preMinWei);
    // BK Ok
    require(weiAmount <= preMaxWei);

    // BK Ok
    weiRaised = safeAdd(weiRaised,weiAmount);
    // BK Ok
    tokensSold = safeAdd(tokensSold,tokenAmount);

    token.addContributor(token.nextPreIcoContributorId(), receiver, tokenAmount);
    
    // BK Ok
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    // BK Ok
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

    // BK Ok
    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    // BK Ok - Log events
    Invested(receiver, weiAmount, tokenAmount, 0, token.nextPreIcoContributorId());

    //increment counter
    token.incrementPreIcoContributorId();
  }

  /**
   * Track who is the customer making the payment so we can send thank you email.
   */
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    // BK Ok - Always false
    require(!requiredSignedAddress);
    
    // BK Ok
    require(customerId != 0);
    
    // BK Ok
    investInternal(addr, customerId);
  }

  /**
   * Allow anonymous contributions to this crowdsale.
   */
  // BK Ok
  function invest(address addr) public payable {
    // BK Ok
    require(!requireCustomerId);
    
    // BK Ok - Always false
    require(!requiredSignedAddress);
    
    // BK Ok
    investInternal(addr, 0);
  }

  /**
   * Invest to tokens, recognize the payer.
   *
   */
  // BK Ok
  function buyWithCustomerId(uint128 customerId) public payable {
    // BK Ok
    investWithCustomerId(msg.sender, customerId);
  }

  /**
   * The basic entry point to participate in the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  // BK Ok
  function buy() public payable {
    // BK Ok
    invest(msg.sender);
  }

  /**
   * The default entry point to participate the crowdsale process.
   *
   * Pay for funding, get invested tokens back in the sender address.
   */
  // BK Ok
  function () public payable {
    // BK Ok
    invest(msg.sender);
  }

  /**
   * Finalize a succcesful crowdsale.
   * The owner can trigger a call to the contract that provides post-crowdsale actions, 
   * like releasing the tokens.
   */
  // BK Ok - Only owner can call this
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

    // Already finalized
    // BK Ok
    require(!finalized);

    // Finalizing is optional. We only call it if we are given a finalizing agent.
    // BK Ok
    if(address(finalizeAgent) != 0) {
      // BK Ok
      finalizeAgent.finalizeCrowdsale();
    }

    // BK Ok
    finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   *
   * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
   */
  // BK Ok - Only owner can set the finalizeAgent
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    // BK Ok
    finalizeAgent = addr;

    // Don't allow setting bad agent
    // BK Ok
    require(finalizeAgent.isFinalizeAgent());
  }

  /**
   * Set policy do we need to have server-side customer ids for the investments.
   *
   */
  // BK Ok - Only owner can set
  function setRequireCustomerId(bool value) onlyOwner {
    // BK Ok
    requireCustomerId = value;
    // BK Ok
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
  // BK Ok - Only owner can set
  function setEndsAt(uint time) onlyOwner {
    // BK Ok - Can only set date now or in the future
    require(now <= time);
    // BK Ok
    endsAt = time;
    // BK Ok - Log event
    EndsAtChanged(endsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
   */
  // BK Ok - Only owner can set the pricing strategy, and this can be changed at any time
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    // BK Ok
    pricingStrategy = _pricingStrategy;

    // Don't allow setting bad agent
    // BK Ok
    require(pricingStrategy.isPricingStrategy());
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  // BK Ok - Only the owner can set the multisig address, before a few transactions
  function setMultisig(address addr) public onlyOwner {
    // Change Multisig wallet address
    // BK Ok
    require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);
    // BK Ok
    multisigWallet = addr;
  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal 
   * was not reached.
   */
  // BK Ok - Any account can call this function with ethers if the crowdsale has not met the minimum funding goal
  function loadRefund() public payable inState(State.Failure) {
    // BK Ok - Must send ethers
    require(msg.value != 0);
    // BK Ok
    loadedRefund = safeAdd(loadedRefund,msg.value);
  }

  /**
   * Investors can claim refund.
   */
  // BK Ok - Any contributing address can call this function if the crowdsale has not met the minimum funding goal
  function refund() public inState(State.Refunding) {
    // BK Ok - Amount contributed by account
    uint256 weiValue = investedAmountOf[msg.sender];
    // BK Ok - There are refunds to withdraw
    require(weiValue != 0);
    // BK Ok - Set the account's available refund to zero
    investedAmountOf[msg.sender] = 0;
    // BK Ok - Keep track of total
    weiRefunded = safeAdd(weiRefunded,weiValue);
    // BK Ok - Log event
    Refund(msg.sender, weiValue);
    // BK Ok - Expecting this to throw an error if there are insufficient funds to be transferred for the refund withdrawal
    require(msg.sender.send(weiValue));
  }

  /**
   * @return true if the crowdsale has raised enough money to be a succes
   */
  // BK Ok - Constant function
  function isMinimumGoalReached() public constant returns (bool reached) {
    // BK Ok
    return weiRaised >= minimumFundingGoal;
  }

  /**
   * Check if the contract relationship looks good.
   */
  // BK Ok - Constant function
  function isFinalizerSane() public constant returns (bool sane) {
    // BK Ok
    return finalizeAgent.isSane();
  }

  /**
   * Check if the contract relationship looks good.
   */
  // BK Ok - Constant function
  function isPricingSane() public constant returns (bool sane) {
    // BK Ok
    return pricingStrategy.isSane(address(this));
  }

  /**
   * Crowdfund state machine management.
   *
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   */
  // BK Ok - Constant function
  function getState() public constant returns (State) {
    // BK Ok
    if (finalized) return State.Finalized;
    // BK Ok
    else if (address(finalizeAgent) == 0) return State.Preparing;
    // BK Ok
    else if (!finalizeAgent.isSane()) return State.Preparing;
    // BK Ok
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    // BK Ok - Once all presale addresses have been aded, the crowdsale can commence
    else if (block.timestamp < startsAt) return State.PreFunding;
    // BK Ok
    else if (block.timestamp <= endsAt) return State.Funding;
    // BK Ok
    else if (isMinimumGoalReached()) return State.Success;
    // BK Ok
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    // BK Ok
    else return State.Failure;
  }

  /** This is for manual testing of multisig wallet interaction */
  // BK Ok - Only owner can call this, but `ownerTestValue` is never used
  function setOwnerTestValue(uint val) onlyOwner {
    // BK Ok
    ownerTestValue = val;
  }

  /** Interface marker. */
  // BK Ok
  function isCrowdsale() public constant returns (bool) {
    // BK Ok
    return true;
  }

  //
  // Modifiers
  //

  /** Modified allowing execution only if the crowdsale is currently running.  */
  // BK Ok
  modifier inState(State state) {
    // BK Ok
    require(getState() == state);
    // BK Ok
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
  // BK Ok
  function isBreakingCap(uint weiRaisedTotal) constant returns (bool limitBroken);


  /**
   * Create new tokens or transfer issued tokens to the investor depending on the cap model.
   */
  // BK Ok
  function assignTokens(address receiver, uint tokenAmount) private;
}

```
