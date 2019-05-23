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
- **Magic numbers used in several functions** - `Best practice` Examples: [#L598](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L598]) [#L617-L619](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L617-L619]) ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/24)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Recommend using the shortcut variable that was created** - `Best practice` [#L588-L590](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L588-L590]) This variable ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/23)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **A minting address is never set to status SOLD** - `Correctness` [#L23](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L23]) The `SOLD` status is ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/22)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Safe math should be used for all user-inputted values** - `Correctness` # Day Token [#L566](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L566]) ``` balances[this] = safeSub(balances[this], ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/17)
    - [ ] **Not Fixed**
- **Unnecessary cast to int** - `Correctness` # DayToken.sol [#L411](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L411]) `contributors[toId].totalTransferredDay = ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/15)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **DRY isContributor** - `Best practice` # DayToken.sol There is a pattern used throughout this file for identifying if an ID is a contributor. The modifier `onlyContributor` uses it, and several ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/13)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **updateBalanceOf should return a bool** - `Correctness` # DayToken.sol [#L259](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L259]) `function updateBalanceOf(uint256 _id) internal ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/12)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Expected total coins minted to be a uint, an int is returned** - `Correctness` # DayToken.sol [#L234](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L234]) `function getTotalMinted(address _adr) public ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/11)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **DRY mintingPowerByAddress** - `Best practice` # DayToken.sol [#L217](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L217]) `function getMintingPowerByAddress` is repeating ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/10)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Explicit declaration of variable access modifier** - `Best practice` # DayToken.sol [#L74](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L74]) e.g ``` uint256 public bounty; /* Minimum Balance ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/9)
- **Recommend using the latest version of Solidity supported by Truffle.js** - `Best practice`, Security` The latest version of Solidity supported by Truffle.js is 0.4.13, the contracts are all using 0.4.11  [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/8)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **FlatPricing strategy can be initialized in an invalid state** - `Best practice` # FlatPricing.sol We would recommend adding `require(_oneTokenInWei > 0)` in the constructor, you should not be able to declare this variable to 0 because ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/7)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Safe math functions should be constant** - `Best practice` Add Constant modifier to SafeMath functions as they don't modify storage  [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/6)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Gender neutral language is recommended** - `Correctness` # UpgradeableToken.sol `* Somebody has upgraded some of his tokens.` Should probably say `* Somebody has upgraded some of their tokens.` # DayToken.sol ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/5)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **ERC20 Token Standard Consistency** - `Best practice` # ERC20.sol and ERC20Basic.sol The names of the parameters deviate from the standard naming conventions in ERC20 Token Standard. We would recommend following ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/4)
    - [ ] **Not Fixed**
- **Simplify Conditional logic** - `Best practice` # StandardToken.sol [#L68](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/StandardToken.sol#L68]) `require(!((_value != 0) && (allowed[msg.sender][_spender] ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/3)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Code formatting is not consistent** - `Best practice` We would recommend using a code linter and picking a consistent style guide. This would make the code look cleaner, and more professional.  [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/2)
    - [ ] **Not Fixed**
### Moderate
- **Value mismatch when purchasing minting address** - `Correctness` [#L547-L550](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L547-L550]) The logic ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/21)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Re-entracy issue** - `Security` # DayToken.sol [#L549-L550](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L549-L550]) ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/20)
    - [ ] **Not Fixed**
- **Issue with sellMintingAddress** - `Correctness` # DayToken.sol [#L538](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L538]) `sellMintingAddress` ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/19)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Another re-entrancy attack** - `Security` # DayToken.sol [#L515](https://github.com/BlockchainLabsNZ/chronologic/blob/3ba1fe830881ca9e85f2c2db3e77b3b333bc4dd1/contracts/DayToken.sol#L515]) ``` ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/18)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Potential re-entrancy attack** - `Security` # DayToken.sol [#L414](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L414]) ``` balances[_to] = safeAdd(balances[_to], ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/16)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
- **Possibly reentrancy attack** - `Security` # StandardToken.sol [#L47](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/StandardToken.sol#L47]) ``` balances[_to] = safeAdd(balances[_to],_value); ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/1)
    - [ ] **Not Fixed**
### Major
- None found
### Critical
- **Transfer is not behaving correctly** - `Correctness` # DayToken.sol [#L380](https://github.com/BlockchainLabsNZ/chronologic/blob/dev/contracts/DayToken.sol#L380]) `balances[_to] = safeAdd(balances[msg.sender], ... [View on GitHub](https://github.com/BlockchainLabsNZ/chronologic/issues/14)
    - [x] Fixed [007cdecf](https://github.com/chronologic/chronologic/commit/007cdecfc51495689e591d821c07cbef80a4e284)
