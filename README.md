# Distbit Blockchain
> tools to integrate Blockchain ETH layer.

## Installation

OS X & Linux:

```sh
npm install
```

## Usage

#### Wallets

Wallet creation.

Wallets folder contains files for Ethereum services

config.js contains configuration for wallets services

main.js contains samples for call ethereum services


Sample wallet creation:

```sh
{ 
    address: "0xb463470f77418dfd1a9a6404a171075fafa4da4a",
    public_key: "0xb463470f77418dfd1a9a6404a171075fafa4da4a",
    private_key: "66ddd1e06b466eae6df499b5cbf9651e7433348afabb8146b287a1f73700d5ac"
}
```

_For more examples and usage, please refer to the [Wiki][wiki]._

#### Contracts

Instance contract Trato master:

```js
let trato = await Trato.deployed()
```
 
#### Description of contracts base

##### ContractCharge.sol
Balance charge to the contract to be able to carry out the dispersion, this charge is made from the wallet that owns the contract and emits a Charge type event

```js
// Send ETH to contract address
trato.send(web3.utils.toWei("4","ether"), trato.address);
```

##### PaymentGateway.sol
Our payment gateway will have a few basic features:
* It should create an OpenZeppelin escrow contract.
* It should accept payments and send them to the escrow contract.
* It should allow the owner of the gateway to withdraw funds from the escrow to a wallet.
* It should allow the owner of the gateway to view the balance they can withdraw.

Basically, if you call transfer inside another function, an attacker could create a contract that causes the function to fail and potentially wreak havoc on your contract. If you call it in a separate withdrawal function, the attacker cannot abuse any other part of your contract.
Balance of operations using this Contract **is not public**.

```js
// Send ETH from user to contract address
trato.sendPayment({ from: "0x...", value: web3.utils.toWei("10", "ether") })
// Withdraw all balance to owner wallet
trato.withdraw()
// Return BN contract balance
trato.balance()
```

##### Member.sol
Contract in charge of registering, registering, verifying the information of the members of the contract, as well as listing all the members of the contract

```js
// Register new user on contract
trato.registerMember("0x.....")
// Add approvation from member to contract [need to execute with member key pairs]
trato.signMember()
// Returns ID, percent from member
trato.getMember("0x.....")
// Get list of all wallets in contract
trato.getMembers()
```

##### Time.sol
Contract to modify and evaluate contract start and closing dates, it has 5 functions:
* stablish contract time
* Obtain the contract execution date
* Obtain the contract end date based on the date of execution.

The execution date is different from the contract creation date, this date is automatic when the contract starts


Validations required for time lapseds:
**To reduce gas it is necessary to carry out several verifications before writing about the contract**.
For example:
If duration of contract is 2  months, lapseds cant be greater than 2 months

Duration: 2 months
God: Lapsed 5 days, 10 days, 1 month
Bad: Lapsed 1 year, 70 days, 3 moths

And

Verify sum of percent === 100

```js
// Set time of contrat (units, [month, day, year])
trato.setEnd(4, web3.utils.fromAscii("day"))
/*
Set time lapseds for dispersions (percents, every, unit)
- percents: [10, 10, 80] sum of the arrangement should give 100
- every: unit for dispersions, for example every 5 days
- unit: unit of time [day, month, year]
*/
trato.setLapseds([10, 10, 10, 70], 2, web3.utils.fromAscii("day"))
// Get [year, month, day] of execution start, throw error if contrat not start
trato.getStart()
// Get [year, month, day] of execution end, throw error if contrat not start
trato.getEnd()
// Get [year, month, day] of next payments, throw error if contrat not start
trato.getNextPayment()
```


##### EventDispersion.sol
Contract for event dispersion
Run a payment when an event is logged

```js
// Create event
trato.createEvent(web3.utils.fromAscii("event"));
// Execute event
trato.executeEvent();
```
When the execution of the event is called, the contract will spread the payments and the status will be changed to finalized



##### TimeDispersion.sol
Contract for dispersion
This is an automated contract
* Receive ethers for dispersion
* Calculate amount from percent in lapsed time and percent from user
* Save and send the previously calculated amount safely

```js
// Sample
_escrow.deposit{ value: _amount }(_to);
_escrow.withdraw(payable(_to));
```

##### ClauseDispersion.sol
Contract by clauses, which allows the following actions
* Create custom clauses
    * Set conditions for contract
    * Dispersion in clause execution
* Disperse on all clauses execution

Clause:
Properties:
* id
* type
* name
* conditions [Condition] (Conditions of clause)
* pay [Pay] (Information for payments)
* receiver
* executed

Pay
* pay on executed (**Pay when clause is executed**)
* amount (Amount for dispersion)

Condition
* prop (**id for property for conditions**)
* executed (Amount for dispersion)
* member (Assignment of obligation)

When a condition is executed, it is evaluated if all the conditions of the clause were met, if the condition is met, payment is made if a payment is registered in it.

If the setOnAll parameter is true, the payment will be made when all the clauses have been executed.

