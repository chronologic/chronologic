// Jul 7 2017
var ethPriceUSD = 262.3980;

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "Account #0 - Miner");
addAccount(eth.accounts[1], "Account #1 - Contract Owner");
addAccount(eth.accounts[2], "Account #2 - Multisig");
addAccount(eth.accounts[3], "Account #3 - Team #1");
addAccount(eth.accounts[4], "Account #4 - Team #2");
addAccount(eth.accounts[5], "Account #5 - Team #3");
addAccount(eth.accounts[6], "Account #6 - Test Address #1");
addAccount(eth.accounts[7], "Account #7 - Test Address #2");
addAccount(eth.accounts[8], "Account #8");
addAccount(eth.accounts[9], "Account #9");


var minerAccount = eth.accounts[0];
var contractOwnerAccount = eth.accounts[1];
var multisig = eth.accounts[2];
var team1 = eth.accounts[3];
var team2 = eth.accounts[4];
var team3 = eth.accounts[5];
var testAddress1 = eth.accounts[6];
var testAddress2 = eth.accounts[7];
var account8 = eth.accounts[8];
var account9 = eth.accounts[9];

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
  }
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
}


// -----------------------------------------------------------------------------
// Token Contract
// -----------------------------------------------------------------------------
var tokenContractAddress = null;
var tokenContractAbi = null;

function addTokenContractAddressAndAbi(address, tokenAbi) {
  tokenContractAddress = address;
  tokenContractAbi = tokenAbi;
}


// -----------------------------------------------------------------------------
// Account ETH and token balances
// -----------------------------------------------------------------------------
function printBalances() {
  var token = tokenContractAddress == null || tokenContractAbi == null ? null : web3.eth.contract(tokenContractAbi).at(tokenContractAddress);
  var decimals = token == null ? 18 : token.decimals();
  var i = 0;
  var totalTokenBalance = new BigNumber(0);
  console.log("RESULT:  # Account                                             EtherBalanceChange                Token Name");
  console.log("RESULT: -- ------------------------------------------ --------------------------- -------------------- ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenBalance = token == null ? new BigNumber(0) : token.balanceOf(e).shift(-decimals);
    totalTokenBalance = totalTokenBalance.add(tokenBalance);
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " + padToken(tokenBalance, decimals) + " " + accountNames[e]);
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- -------------------- ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenBalance, decimals) + " Total Token Balances");
  console.log("RESULT: -- ------------------------------------------ --------------------------- -------------------- ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  console.log("RESULT: " + name + " gas=" + tx.gas + " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH +
    " costUSD=" + gasCostUSD + " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + gasPrice + " block=" + 
    txReceipt.blockNumber + " txId=" + txId);
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
// Crowdsale Contract
//-----------------------------------------------------------------------------
var crowdsaleContractAddress = null;
var crowdsaleContractAbi = null;

function addCrowdsaleContractAddressAndAbi(address, abi) {
  crowdsaleContractAddress = address;
  crowdsaleContractAbi = abi;
}

var crowdsaleFromBlock = 0;
function printCrowdsaleContractDetails() {
  console.log("RESULT: crowdsaleContractAddress=" + crowdsaleContractAddress);
  // console.log("RESULT: crowdsaleContractAbi=" + JSON.stringify(crowdsaleContractAbi));
  if (crowdsaleContractAddress != null && crowdsaleContractAbi != null) {
    var contract = eth.contract(crowdsaleContractAbi).at(crowdsaleContractAddress);
    console.log("RESULT: crowdsale.owner=" + contract.owner());
    var startsAt = contract.startsAt();
    console.log("RESULT: crowdsale.startsAt=" + startsAt + " " + new Date(startsAt * 1000).toUTCString());
    var endsAt = contract.endsAt();
    console.log("RESULT: crowdsale.endsAt=" + endsAt + " " + new Date(endsAt * 1000).toUTCString());
  }
}


