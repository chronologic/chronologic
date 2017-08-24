# MintableToken

Source file [../../contracts/MintableToken.sol](../../contracts/MintableToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;
// BK Next 4 Ok
import './ERC20.sol';
import './Ownable.sol';
import './StandardToken.sol';
import "./SafeMathLib.sol";

/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
// BK Ok
contract MintableToken is StandardToken, Ownable {

  // BK Ok
  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  // BK Ok
  mapping (address => bool) public mintAgents;

  // BK Ok
  event MintingAgentChanged(address addr, bool state  );

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent).
   */
  // BK Ok - Only minting agent can mint before mintingFinished
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    // BK Ok
    totalSupply = safeAdd(totalSupply, amount);
    // BK Ok
    balances[receiver] = safeAdd(balances[receiver], amount);
    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    // BK Ok
    Transfer(0, receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  // BK Ok - Only owner can set the mint agent before mintingFinished
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    // BK Ok
    mintAgents[addr] = state;
    // BK Ok
    MintingAgentChanged(addr, state);
  }

  // BK Ok
  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    // BK Ok
    require(mintAgents[msg.sender]);
    // BK Ok
    _;
  }

  /** Make sure we are not done yet. */
  // BK Ok
  modifier canMint() {
    // BK Ok
    require(!mintingFinished);
    // BK Ok
    _;
  }
}

```
