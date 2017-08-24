# UpgradeableToken

Source file [../../contracts/UpgradeableToken.sol](../../contracts/UpgradeableToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.11;

// BK Next 3 Ok
import './ERC20.sol';
import './StandardToken.sol';
import "./UpgradeAgent.sol";

/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
// BK Ok
contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. 
   * This can be the same as team multisig wallet, as what it is with its default value. 
   */
  // BK Ok
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  // BK Ok
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  // BK Ok
  uint256 public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don't have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  // BK Ok
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  // BK Ok
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  /**
   * New upgrade agent available.
   */
  // BK Ok
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  // BK Ok - Constructor
  function UpgradeableToken(address _upgradeMaster) {
    // BK Ok
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  // BK Ok - Anyone can call this
  function upgrade(uint256 value) public {
    // BK Ok
    UpgradeState state = getUpgradeState();
    // BK Ok
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));
    // Validate input value.
    // BK Ok - Can upgrade partial amount
    require(value!=0);

    // BK Ok - This token contract's balances for the account is reduced
    balances[msg.sender] = safeSub(balances[msg.sender],value);

    // Take tokens out from circulation
    // BK Ok - This token contract's total supply is reduced 
    totalSupply = safeSub(totalSupply,value);
    // BK Ok - Keeping track of the amount of tokens upgraded
    totalUpgraded = safeAdd(totalUpgraded,value);

    // Upgrade agent reissues the tokens
    // BK Ok - New token contract increases the balance for the account
    upgradeAgent.upgradeFrom(msg.sender, value);
    // BK Ok - Log event
    Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  // BK Ok
  function setUpgradeAgent(address agent) external {
    // BK Ok
    require(canUpgrade());
    // BK Ok
    require(agent != 0x0);
    // Only a master can designate the next agent
    // BK Ok
    require(msg.sender == upgradeMaster);
    // Upgrade has already begun for an agent
    // BK Ok - Can only set upgrade agent when upgrading has not commenced
    require(getUpgradeState() != UpgradeState.Upgrading);

    // BK Ok
    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    // BK Ok
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    // BK Ok - New token contract originalSupply must equal old token contract totalSupply
    require(upgradeAgent.originalSupply() == totalSupply);

    // BK Ok
    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  // BK Ok - Constant function
  function getUpgradeState() public constant returns(UpgradeState) {
    // BK Ok - Non upgradable token contract
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    // BK Ok - No upgrade agent specified yet
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    // BK Ok - Upgrade agent specified, but upgrade has not commenced
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    // BK Ok - Upgrade agent specified and upgrading has commenced
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  // BK Ok
  function setUpgradeMaster(address master) public {
    // BK Ok
    require(master != 0x0);
    // BK Ok - Current upgradeMaster can set new upgradeMaster
    require(msg.sender == upgradeMaster);
    // BK Ok
    upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  // BK Ok - Constant function. Can always upgrade this token contract
  function canUpgrade() public constant returns(bool) {
    // BK Ok
     return true;
  }

}

```