//-----------------------------------------------------------------------------
// Token Contract
//-----------------------------------------------------------------------------
var tokenFromBlock = 0;
function printTokenContractDetails() {
  console.log("RESULT: tokenContractAddress=" + tokenContractAddress);
  // console.log("RESULT: tokenContractAbi=" + JSON.stringify(tokenContractAbi));
  if (tokenContractAddress != null && tokenContractAbi != null) {
    var contract = eth.contract(tokenContractAbi).at(tokenContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: token.owner=" + contract.owner());
    console.log("RESULT: token.symbol=" + contract.symbol());
    console.log("RESULT: token.name=" + contract.name());
    console.log("RESULT: token.decimals=" + decimals);
    console.log("RESULT: token.totalSupply=" + contract.totalSupply().shift(-decimals));
    console.log("RESULT: token.mintingFinished=" + contract.mintingFinished());
    console.log("RESULT: token.latestAllUpdate=" + contract.latestAllUpdate());
    console.log("RESULT: token.latestContributerId=" + contract.latestContributerId());
    console.log("RESULT: token.maxAddresses=" + contract.maxAddresses());
    console.log("RESULT: token.minMintingPower=" + contract.minMintingPower() + "=" + contract.minMintingPower().shift(-19));
    console.log("RESULT: token.maxMintingPower=" + contract.maxMintingPower() + "=" + contract.maxMintingPower().shift(-19));
    console.log("RESULT: token.halvingCycle=" + contract.halvingCycle());
    var initialBlockTimestamp = contract.initialBlockTimestamp();
    console.log("RESULT: token.initialBlockTimestamp=" + initialBlockTimestamp + " " + new Date(initialBlockTimestamp * 1000).toUTCString());
    console.log("RESULT: token.mintingDec=" + contract.mintingDec());
    console.log("RESULT: token.bounty=" + contract.bounty());
    console.log("RESULT: token.minBalanceToSell=" + contract.minBalanceToSell());
    console.log("RESULT: token.teamLockPeriodInSec=" + contract.teamLockPeriodInSec());
    console.log("RESULT: token.teamTestAdrEndId=" + contract.teamTestAdrEndId());
    console.log("RESULT: token.DayInSecs=" + contract.DayInSecs());
    console.log("RESULT: token.releaseAgent=" + contract.releaseAgent());
    console.log("RESULT: token.released=" + contract.released());
    console.log("RESULT: token.upgradeMaster=" + contract.upgradeMaster());
    console.log("RESULT: token.upgradeAgent=" + contract.upgradeAgent());
    console.log("RESULT: token.totalUpgraded=" + contract.totalUpgraded().shift(-decimals));


    var latestBlock = eth.blockNumber;
    var i;

    var approvalEvents = contract.Approval({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: Approval " + i++ + " #" + result.blockNumber + " owner=" + result.args.owner + " spender=" + result.args.spender + " _value=" +
        result.args.value.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: Transfer " + i++ + " #" + result.blockNumber + ": from=" + result.args.from + " to=" + result.args.to +
        " value=" + result.args.value.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenFromBlock = parseInt(latestBlock) + 1;
  }
}


//-----------------------------------------------------------------------------
// Pricing Contract
//-----------------------------------------------------------------------------
var pricingContractAddress = null;
var pricingContractAbi = null;

function addPricingContractAddressAndAbi(address, abi) {
  pricingContractAddress = address;
  pricingContractAbi = abi;
}

function printPricingContractDetails() {
  console.log("RESULT: pricingContractAddress=" + pricingContractAddress);
  // console.log("RESULT: pricingContractAbi=" + JSON.stringify(pricingContractAbi));
  if (pricingContractAddress != null && pricingContractAbi != null) {
    var contract = eth.contract(pricingContractAbi).at(pricingContractAddress);
    console.log("RESULT: pricing.oneTokenInWei=" + contract.oneTokenInWei() + " wei=" + web3.fromWei(contract.oneTokenInWei(), "ether") + " ETH");
  }
}


//-----------------------------------------------------------------------------
// Finaliser Contract
//-----------------------------------------------------------------------------
var finaliserContractAddress = null;
var finaliserContractAbi = null;

function addFinaliserContractAddressAndAbi(address, abi) {
  finaliserContractAddress = address;
  finaliserContractAbi = abi;
}

function printFinaliserContractDetails() {
  console.log("RESULT: finaliserContractAddress=" + finaliserContractAddress);
  // console.log("RESULT: finaliserContractAbi=" + JSON.stringify(finaliserContractAbi));
  if (finaliserContractAddress != null && pricingContractAbi != null) {
    var contract = eth.contract(finaliserContractAbi).at(finaliserContractAddress);
    console.log("RESULT: finaliser.token=" + contract.token());
    console.log("RESULT: finaliser.totalMembers=" + contract.totalMembers());
    console.log("RESULT: finaliser.testAddressTokens=" + contract.testAddressTokens());
    console.log("RESULT: finaliser.allocatedBonus=" + contract.allocatedBonus());
    console.log("RESULT: finaliser.teamBonus=" + contract.teamBonus());
    console.log("RESULT: finaliser.totalBountyInDay=" + contract.totalBountyInDay());
    console.log("RESULT: finaliser.teamAddresses=" + contract.teamAddresses());
    console.log("RESULT: finaliser.testAddresses=" + contract.testAddresses());
  }
}


