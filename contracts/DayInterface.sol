pragma solidity ^0.4.11;

contract DayInterface{
//Minting Power in %
//ContributionID should start from 1. 0 for not a minting address.

//HOW TO SET INITIAL VALUES OF EVERY VARIABLE IN STRUCTURE?
struct Contributor
{
    address adr;
	uint256 initialContribution;
    uint256 balance;
    uint256 lastUpdatedOn; //Day from Minting Epoch
    uint256 mintingPower;
    uint256 totalMinted; 
    int totalTransferred;
}
mapping (address => uint) public idOf;
mapping (uint256 => Contributor) contributors;

uint public latestAllUpdate;
uint256 public latestContributerId;
uint256 public maxAddresses;// Hard Code: Stores max number of minting addresses
uint256 public minMintingPower;
uint256 public maxMintingPower;
uint256 public halvingCycle;
uint256 public initialBlockCount; //Hard Code
uint256 public initialBlockTimestamp; //Hard Code
uint256 public dayPerEther; //Hard Code
uint256 public mintingDec; 

function availableBalanceOf(uint256 id)internal returns (uint256);//calculates balance and calls setBalanceOf() Done

function setBalanceOf(address,uint256) returns (bool); //Done
function setInitialMintingPowerOf(uint256 id) internal returns (bool);//Done

function getDayCount()public constant returns (uint today); // Day from DAY epoch: getCurrentBlock.now()-initialBlockTimestamp
function getPhaseCount(uint day)public constant returns (uint phase); // Returns daycount/halving cycle ----Done

function setHalvingCycle(uint256) returns (bool);

function setMaxMinMintingPower(uint256 _newMinMintingPower,uint256 _newMaxMintingPower) returns (bool);
function getTotalMinted(address _adr) returns (uint256);
function getMitingPowerByAddress(address _adr)public constant returns (uint256);
function getMitingPowerById(uint id)public constant returns (uint256);

function transferMintingAddress(address _from, address _to)returns (bool); //-------------?

function getTotalSupply() returns (uint256); //Watch gas used. Pretty big calc.
//function setDayPerEther(uint256) returns (bool);// ?????
function balanceById(uint id)public constant returns (uint256 balance);
function updateBalanceOf(uint256 id)internal returns (bool success);
function updateAllBalances()public returns (bool status);
/*
function getTimestamp() constant returns (uint256){
    return now;
}
*/
function getCurrentBlock() constant returns (uint256 blockNumber)
{
	return block.number - initialBlockCount;
}

function getCurrentEthBlock() constant returns (uint256 blockNumber)
{
	return block.number;
}

}