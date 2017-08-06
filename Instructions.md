## Before starting

* Install `testrpc` and `truffle`.
* Open the cloned Chronologic repository
* Compile contracts:
  ```
  ./node_modules/.bin/truffle compile
  ```
* Start your Ethereum client with Maximum Gas limit and 30 test accounts:
  ```
  ./node_modules/.bin/testrpc -l 999999999999 -a 30
  ```

## Run tests

* Run tests
  ```
  ./node_modules/.bin/truffle test --network testrpc
  ```

## Deploy

* Deploy contracts (choose network from `truffle.js`). The following command deploys up to migration step 2:
  ```
  ./node_modules/.bin/truffle migrate --network testrpc
  ```
  