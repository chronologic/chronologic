pragma solidity ^0.4.11; 

import './DayInterface.sol'; 
import './DayToken.sol'; 

contract Bounty is DayInterface, DayToken {

    uint256 bounty; 
    uint lastUpdated; //STORE THIS SOMEWHERE
    function getBounty() public returns (bool) {
        uint today = (block.timestamp - initialBlockTimestamp)/1 days; 
        require(today != lastUpdated); 
        updateAllBalances(); 
        lastUpdated = today; 
        balances[msg.sender] + = bounty; 
    }
}

