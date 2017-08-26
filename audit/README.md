# Chronologic Crowdsale Contract Audit

Status: Work in progress

Commits [3ba1fe83](https://github.com/chronologic/chronologic/commit/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1),
[fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8) and
[be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93).

## Summary

TODO

<br />

### Crowdsale Contract

* Funds contributed during the crowdsale are immediately transferred to the multisig wallet
* If the minimum funding goal is not met, contributed funds must be transferred back into the crowdsale contract for investors
  to be able to withdraw their refunds

<br />

### Finalizer Contract

* *WARNING* - The *BonusFinalizeAgent* must be correctly set for the crowdsale contract before the crowdsale contracts
  `finalize()` function can be called, or the crowdsale will never be finalised correctly.

<br />

### Token Contract

The token contract is [ERC20](https://github.com/ethereum/eips/issues/20) compliant with the following features:

* `decimals` is correctly defined as `uint8` instead of `uint256`
* `transfer(...)` and `transferFrom(...)` will throw an error instead of return true/false when the transfer is invalid
* `transfer(...)` and `transferFrom(...)` have not been built with a check on the size of the data being passed. This check is
  [no longer a recommended feature](https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/)
* `approve(...)` has the [requirement that a non-zero approval limit be set to 0 before a new non-zero limit can be set](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Table Of Contents](#table-of-contents)
* [Recommendations](#recommendations)
* [Testing](#testing)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

* **HIGH IMPORTANCE** - In *DayToken*, `balances[_to] = safeAdd(balances[msg.sender], _value);` in `transfer(...)` should be
  `balances[_to] = safeAdd(balances[to], _value); `
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **MEDIUM IMPORTANCE** - In *DayToken* and *Crowdsale*, please convert the magic numbers like `333`, `3227`, `3227`, `3245` into
  constant variable that will explain the meaning of these numbers
  * [x] Fixed in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - In *DayToken*, `minBalanceToSell`, `crowdsaleAddress` and `BonusFinalizeAgentAddress` should be made public to
  provide visibility
  * [x] Fixed for `minBalanceToSell` in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - In *DayToken*, `DayInSecs` should be renamed `dayInSecs` and `BonusFinalizeAgentAddress` should be renamed
  `bonusFinalizeAgentAddress` for variable naming consistency
  * [x] Fixed for `bonusFinalizeAgentAddress` in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - In *DayToken*, `modifier onlyCrowdsale()` is unused and can be removed to simplify the contract
  * [x] Fixed in [be2bbba9](https://github.com/chronologic/chronologic/commit/be2bbba97ba1c78206d2a21724f6e0b94c9afd93)
* **LOW IMPORTANCE** - Un-indent `function transferFrom(...)` in *DayToken*
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - In *Crowdsale*, `preMinWei`, `preMaxWei`, `minWei` and `maxWei` should be made public to provide visibility
* **LOW IMPORTANCE** - In *AddressCappedCrowdsale*, `maxIcoAddresses` is never used
  * [x] Fixed in [fd679446](https://github.com/chronologic/chronologic/commit/fd679446f01c2d29b02856719548d6a35e8c34c8)
* **LOW IMPORTANCE** - In *DayToken*, `isValidContributorId(...)` and `isValidContributorAddress(...)` should be made constant
* **LOW IMPORTANCE** - Remove `DayToken.updateAllBalances()`. After enquiring about the potentially large gas cost of executing
  this function, the developers have stated that this function is not required any more, as balances are now calculated on the fly
  and this function is now disabled by default, using the switch `updateAllBalancesEnabled`.
 
<br />

<hr />

## Testing

* Testing script [test/01_test1.sh](test/01_test1.sh)
* Testing results [test/test1results.txt](test/test1results.txt)

<br />

<hr />

## Code Review

* Crowdsale Contract And Inheritance Dependencies
  * [x] [code-review/Ownable.md](code-review/Ownable.md)
    * [x] contract Ownable
  * [x] [code-review/Haltable.md](code-review/Haltable.md)
    * [x] contract Haltable is Ownable
  * [x] [code-review/SafeMathLib.md](code-review/SafeMathLib.md)
    * [x] contract SafeMathLib
  * [x] [code-review/Crowdsale.md](code-review/Crowdsale.md)
    * [x] contract Crowdsale is Haltable, SafeMathLib
  * [x] [code-review/AddressCappedCrowdsale.md](code-review/AddressCappedCrowdsale.md)
    * [x] contract AddressCappedCrowdsale is Crowdsale
* Crowdsale Finaliser Contract And New Dependencies
  * [x] [code-review/FinalizeAgent.md](code-review/FinalizeAgent.md)
    * [x] contract FinalizeAgent
  * [x] [code-review/BonusFinalizeAgent.md](code-review/BonusFinalizeAgent.md)
    * [x] contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib
* Crowdsale Pricing Contract And New Dependencies
  * [x] [code-review/PricingStrategy.md](code-review/PricingStrategy.md)
    * [x] contract PricingStrategy
  * [x] [code-review/FlatPricing.md](code-review/FlatPricing.md)
    * [x] contract FlatPricing is PricingStrategy, SafeMathLib 
* Token Contract And New Dependencies
  * [x] [code-review/ERC20Basic.md](code-review/ERC20Basic.md)
    * [x] contract ERC20Basic
  * [x] [code-review/ERC20.md](code-review/ERC20.md)
    * [x] contract ERC20 is ERC20Basic
  * [x] [code-review/ReleasableToken.md](code-review/ReleasableToken.md)
    * [x] contract ReleasableToken is ERC20, Ownable
  * [x] [code-review/StandardToken.md](code-review/StandardToken.md)
    * [x] contract StandardToken is ERC20, SafeMathLib 
  * [x] [code-review/MintableToken.md](code-review/MintableToken.md)
    * [x] contract MintableToken is StandardToken, Ownable
  * [x] [code-review/UpgradeAgent.md](code-review/UpgradeAgent.md)
    * [x] contract UpgradeAgent
  * [x] [code-review/UpgradeableToken.md](code-review/UpgradeableToken.md)
    * [x] contract UpgradeableToken is StandardToken 
  * [ ] [code-review/DayToken.md](code-review/DayToken.md)
    * [ ] contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken

<br />

### Not Reviewed

#### ConsenSys Multisig Wallet

[../contracts/ConsenSysWallet.sol](../contracts/ConsenSysWallet.sol) is outside the scope of this review.

The following are the differences between the version in this repository and the original ConsenSys
[MultiSigWallet.sol](https://raw.githubusercontent.com/ConsenSys/MultiSigWallet/e3240481928e9d2b57517bd192394172e31da487/contracts/solidity/MultiSigWallet.sol):

    $ diff -w OriginalConsenSysMultisigWallet.sol ConsenSysWallet.sol 
    1c1
    < pragma solidity 0.4.4;
    ---
    > pragma solidity ^0.4.13;
    367d366
    < 

The only difference is in the Solidity version number.

<br />

The following are the differences between the version in this repository and the ConsenSys MultiSigWallet deployed 
at [0xa646e29877d52b9e2de457eca09c724ff16d0a2b](https://etherscan.io/address/0xa646e29877d52b9e2de457eca09c724ff16d0a2b#code)
by Status.im and is currently holding 284,732.64 Ether:

    $ diff -w ConsenSysWallet.sol StatusConsenSysMultisigWallet.sol 
    1c1
    < pragma solidity ^0.4.13;
    ---
    > pragma solidity ^0.4.11;
    10,18c10,18
    <     event Confirmation(address indexed sender, uint indexed transactionId);
    <     event Revocation(address indexed sender, uint indexed transactionId);
    <     event Submission(uint indexed transactionId);
    <     event Execution(uint indexed transactionId);
    <     event ExecutionFailure(uint indexed transactionId);
    <     event Deposit(address indexed sender, uint value);
    <     event OwnerAddition(address indexed owner);
    <     event OwnerRemoval(address indexed owner);
    <     event RequirementChange(uint required);
    ---
    >     event Confirmation(address indexed _sender, uint indexed _transactionId);
    >     event Revocation(address indexed _sender, uint indexed _transactionId);
    >     event Submission(uint indexed _transactionId);
    >     event Execution(uint indexed _transactionId);
    >     event ExecutionFailure(uint indexed _transactionId);
    >     event Deposit(address indexed _sender, uint _value);
    >     event OwnerAddition(address indexed _owner);
    >     event OwnerRemoval(address indexed _owner);
    >     event RequirementChange(uint _required);
    295c295
    <     /// @dev Returns total number of transactions after filers are applied.
    ---
    >     /// @dev Returns total number of transactions after filters are applied.

The only differences are in the Solidity version number and the prefixing of the event variables with `_`s.

This [link](https://etherscan.io/find-similiar-contracts?a=0xa646e29877d52b9e2de457eca09c724ff16d0a2b) will display
79 (currently) other multisig wallet contracts with high similarity to the ConsenSys MultiSigWallet deployed by Status.im .

Some further information on the ConsenSys multisig wallet:

* [The Gnosis MultiSig Wallet and our Commitment to Security](https://blog.gnosis.pm/the-gnosis-multisig-wallet-and-our-commitment-to-security-ce9aca0d17f6)
* [Release of new Multisig Wallet](https://blog.gnosis.pm/release-of-new-multisig-wallet-59b6811f7edc)

An audit on a previous version of this multisig has already been done by [Martin Holst Swende](https://gist.github.com/holiman/77dfe5addab521bf28ea552591ef8ac4).

<br />

#### Unused Testing Framework

The following file is used for the testing framework are is outside the scope of this review: 
* [../contracts/Migrations.sol](../contracts/Migrations.sol)

