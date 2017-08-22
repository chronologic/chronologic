# ChronoLogic Audit Report

## Focus Areas
The audit report is focused on the following key areas - though this is not an exhaustive list.
### Correctness
- No correctness defects uncovered during static analysis?
- No implemented contract violations uncovered during execution?
- No other generic incorrect behaviour detected during execution?
- Adherence to adopted standards such as ERC20?
### Testability
- Test coverage across all functions and events?
- Test cases for both expected behaviour and failure modes?
- Settings for easy testing of a range of parameters?
- No reliance on nested callback functions or console logs?
- Avoidance of test scenarios calling other test scenarios?
### Security
- No presence of known security weaknesses?
- No funds at risk of malicious attempts to withdraw/transfer?
- No funds at risk of control fraud?
- Prevention of Integer Overflow or Underflow?
### Best Practice
- Explicit labeling for the visibility of functions and state variables?
- Proper management of gas limits and nested execution?
- Latest version of the Solidity compiler?

## Classification
### Defect Severity
- Minor - A defect that does not have a material impact on the contract execution and is likely to be subjective.
- Moderate - A defect that could impact the desired outcome of the contract execution in a specific scenario.
- Major - A defect that impacts the desired outcome of the contract execution or introduces a weakness that may be exploited.
- Critical - A defect that presents a significant security vulnerability or failure of the contract across a range of scenarios.

## Findings
### Minor
- [Magic numbers used in several functions](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/24)
- [Recommend using the shortcut variable that was created](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/23)
- [A minting address is never set to status SOLD](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/22)
- [Safe math should be used for all user-inputted values](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/17)
- [Unnecessary cast to int](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/15)
- [DRY isContributor](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/13)
- [updateBalanceOf should return a bool](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/12)
- [Expected total coins minted to be a uint, an int is returned](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/11)
- [DRY mintingPowerByAddress](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/10)
- [Explicit declaration of variable access modifier](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/9)
- [Recommend using the latest version of Solidity supported by Truffle.js](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/8)
- [FlatPricing strategy can be initialized in an invalid state](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/7)
- [Safe math functions should be constant](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/6)
- [Gender neutral language is recommended](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/5)
- [ERC20 Token Standard Consistency](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/4)
- [Simplify Conditional logic](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/3)
- [Code formatting is not consistent](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/2)
### Moderate
- [Value mismatch when purchasing minting address](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/21)
- [Re-entracy issue](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/20)
- [Issue with sellMintingAddress](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/19)
- [Another re-entrancy attack](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/18)
- [Potential re-entrancy attack](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/16)
- [Possibly reentrancy attack](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/1)
### Major
- None found
### Critical
- [Transfer is not behaving correctly](https://api.github.com/repos/BlockchainLabsNZ/chronologic/issues/14)

