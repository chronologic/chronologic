The below information is only on the basis of visual review of DayToken.sol and inherited files and not actual tests:


#1 VERY HIGH IMPORTANCE and BIG BUG : missing modifier for addContributor function.
Because of missing modifier any person who reads the code can add his/her account as contributer without paying anything which should only be allowed for crowdsale contract

#2 MEDIUM IMPORTANCE - transferFrom function in DayToken.sol does not return any value.
function declaration returns a (bool success) but not the function definition

#3 MEDIUM IMPORTANCE - addContributor function in DayToken.sol accepts uint _initialBalance but never uses it
Being dead code, this should be removed

// #4 To be reviewed on actual test if missing adr is an issue or not
#4 MEDIUM IMPORTANCE - missing adr in balanceById if _id > latestContributerId

#5 MEDIUM IMPORTANCE - transfer and transferFrom implementation in DayToken.sol does a dual check for balance update using require and safeAdd/safeSub
Checks can be removed when using safeAdd and SafeSub, otherwise, result in consuming extra gas and a little higher transaction cost

#6 MEDIUM IMPORTANCE - A lot of spaces in DayToken.sol need safeMathLib call to handle overflows

#7 LOW IMPORTANCE - Use require(...) instead of throw in upgradeableToken.sol line 63
 "Syntax Checker: Deprecated throw in favour of require(), assert() and revert()"
 
#8 VERY LOW IMPORTANCE - getTotalSupply returns uint256 totalSupply which was declared earlier as uint
This is a very low importance since, uint is an allias for uint256, but still, should be modified to maintain uniformity


Potential Risks : 
Use of block.timestamp : "block.timestamp" can be influenced by miners to a certain degree. 
That means that a miner can "choose" the block.timestamp, to a certain degree, to change the outcome of a transaction in the mined block.
Reference (http://solidity.readthedocs.io/en/develop/frequently-asked-questions.html#are-timestamps-now-block-timestamp-reliable)
BUT, from perspective of DayToken, no alternatives are present as of now

Miscellaneous info :
VERY LOW IMPORTANCE - getOnSaleAddresses notifies available address by events (which needs to be decoded if not using etherscan.io) 

In progress : 
1. This information is not confirmed right now, but there seems to be an issue with fetchSuccessfulSaleProceed maybe with comment or implementation (which seems to be called by seller as per comment on function)
2. I need a little help for reviewing [transfer] function of DayToken.sol with developer.

Please note that visual review is not completed yet, which would be followed by actual tests on geth instead of testrpc