```js
// Create event [type of clause, name of clause, pay on execution clause]
trato.createClause(web3.utils.fromAscii("type"), web3.utils.fromAscii("name"), true);
// if pay on execution clause is true [position clause, amount, receiver of payment[member]]
trato.setClausePay(0, web3.utils.toWei("1", "ether"), "0x58...");
// add new condition to clause[position clause, responsable, uuid for description]
trato.addCondition(0, "0x58..", web3.utils.fromAscii("uuidv4"))
// set pay on all execution
trato.setOnAll(true)
// remove clause by position[position cluase]
trato.removeClause(0)
// remove condition by position [position cluase, position condition]
trato.removeCondition(0, 0)
//execute condition[position cluase, position condition]
trato.executeCondition(0, 0)
```

**Condition is only representation from a real text when prop is and id fron catalog**

**Is an bad practice store large strings on contract, that's why only a reference identifier to a catalog is stored**


##### Trato.sol
Master Contract

```js
// Register contract hash
trato.setHash("hash")
// Get contract hash
trato.getHash()
```

## Contract state
Contracts often act as a state machine, which means that they have certain stages in which they behave differently or in which different functions can be called. A function call often ends a stage and transitions the contract into the next stage (especially if the contract models interaction). It is also common that some stages are automatically reached at a certain point in time.

Current stages:

* CREATION
* SIGN
* RUNNING
* FINISH

**Creation**: Owner can modify balance of contract, add members, set duration of contract and set lapseds

**Sign**: Members start sign contract, ant start this stage if time or balance of contract is not set

**Running**: Contract execution (payment dispersion)

**Finish**: Contract finish (destroy)



## Contract flow

* Deploy contract
* Send total amount of Ethers to contract
```js
trato.send(web3.utils.toWei("5","ether"), trato.address);
```
* Register members to contract [address, percent] (If percent is equal to 0, the percentage will be calculated automatically based on the existing ones)
**Percent sum must always be equal to 100**
```js
trato.registerMember('0x81...', 10)
trato.registerMember('0x82...', 10)
trato.registerMember('0x83...', 10)
trato.registerMember('0x84...', 0) // automatically set to 70
```
* Set duration of contract
```js
trato.setEnd(4, web3.utils.fromAscii("month"))
```
* Set time lapseds [percents, value, unit],
```js
/*
 * First month 10 % of total of ethers
 * Second month 10 % of total of ethers
 * Third month 10 % of total of ethers
 * Fourth month 70 % of total of ethers
 */
trato.setLapseds([10, 10, 10, 70], 1, web3.utils.fromAscii("month"))
```

Another sample:

Contracts starts on January
```js
/*
 * March month 20 % of total of ethers
 * May month 20 % of total of ethers
 * Jul month 20 % of total of ethers
 * September month 40 % of total of ethers
 */
trato.setLapseds([20, 20, 20, 40], 2, web3.utils.fromAscii("month"))
```
* Sign members
This call must be executed from the wallet of the person to sign
```js
trato.signMember()
```

* Register hash
```js
trato.setHash("***")
```

* Start contract
This call is automatically executed when all contract members signed
```js
exec()
```

## Execution sample time dispersion

Data: 
**Amount for dispersion:** 5 ETH
* **Members:** 
[0x846a1c878BceDC8FFbD30fB1ff49D98A59928161, 0x422D9074138a5D4F9Ea2F9557dA96dDB39667A8D,
0xBbfF0da113e085063a08472f818b492779FF4753,
0x132d96EA49249A9317ecDeAe8865E3560F3dAd86]
* **Members percent:** [10, 10, 10, 0]
* **Duration:** 3 days
* **Lapsed percents:** [10, 10, 70]

Final balance of contract on first payment:

![Contract balance](https://i.ibb.co/dpfFmKJ/Captura-de-Pantalla-2020-06-03-a-la-s-20-37-42.png)


Balance of members on first payment:

![Contract balance](https://i.ibb.co/hFSKH0V/Captura-de-Pantalla-2020-06-03-a-la-s-20-41-55.png)



## Price

Price for contract deployment
Total deployments:   2
Final cost:          0.01327631 ETH - **3.2 USD**

## Development setup

Describe how to install all development dependencies and how to run an automated test-suite of some kind. Potentially do this for multiple platforms.

```properties
npm i
node main.js
```

## Deeploys testing

* **Time**: [0xFc7c2Ac029B3D340DcAf668F7cCbE7101a3315b8](https://ropsten.etherscan.io/address/0xFc7c2Ac029B3D340DcAf668F7cCbE7101a3315b8)

* **Clauses**: [0x2978d6D2287ab0491af2774a2233e9b629BdC5d0](https://ropsten.etherscan.io/address/0x2978d6D2287ab0491af2774a2233e9b629BdC5d0)

* **Event**: [0x14ae19c7c02c2Bd3063c9A8f2F1372c309579de3](https://ropsten.etherscan.io/address/0x14ae19c7c02c2Bd3063c9A8f2F1372c309579de3)


Every contract has function typeContract() for get contract type. (**result in bytes**)

## Release History

* 0.0.1
    * Work in progress

## Meta

Miguel Angel – [@xellDart](https://github.com/xellDart) – mundorap2010@gmail.com

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/feature`)
5. Create a new Pull Request

<!-- Markdown link & img dfn's -->
[npm-image]: https://img.shields.io/npm/v/datadog-metrics.svg?style=flat-square
[npm-url]: https://npmjs.org/package/datadog-metrics
[npm-downloads]: https://img.shields.io/npm/dm/datadog-metrics.svg?style=flat-square
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[wiki]: https://github.com/yourname/yourproject/wiki
