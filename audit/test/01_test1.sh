#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

CONTRACTSDIR=`grep ^CONTRACTSDIR= settings.txt | sed "s/^.*=//"`

TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENTEMPSOL=`grep ^TOKENTEMPSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

PRICINGSOL=`grep ^PRICINGSOL= settings.txt | sed "s/^.*=//"`
PRICINGTEMPSOL=`grep ^PRICINGTEMPSOL= settings.txt | sed "s/^.*=//"`
PRICINGJS=`grep ^PRICINGJS= settings.txt | sed "s/^.*=//"`

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALETEMPSOL=`grep ^CROWDSALETEMPSOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`

FINALIZEAGENTSOL=`grep ^FINALIZEAGENTSOL= settings.txt | sed "s/^.*=//"`
FINALIZEAGENTTEMPSOL=`grep ^FINALIZEAGENTTEMPSOL= settings.txt | sed "s/^.*=//"`
FINALIZEAGENTJS=`grep ^FINALIZEAGENTJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

# Setting time to be a block representing one day
BLOCKSINDAY=1

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+75" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*4" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE                 = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT      = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD             = '$PASSWORD'\n" | tee -a $TEST1OUTPUT

printf "CONTRACTSDIR         = '$CONTRACTSDIR'\n" | tee -a $TEST1OUTPUT

printf "TOKENSOL             = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENTEMPSOL         = '$TOKENTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS              = '$TOKENJS'\n" | tee -a $TEST1OUTPUT

printf "PRICINGSOL           = '$PRICINGSOL'\n" | tee -a $TEST1OUTPUT
printf "PRICINGTEMPSOL       = '$PRICINGTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "PRICINGJS            = '$PRICINGJS'\n" | tee -a $TEST1OUTPUT

printf "CROWDSALESOL         = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALETEMPSOL     = '$CROWDSALETEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS          = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT

printf "FINALIZEAGENTSOL     = '$FINALIZEAGENTSOL'\n" | tee -a $TEST1OUTPUT
printf "FINALIZEAGENTTEMPSOL = '$FINALIZEAGENTTEMPSOL'\n" | tee -a $TEST1OUTPUT
printf "FINALIZEAGENTJS      = '$FINALIZEAGENTJS'\n" | tee -a $TEST1OUTPUT

printf "DEPLOYMENTDATA       = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS            = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT          = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS         = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME          = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME            = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME              = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`
`cp $CONTRACTSDIR/$PRICINGSOL $PRICINGTEMPSOL`
`cp $CONTRACTSDIR/$CROWDSALESOL $CROWDSALETEMPSOL`
`cp $CONTRACTSDIR/$FINALIZEAGENTSOL $FINALIZEAGENTTEMPSOL`

# Copy secondary files
`cp $CONTRACTSDIR/Ownable.sol .`
`cp $CONTRACTSDIR/Haltable.sol .`
`cp $CONTRACTSDIR/SafeMathLib.sol .`
`cp $CONTRACTSDIR/Crowdsale.sol .`
`cp $CONTRACTSDIR/FinalizeAgent.sol .`
`cp $CONTRACTSDIR/ERC20Basic.sol .`
`cp $CONTRACTSDIR/ERC20.sol .`
`cp $CONTRACTSDIR/ReleasableToken.sol .`
`cp $CONTRACTSDIR/StandardToken.sol .`
`cp $CONTRACTSDIR/MintableToken.sol .`
`cp $CONTRACTSDIR/UpgradeAgent.sol .`
`cp $CONTRACTSDIR/UpgradeableToken.sol .`
`cp $CONTRACTSDIR/PricingStrategy.sol .`

# --- Modify dates ---
`perl -pi -e "s/uint256 minBalanceToSell;/uint256 public minBalanceToSell;/" $TOKENTEMPSOL`
`perl -pi -e "s/uint256 teamLockPeriodInSec;/uint256 public teamLockPeriodInSec;/" $TOKENTEMPSOL`
`perl -pi -e "s/address crowdsaleAddress;/address public crowdsaleAddress;/" $TOKENTEMPSOL`
`perl -pi -e "s/address BonusFinalizeAgentAddress;/address public BonusFinalizeAgentAddress;/" $TOKENTEMPSOL`

