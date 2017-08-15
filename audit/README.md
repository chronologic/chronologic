# Chronologic Crowdsale Contract Audit

Status: Work in progress

## Summary

TODO

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Table Of Contents](#table-of-contents)
* [Testing](#testing)
* [Code Review](#code-review)

<br />

<hr />

## Testing

* Testing script [test/01_test1.sh](test/01_test1.sh)
* Testing results [test/test1results.txt](test/test1results.txt)

<br />

<hr />

## Code Review

* Crowdsale Contract And Dependencies
  * [x] [code-review/Ownable.md](code-review/Ownable.md)
    * [x] contract Ownable
  * [x] [code-review/Haltable.md](code-review/Haltable.md)
    * [x] contract Haltable is Ownable
  * [x] [code-review/SafeMathLib.md](code-review/SafeMathLib.md)
    * [x] contract SafeMathLib
  * [ ] [code-review/Crowdsale.md](code-review/Crowdsale.md)
    * [ ] contract Crowdsale is Haltable, SafeMathLib
  * [ ] [code-review/AddressCappedCrowdsale.md](code-review/AddressCappedCrowdsale.md)
    * [ ] contract AddressCappedCrowdsale is Crowdsale
* Crowdsale Finaliser Contract And New Dependencies
  * [ ] [code-review/FinalizeAgent.md](code-review/FinalizeAgent.md)
    * [ ] contract FinalizeAgent
  * [ ] [code-review/BonusFinalizeAgent.md](code-review/BonusFinalizeAgent.md)
    * [ ] contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib
* Crowdsale Pricing Contract And New Dependencies
  * [ ] [code-review/PricingStrategy.md](code-review/PricingStrategy.md)
    * [ ] contract PricingStrategy
  * [ ] [code-review/FlatPricing.md](code-review/FlatPricing.md)
    * [ ] contract FlatPricing is PricingStrategy, SafeMathLib 
* Token Contract And New Dependencies
  * [ ] [code-review/ERC20Basic.md](code-review/ERC20Basic.md)
    * [ ] contract ERC20Basic
  * [ ] [code-review/ERC20.md](code-review/ERC20.md)
    * [ ] contract ERC20 is ERC20Basic
  * [ ] [code-review/ReleasableToken.md](code-review/ReleasableToken.md)
    * [ ] contract ReleasableToken is ERC20, Ownable
  * [ ] [code-review/StandardToken.md](code-review/StandardToken.md)
    * [ ] contract StandardToken is ERC20, SafeMathLib 
  * [ ] [code-review/MintableToken.md](code-review/MintableToken.md)
    * [ ] contract MintableToken is StandardToken, Ownable
  * [ ] [code-review/UpgradeAgent.md](code-review/UpgradeAgent.md)
    * [ ] contract UpgradeAgent
  * [ ] [code-review/UpgradeableToken.md](code-review/UpgradeableToken.md)
    * [ ] contract UpgradeableToken is StandardToken 
  * [ ] [code-review/DayToken.md](code-review/DayToken.md)
    * [ ] contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken

<br />

### Not Reviewed

* Unused Contracts
  * [ ] [code-review/FractionalERC20.md](code-review/FractionalERC20.md)
    * [ ] contract FractionalERC20 is ERC20
  * [ ] [code-review/newToken.md](code-review/newToken.md)
    * [ ] contract newToken is StandardToken, UpgradeAgent
* Outside Scope
  * [ ] [code-review/ConsenSysWallet.md](code-review/ConsenSysWallet.md)
    * [ ] contract MultiSigWallet
* Unused Testing Framework
  * [ ] [code-review/Migrations.md](code-review/Migrations.md)
    * [ ] contract Migrations 

<br />

### Compiler Warnings

```
PricingStrategy.sol:17:19: Warning: Unused local variable
  function isSane(address crowdsale) public constant returns (bool) {
                  ^---------------^
FlatPricing.sol:23:39: Warning: Unused local variable
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
                                      ^------------^
FlatPricing.sol:23:55: Warning: Unused local variable
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
                                                      ^-------------^
FlatPricing.sol:23:72: Warning: Unused local variable
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
                                                                       ^---------------^
PricingStrategy.sol:17:19: Warning: Unused local variable
  function isSane(address crowdsale) public constant returns (bool) {
                  ^---------------^
AddressCappedCrowdsale.sol:42:28: Warning: Unused local variable
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
                           ^------------^
AddressCappedCrowdsale.sol:42:44: Warning: Unused local variable
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
                                           ^--------------^
AddressCappedCrowdsale.sol:42:83: Warning: Unused local variable
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
                                                                                  ^------------------^
PricingStrategy.sol:17:19: Warning: Unused local variable
  function isSane(address crowdsale) public constant returns (bool) {
                  ^---------------^
```