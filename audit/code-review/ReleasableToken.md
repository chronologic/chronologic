# ReleasableToken

Source file [../../contracts/ReleasableToken.sol](../../contracts/ReleasableToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;

// BK Next 2 Ok
import './Ownable.sol';
import './ERC20.sol';


/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
// BK Ok
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  // BK Ok
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. 
   * If false we are are in transfer lock up period.
   */
  // BK Ok
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. 
   * These are crowdsale contracts and possible the team multisig itself. 
   */
  // BK Ok
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   */
  // BK Ok
  modifier canTransfer(address _sender) {

    // BK Ok
    if (!released) {
        // BK Ok - 
        require(transferAgents[_sender]);
    }

    // BK Ok
    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  // BK Ok - Only owner can set releaseAgent when not released
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don't do interface check here as we might want to a normal wallet address to act as a release agent
    // BK Ok
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  // BK Ok - Only owner can set the transferAgent when not released
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    // BK Ok
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. 
   * It is only called if the crowdsale has been success (first milestone reached).
   */
   // BK Ok - Only the releaseAgent can release the token transfers
  function releaseTokenTransfer() public onlyReleaseAgent {
    // BK Ok
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  // BK Ok
  modifier inReleaseState(bool releaseState) {
    // BK Ok
    require(releaseState == released);
    // BK Ok
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  // BK Ok
  modifier onlyReleaseAgent() {
    // BK Ok
    require(msg.sender == releaseAgent);
    // BK Ok
    _;
  }

  // BK Ok
  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
    // BK Ok
   return super.transfer(_to, _value);
  }

  // BK Ok
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    // BK Ok
    return super.transferFrom(_from, _to, _value);
  }

}

```