`perl -pi -e "s/uint preMinWei;/uint public preMinWei;/" Crowdsale.sol`
`perl -pi -e "s/uint preMaxWei;/uint public preMaxWei;/" Crowdsale.sol`
`perl -pi -e "s/uint minWei;/uint public minWei;/" Crowdsale.sol`
`perl -pi -e "s/uint maxWei;/uint public maxWei;/" Crowdsale.sol`

DIFFS1=`diff $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL`
echo "--- Differences $CONTRACTSDIR/$TOKENSOL $TOKENTEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $CONTRACTSDIR/$PRICINGSOL $PRICINGTEMPSOL`
echo "--- Differences $CONTRACTSDIR/$PRICINGSOL $PRICINGTEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $CONTRACTSDIR/$CROWDSALESOL $CROWDSALETEMPSOL`
echo "--- Differences $CONTRACTSDIR/$CROWDSALESOL $CROWDSALETEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $CONTRACTSDIR/Crowdsale.sol Crowdsale.sol`
echo "--- Differences $CONTRACTSDIR/Crowdsale.sol Crowdsale.sol ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $CONTRACTSDIR/$FINALIZEAGENTSOL $FINALIZEAGENTTEMPSOL`
echo "--- Differences $CONTRACTSDIR/$FINALIZEAGENTSOL $FINALIZEAGENTTEMPSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc_4.1.11 --optimize --combined-json abi,bin,interface $TOKENTEMPSOL`;" > $TOKENJS

echo "var pricingOutput=`solc_4.1.11 --optimize --combined-json abi,bin,interface $PRICINGTEMPSOL`;" > $PRICINGJS

echo "var crowdsaleOutput=`solc_4.1.11 --optimize --combined-json abi,bin,interface $CROWDSALETEMPSOL`;" > $CROWDSALEJS

echo "var finaliserOutput=`solc_4.1.11 --optimize --combined-json abi,bin,interface $FINALIZEAGENTTEMPSOL`;" > $FINALIZEAGENTJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TOKENJS");
loadScript("$PRICINGJS");
loadScript("$CROWDSALEJS");
loadScript("$FINALIZEAGENTJS");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENTEMPSOL:DayToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENTEMPSOL:DayToken"].bin;

var pricingAbi = JSON.parse(pricingOutput.contracts["$PRICINGTEMPSOL:FlatPricing"].abi);
var pricingBin = "0x" + pricingOutput.contracts["$PRICINGTEMPSOL:FlatPricing"].bin;

var crowdsaleAbi = JSON.parse(crowdsaleOutput.contracts["$CROWDSALETEMPSOL:AddressCappedCrowdsale"].abi);
var crowdsaleBin = "0x" + crowdsaleOutput.contracts["$CROWDSALETEMPSOL:AddressCappedCrowdsale"].bin;

var finaliserAbi = JSON.parse(finaliserOutput.contracts["$FINALIZEAGENTTEMPSOL:BonusFinalizeAgent"].abi);
var finaliserBin = "0x" + finaliserOutput.contracts["$FINALIZEAGENTTEMPSOL:BonusFinalizeAgent"].bin;

// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: pricingAbi=" + JSON.stringify(pricingAbi));
// console.log("DATA: crowdsaleAbi=" + JSON.stringify(crowdsaleAbi));
// console.log("DATA: finaliserAbi=" + JSON.stringify(finaliserAbi));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTokenMessage = "Deploy CrowdsaleToken Contract";
// -----------------------------------------------------------------------------
var _tokenName = "Day";
var _tokenSymbol = "DAY";
var _tokenDecimals = 8;
var _tokenInitialSupply = 100000000;
var _tokenMintable = true;
var _maxAddresses = 7;
var _minMintingPower = 500000000000000000;
var _maxMintingPower = 1000000000000000000;
var _halvingCycle = 88;
var _initalBlockTimestamp = $ENDTIME;
var _mintingDec = 19;
var _bounty = 100000000;
var _minBalanceToSell = 8888;
var _DayInSecs = 84600;
var _teamLockPeriodInSec = 15780000;
// function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
//   bool _mintable, uint _maxAddresses, uint256 _minMintingPower, uint256 _maxMintingPower, 
//   uint _halvingCycle, uint _initialBlockTimestamp, uint256 _mintingDec, uint _bounty, 
//   uint256 _minBalanceToSell, uint256 _DayInSecs, uint256 _teamLockPeriodInSec) UpgradeableToken(msg.sender)
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployTokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new(_tokenName, _tokenSymbol, _tokenInitialSupply, _tokenDecimals, _tokenMintable,
    _maxAddresses, _minMintingPower, _maxMintingPower, _halvingCycle, _initalBlockTimestamp, _mintingDec, _bounty,
    _minBalanceToSell, _DayInSecs, _teamLockPeriodInSec, {from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);


// -----------------------------------------------------------------------------
var deployPricingMessage = "Deploy Pricing Contract";
// -----------------------------------------------------------------------------
var _oneTokenInWei = 41666666666666666;
// function FlatPricing(uint _oneTokenInWei)
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployPricingMessage);
var pricingContract = web3.eth.contract(pricingAbi);
console.log(JSON.stringify(pricingContract));
var pricingTx = null;
var pricingAddress = null;

