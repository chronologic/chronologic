pragma solidity ^0.4.11; 

import './StandardToken.sol'; 
import "./UpgradeableToken.sol"; 
import "./ReleasableToken.sol"; 
import "./MintableToken.sol"; 
import "./DayInterface.sol"; 
import "./SafeMathLib.sol"; 

//TODO: Add permissions: modifiers

/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract DayToken is ReleasableToken, MintableToken, UpgradeableToken, DayInterface {

event UpdatedTokenInformation(string newName, string newSymbol); 
event UpdateFailed(uint id); 
event UpToDate (bool status); 
event MintingPower(address adr, uint256 mintingPower); 
event Balance(address adr, uint256 balance); 

string public name; 

string public symbol; 

uint8 public decimals; 

/**
    * Construct the token.
    *
    * This token must be created through a team multisig wallet, so that it is owned by that wallet.
    *
    * @param _name Token name
    * @param _symbol Token symbol - should be all caps
    * @param _initialSupply How many tokens we start with
    * @param _decimals Number of decimal places
    * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
    */
function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable, uint _maxAddresses, uint256 _minMintingPower,
 uint256 _maxMintingPower, uint _halvingCycle, uint _initialBlockTimestamp, uint _mintingDec,uint _bounty)UpgradeableToken(msg.sender) {

// Create any address, can be transferred
// to team multisig via changeOwner(),
// also remember to call setUpgradeMaster()
owner = msg.sender; 
name = _name; 
symbol = _symbol; 
totalSupply = _initialSupply; 
decimals = _decimals; 

// Create initially all balance on the team multisig
balances[owner] = totalSupply; 

maxAddresses=_maxAddresses;
minMintingPower=_minMintingPower;
maxMintingPower=_maxMintingPower;
halvingCycle=_halvingCycle;
initialBlockTimestamp=_initialBlockTimestamp;
mintingDec=_mintingDec;
latestContributerId=0;
latestAllUpdate=0;
bounty=_bounty;

if (totalSupply > 0) {
Minted(owner, totalSupply); 
}

if ( ! _mintable) {
mintingFinished = true; 
require(totalSupply != 0); 
}
//SET INITIAL VALUES

//CALL function setInitialMintingPowerOf
}

/**
    * When token is released to be transferable, enforce no new tokens can be created.
    */
function releaseTokenTransfer()public onlyReleaseAgent {
mintingFinished = true; 
super.releaseTokenTransfer(); 
}

/**
    * Allow upgrade agent functionality kick in only if the crowdsale was success.
    */
function canUpgrade()public constant returns(bool) {
return released && super.canUpgrade(); 
}

/**
    * Owner can update token information here
    */
function setTokenInformation(string _name, string _symbol)onlyOwner {
name = _name; 
symbol = _symbol; 
UpdatedTokenInformation(name, symbol); 
}

/**
    * Owner can update token information here
    */
function getPhaseCount(uint day)public constant returns (uint phase) {
phase = (day/halvingCycle) + 1; 
return (phase); 
}

function getDayCount() public constant returns (uint today) {
today = ((block.timestamp - initialBlockTimestamp)/86400); 
return today; 
}

function setInitialMintingPowerOf(uint256 id)internal returns (bool) {//Call once, initially for all contributor structures.
if (id <= latestContributerId) {
Contributor user = contributors[id]; 
user.mintingPower = (maxMintingPower - (id * (maxMintingPower - minMintingPower)/maxAddresses)); 
return true; 
}
else {
return false; 
}
}

function getMitingPowerByAddress(address _adr)public constant returns (uint256) {
Contributor user = contributors[idOf[_adr]]; 
MintingPower(user.adr, user.mintingPower); 
return user.mintingPower; 
}

function getMitingPowerById(uint id)public constant returns (uint256) {
Contributor user = contributors[id]; 
MintingPower(user.adr, user.mintingPower); 
return user.mintingPower; 
}

/*
// CHECK THIS. NEEDS UPDATES
function getTotalMinted(address _adr)returns (uint256) {
Contributor user = contributors[idOf[_adr]]; 
return user.balance - user.totalTransferred - user.initialContribution; 
}
*/
//<==========End Minting Power=========>
//<===================Balances=================>
function availableBalanceOf(uint256 id)internal returns (uint256) {
Contributor user = contributors[id]; 
uint256 balance = user.balance; 
for (uint i = user.lastUpdatedOn; i < getDayCount(); i++) {
balance = (balance * ((10 ** (mintingDec + 2) * (2 ** (getPhaseCount(i)-1))) + user.mintingPower))/(2 ** (getPhaseCount(i)-1)); 
}
balance = balance/10 ** ((mintingDec + 2) * (getDayCount() - user.lastUpdatedOn)); 
return balance; 
}

//For Internal Calls. Not Public
function updateBalanceOf(uint256 id)internal returns (bool success) {
Contributor user = contributors[id]; 
user.balance = availableBalanceOf(id); 
balances[user.adr] = user.balance; 
return true; 
}

//For user to call
function balanceOf(address _adr)public constant returns (uint256 balance) {
uint id = idOf[_adr]; 
if (id <= maxAddresses) {
require(updateBalanceOf(id)); 
}
return balances[_adr]; 
}
function balanceById(uint id)public constant returns (uint256 balance) {
if (id <= maxAddresses) {
address _adr=contributors[id].adr; 
require(updateBalanceOf(id)); 
}
return balances[_adr]; 
}

// To be called daily
function updateAllBalances()public returns (bool status) {
    uint today = (block.timestamp - initialBlockTimestamp)/1 days; 
        require(today != latestAllUpdate); 
for (uint i = 1; i <= latestContributerId; i++) {
if (updateBalanceOf(i)) {}
else {
UpdateFailed(i); 
}
}
latestAllUpdate = today; 
balances[msg.sender]+= bounty; 
UpToDate(true); 
}
function setBounty(uint256 _bounty) onlyOwner{
    bounty=_bounty;
}
//=============================UNDER DEV===============================
//<===================End Balances================>

//<===================Tranfers====================> //Allowances to be considered??
function transfer(address _to, uint256 _value)returns (bool) {
if (balanceOf(msg.sender) < _value)throw; 
if (balanceOf(_to) + _value < balanceOf(_to))throw; 
balances[msg.sender] = safeSub(balances[msg.sender], _value); 
balances[_to] = safeSub(balances[msg.sender], _value); 
Transfer(msg.sender, _to, _value); 
}

function transferFrom() {

}

function transferMintingAddress(address _from, address _to)returns (bool) {
}


//<================End Transfers===================>

}