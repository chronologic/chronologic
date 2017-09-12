# Chronologic Audit Report 


Aim of this report is to check the contracts for issues with :

1. Security
2. Weaknesses
3. Incorrect implementation / bugs
4. Check if contract works as intended
5. Dead code

### Classification
1. Low : Does not impact functionality, more of a suggestion or best practice
2. Medium : Could impact functionality
3. High : Impacts intended functionality

### Contract wise Findings

#### DayToken.sol

1. **HIGH** : missing modifier for addContributor function. Any person who reads the code can add his/her account as contributer without paying anything which should only be allowed for crowdsale contract - **RESOLVED**
2. **HIGH** : balances[_to] = safeAdd(balances[msg.sender], _value); in transfer function should be balances[_to] = safeAdd(balances[to], _value); - **RESOLVED**
3. **MEDIUM** : transferFrom function does not return any value. function declaration returns a (bool success) but not the function definition - **RESOLVED**
4. **MEDIUM** : missing variable "adr" in balanceById function if condition is satisfied :  _id > latestContributerId - **RESOLVED** and code modifed for more logic
5. **LOW** : transfer and transferFrom implementation does a dual check for balance update using require and safeAdd/safeSub
Checks can be removed when using safeAdd and SafeSub, otherwise, result in consuming extra gas and a little higher transaction cost
6. **LOW** : addContributor function accepts uint _initialBalance but never uses it. Being dead code, can be removed - **RESOLVED**
7. **LOW** : getTotalSupply returns uint256 totalSupply which was declared earlier as uint Though, uint is an allias for uint256, but still, should be modified to maintain uniformity - **RESOLVED**
8. **LOW** : Incorrect initialContributionWei in Contributor structure, should be initialContributionDay which is used to caluclate total minted day tokens - **RESOLVED**
9. **LOW** : Unused Modifier onlyCrowdsale, can be removed

#### Crowdsale.sol
1. **HIGH** : crowdsale contract sends weiAmount (= msg.value) to Daytoken.sol's addContributor function from investInternal(...)
This results in miscalculation of total minted day tokens from getTotalMinted() function. "tokenAmount" should be sent instead of "weiAmount"  - **RESOLVED**
2. **MEDIUM** : missing "require(multisigWallet != 0);" in Crowdsale constructor - **RESOLVED**
3. **LOW** : Use require(...) instead of throw @ refund(), setMultisig(), setEndsAt(), investInternal() - **RESOLVED**
4. **LOW** : Unecessary if-else condition in investInternal(), can be replaced by require - **RESOLVED**
5. **LOW** : Unused mappings and variables : "earlyParticipantWhitelist", "Whitelisted" - **RESOLVED**

#### AddressCappedCrowdsale.sol
1. **LOW** : unused variables "weiAmount", "tokenAmount" and "tokensSoldTotal" in isBreakingCap() - **RESOLVED**

#### FlatPricing.sol
1. **LOW** : Unused declared variables in calculatePrice definition - **RESOLVED**

#### UpgradeableToken.sol
1. **LOW** : Use require(...) instead of throw - **RESOLVED**

#### Miscellaneous Suggestions
1. Remove all commented code which makes previous used code dead, it makes the contract difficult to read for investors - **RESOLVED**
2. Code formatting should be corrected