var pricing = pricingContract.new(_oneTokenInWei, {from: contractOwnerAccount, data: pricingBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        pricingTx = contract.transactionHash;
      } else {
        pricingAddress = contract.address;
        addAccount(pricingAddress, "Pricing");
        addPricingContractAddressAndAbi(pricingAddress, pricingAbi);
        console.log("DATA: pricingAddress=" + pricingAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printTxData("pricingAddress=" + pricingAddress, pricingTx);
printBalances();
failIfGasEqualsGasUsed(tokenTx, deployTokenMessage);
failIfGasEqualsGasUsed(pricingTx, deployPricingMessage);
printTokenContractDetails();
printPricingContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployCrowdsaleMessage = "Deploy Crowdsale Contract";
// -----------------------------------------------------------------------------
// var _startTime = getUnixTimestamp('2017-07-23 09:00:00 GMT');
// var _endTime = getUnixTimestamp('2017-08-7 09:00:00 GMT');
var _minimumFundingGoal = web3.toWei(1500, "ether");
var _cap = web3.toWei(38383, "ether");
var _preMinWei = web3.toWei(33, "ether");
var _preMaxWei = web3.toWei(333, "ether");
var _minWei = web3.toWei(1, "ether");
var _maxWei = web3.toWei(333, "ether");
var _maxPreAddresses = 333;
var _maxIcoAddresses = 3216;
// function AddressCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
//   address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _weiIcoCap, 
//   uint _preMinWei, uint _preMaxWei, uint _minWei,  uint _maxWei, uint _maxPreAddresses, 
//   uint _maxIcoAddresses) 
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployCrowdsaleMessage);
var crowdsaleContract = web3.eth.contract(crowdsaleAbi);
console.log(JSON.stringify(crowdsaleContract));
var crowdsaleTx = null;
var crowdsaleAddress = null;

var crowdsale = crowdsaleContract.new(tokenAddress, pricingAddress, multisig,
    $STARTTIME, $ENDTIME, _minimumFundingGoal, _cap, _preMinWei, _preMaxWei,
    _minWei, _maxWei, _maxPreAddresses, _maxIcoAddresses,
     {from: contractOwnerAccount, data: crowdsaleBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        crowdsaleTx = contract.transactionHash;
      } else {
        crowdsaleAddress = contract.address;
        addAccount(crowdsaleAddress, "Crowdsale");
        addCrowdsaleContractAddressAndAbi(crowdsaleAddress, crowdsaleAbi);
        console.log("DATA: crowdsaleAddress=" + crowdsaleAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("crowdsaleAddress=" + crowdsaleAddress, crowdsaleTx);
printBalances();
failIfGasEqualsGasUsed(crowdsaleTx, deployCrowdsaleMessage);
printCrowdsaleContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployFinaliserMessage = "Deploy BonusFinalizerAgent Contract";
// -----------------------------------------------------------------------------
var _teamAddresses = [team1, team2, team3];
var _testAddresses = [testAddress1, testAddress2];
var _testAddressTokens = 88;
var _teamBonus = 5;
var _totalBountyInDay = 8888;
// function BonusFinalizeAgent(DayToken _token, Crowdsale _crowdsale,  address[] _teamAddresses, 
// address[] _testAddresses, uint _testAddressTokens, uint _teamBonus, uint _totalBountyInDay)
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployFinaliserMessage);
var finaliserContract = web3.eth.contract(finaliserAbi);
console.log(JSON.stringify(finaliserContract));
var finaliserTx = null;
var finaliserAddress = null;

var finaliser = finaliserContract.new(tokenAddress, crowdsaleAddress, _teamAddresses,
    _testAddresses, _testAddressTokens, _teamBonus, _totalBountyInDay,
    {from: contractOwnerAccount, data: finaliserBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        finaliserTx = contract.transactionHash;
      } else {
        finaliserAddress = contract.address;
        addAccount(finaliserAddress, "BonusFinalizerAgent");
        addFinaliserContractAddressAndAbi(finaliserAddress, finaliserAbi);
        console.log("DATA: finaliserAddress=" + finaliserAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("finaliserAddress=" + finaliserAddress, finaliserTx);
printBalances();
failIfGasEqualsGasUsed(finaliserTx, deployFinaliserMessage);
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var stitchMessage = "Stitch Contracts Together";
console.log("RESULT: " + stitchMessage);
var stitch1Tx = token.setMintAgent(crowdsaleAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch2Tx = token.setMintAgent(finaliserAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch3Tx = token.setReleaseAgent(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
var stitch4Tx = token.setTransferAgent(crowdsaleAddress, true, {from: contractOwnerAccount, gas: 400000});
var stitch5Tx = token.setBonusFinalizeAgentAddress(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
var stitch6Tx = crowdsale.setFinalizeAgent(finaliserAddress, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("stitch1Tx", stitch1Tx);
printTxData("stitch2Tx", stitch2Tx);
printTxData("stitch3Tx", stitch3Tx);
printTxData("stitch4Tx", stitch4Tx);
printTxData("stitch5Tx", stitch5Tx);
printTxData("stitch6Tx", stitch6Tx);
printBalances();
failIfGasEqualsGasUsed(stitch1Tx, stitchMessage + " 1");
failIfGasEqualsGasUsed(stitch2Tx, stitchMessage + " 2");
failIfGasEqualsGasUsed(stitch3Tx, stitchMessage + " 3");
failIfGasEqualsGasUsed(stitch4Tx, stitchMessage + " 4");
failIfGasEqualsGasUsed(stitch5Tx, stitchMessage + " 5");
failIfGasEqualsGasUsed(stitch6Tx, stitchMessage + " 6");
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale start
// -----------------------------------------------------------------------------
var startsAtTime = crowdsale.startsAt();
var startsAtTimeDate = new Date(startsAtTime * 1000);
console.log("RESULT: Waiting until startAt date at " + startsAtTime + " " + startsAtTimeDate +
  " currentDate=" + new Date());
while ((new Date()).getTime() <= startsAtTimeDate.getTime()) {
}
console.log("RESULT: Waited until start date at " + startsAtTime + " " + startsAtTimeDate +
  " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution - 100 ETH From Account8 - After Crowdsale Start";
console.log("RESULT: " + validContribution1Message);
var validContribution1Tx = eth.sendTransaction({from: account8, to: crowdsaleAddress, gas: 400000, value: web3.toWei("100", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("validContribution1Tx", validContribution1Tx);
printBalances();
failIfGasEqualsGasUsed(validContribution1Tx, validContribution1Message);
printTokenContractDetails();
printPricingContractDetails();
printCrowdsaleContractDetails();
printFinaliserContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var invalidContribution1Message = "Send Invalid Contribution - 100 ETH From Account6 - Before Crowdsale Start";
console.log("RESULT: " + invalidContribution1Message);
var invalidContribution1Tx = eth.sendTransaction({from: account6, to: mecAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("invalidContribution1Tx", invalidContribution1Tx);
printBalances();
passIfGasEqualsGasUsed(invalidContribution1Tx, invalidContribution1Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution1Message = "Send Valid Contribution - 100 ETH From Account6 - After Crowdsale Start";
console.log("RESULT: " + validContribution1Message);
var validContribution1Tx = mec.investWithCustomerId(account6, 123, {from: account6, to: mecAddress, gas: 400000, value: web3.toWei("100", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("validContribution1Tx", validContribution1Tx);
printBalances();
failIfGasEqualsGasUsed(validContribution1Tx, validContribution1Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var validContribution2Message = "Send Valid Contribution - 1900 ETH From Account7 - After Crowdsale Start";
console.log("RESULT: " + validContribution1Message);
var validContribution2Tx = mec.investWithCustomerId(account7, 124, {from: account7, to: mecAddress, gas: 400000, value: web3.toWei("1900", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("validContribution2Tx", validContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(validContribution2Tx, validContribution2Message);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finaliseMessage = "Finalise Crowdsale";
console.log("RESULT: " + finaliseMessage);
var finaliseTx = mec.finalize({from: contractOwnerAccount, to: mecAddress, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("finaliseTx", finaliseTx);
printBalances();
failIfGasEqualsGasUsed(finaliseTx, finaliseMessage);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transfersMessage = "Testing token transfers";
console.log("RESULT: " + transfersMessage);
var transfers1Tx = cst.transfer(account8, "1000000000000000000", {from: account6, gas: 100000});
var transfers2Tx = cst.approve(account9,  "2000000000000000000", {from: account7, gas: 100000});
while (txpool.status.pending > 0) {
}
var transfers3Tx = cst.transferFrom(account7, account9, "2000000000000000000", {from: account9, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("transfers1Tx", transfers1Tx);
printTxData("transfers2Tx", transfers2Tx);
printTxData("transfers3Tx", transfers3Tx);
printBalances();
failIfGasEqualsGasUsed(transfers1Tx, transfersMessage + " - transfer 1 token ac6 -> ac8");
failIfGasEqualsGasUsed(transfers2Tx, transfersMessage + " - approve 2 tokens ac7 -> ac9");
failIfGasEqualsGasUsed(transfers3Tx, transfersMessage + " - transferFrom 2 tokens ac7 -> ac9");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var invalidPaymentMessage = "Send invalid payment to token contract";
console.log("RESULT: " + invalidPaymentMessage);
var invalidPaymentTx = eth.sendTransaction({from: account7, to: cstAddress, gas: 400000, value: web3.toWei("123", "ether")});

while (txpool.status.pending > 0) {
}
printTxData("invalidPaymentTx", invalidPaymentTx);
printBalances();
passIfGasEqualsGasUsed(invalidPaymentTx, invalidPaymentMessage);
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
// Wait for crowdsale end
// -----------------------------------------------------------------------------
var endsAtTime = mec.endsAt();
var endsAtTimeDate = new Date(endsAtTime * 1000);
console.log("RESULT: Waiting until startAt date at " + endsAtTime + " " + endsAtTimeDate +
  " currentDate=" + new Date());
while ((new Date()).getTime() <= endsAtTimeDate.getTime()) {
}
console.log("RESULT: Waited until start date at " + endsAtTime + " " + endsAtTimeDate +
  " currentDate=" + new Date());

EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
