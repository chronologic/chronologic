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

* Outside Scope
  * [ ] [code-review/ConsenSysWallet.md](code-review/ConsenSysWallet.md)
    * [ ] contract MultiSigWallet
* Unused Testing Framework
  * [ ] [code-review/Migrations.md](code-review/Migrations.md)
    * [ ] contract Migrations 
