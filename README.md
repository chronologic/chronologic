
# Day Token [Work in Progress]

- [Chronologic Website](https://chronologic.network)
- [Chronologic Whitepaper](https://chronologic.network/uploads/Chronologic_Whitepaper.pdf)
- [The Big Picture: TimeMints, ChronoPower & Proof-of-Time](https://blog.chronologic.network/the-big-picture-timemints-chronopower-proof-of-time-f881158b044d) blogpost.


## Technical definition
An ERC20 compliant Token &amp; Crowdsale Application on Ethereum Platform written in truffle framework.

At the technical level DayToken is a self-minting ERC20-compliant token. Details about the token can be found in the [Chronologic Whitepaper](https://chronologic.network/uploads/Chronologic_Whitepaper.pdf)

Tests for the token are written using Mocha and Chai framework.

## Contracts

- [AddressCappedCrowdsale.sol](/contracts/AddressCappedCrowdsale.sol): Child contract of Crowdsale.sol, making it address capped
- [BonusFinalizeAgent.sol](/contracts/BonusFinalizeAgent.sol): Child contract of FinalizeAgent.sol. Used to finalize crowdsale
- [ConsenSysWallet.sol](/contracts/ConsenSysWallet.sol): ConsenSys Multi Signature wallet Contract
- [Crowdsale.sol](/contracts/Crowdsale.sol): Main Crowdsale contract.
- [DayToken.sol](/contracts/DayToken.sol): Main contract for the Day Token
- [ERC20.sol](/contracts/ERC20.sol): Standard ERC20 token code
- [ERC20Basic.sol](/contracts/ERC20Basic.sol): Standard ERC20 Basic token code
- [FinalizeAgent.sol](/contracts/FinalizeAgent.sol): Contract code used to finalise crowdsale
- [FlatPricing.sol](/contracts/FlatPricing.sol): Contract to define pricing of DayTokens during Crowdsale
- [Haltable.sol](/contracts/Haltable.sol): Standard Haltable ERC20 token code
- [MintableToken.sol](/contracts/MintableToken.sol): Adds Minting feature to DayToken
- [Ownable.sol](/contracts/Ownable.sol): Standard ERC20 token code for ownership of DayToken
- [PricingStrategy.sol](/contracts/PricingStrategy.sol): Contract responsible for defining the pricing statergy of DayToken during Crowdsale
- [ReleasableToken.sol](/contracts/ReleasableToken.sol): Standard ERC20 token code making the token Releasable
- [SafeMathLib.sol](/contracts/SafeMathLib.sol): Contract responsible for executing all math operations safely
- [StandardToken.sol](/contracts/StandardToken.sol): Standard ERC20 token code
- [UpgradeAgent.sol](/contracts/UpgradeAgent.sol): Defines UpgradeAgent, letting owner upgrade the token code
- [UpgradeableToken.sol](/contracts/UpgradeableToken.sol): Standard ERC20 token code making the token Upgradeable
- [newToken.sol](/contracts/newToken.sol): New code for the upgraded token

See [INSTRUCTIONS.md](/Instructions.md) for instructions on how to test and deploy the contracts.

## Reviewers and audits.

Code for the Day token is being reviewed by:
- [See Audit details here](https://github.com/chronologic/chronologic/tree/dev/audit): Independent External Auditors
