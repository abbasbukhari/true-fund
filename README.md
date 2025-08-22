## �️ Full GUI Interface

TrueFund will feature a complete web-based graphical user interface (GUI) built with React.js. The frontend will allow users to:

- Connect their wallet
- Select a recipient and currency
- Enter donation amount in their local currency
- View donation history and transparency data
- Admins can manage recipients and supported currencies

The frontend will follow industry standards for web3 integration and user experience.

### Development Best Practice

It’s recommended to build and test the smart contract first, ensuring all core logic and events work as expected. Once the contract is stable, you can develop the frontend and integrate it with the contract. However, you can also prototype the frontend in parallel for faster iteration, especially if you want to test UI ideas early. Most professional teams build the contract first, then the frontend, but learning projects can be flexible!

## �📋 Planning & User Stories

### User Stories

- As an admin, I want to register and manage recipient wallets for organizations so only verified recipients can receive donations.
- As a donor, I want to donate in my local currency (USD, CAD, GBP, HKD, PKR, etc.) so I know exactly how much I’m giving.
- As a donor, I want my donation to go directly to the recipient’s wallet, not stay in the contract, for maximum transparency. Only the intended recipient can receive and access the funds—no one else (not even the admin) can withdraw or access donations.
- As a user, I want to see a public, verifiable history of all donations for trust and accountability.
- As an admin, I want to easily add support for new currencies and price feeds as the project grows.

### Planning Breakdown

**Admin Functions:**

- Register recipient wallets
- Remove recipient wallets
- Add/remove price feeds for supported currencies

**Donation Functions:**

- Donate to a recipient in any supported currency
- Convert local currency amount to ETH using price feeds

**Events:**

- Emit events for every donation, recipient registration/removal, and price feed changes

**View Functions:**

- Get recipient details
- List supported currencies
- Get price feed addresses

**Access Control:**

- Only admin can manage recipients and price feeds

---

# TrueFund

A blockchain-based donation platform for transparent, direct giving to verified recipients such as charities, mosques, or individuals in need. Built as a learning project to explore smart contract development, security, and best practices.

## 🚀 Project Overview

TrueFund allows an admin to register recipient wallets for organizations. Donors can send their local currencies directly to these wallets, with every donation tracked on-chain via events. Funds never stay in the contract, ensuring maximum transparency and trust. Only the intended recipient receives the donation—no one else can withdraw or access the funds.

### 🌍 Multi-Currency Donation Support

Donors can donate using their local currencies. The contract uses Chainlink price feeds to convert local currency amounts to the required ETH value. Supported currencies at launch:

- USD (ETH/USD)
- CAD (ETH/CAD)
- GBP (ETH/GBP)
- HKD (ETH/HKD)
- PKR (ETH/PKR)

The contract is designed to easily add more price feeds and currencies as the project grows.

## ✨ Features

- Admin can register verified recipient wallets
- Donors send ETH directly to recipients
- Donors can specify donation amount in their local currency (ETH value calculated via price feed)
- Every donation emits an on-chain event for transparency
- No funds held in the contract
- Public, verifiable donation history
- Easily extensible to support more currencies and price feeds

## 🛠️ Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
2. Clone this repository:
   ```sh
   git clone <your-repo-url>
   cd true-fund
   forge install
   ```
3. Create a `.env` file for RPC URLs and private keys (if needed)

## 🧪 Usage

- Build contracts:
  ```sh
  forge build
  ```
- Run tests:
  ```sh
  forge test
  ```
- Deploy contracts (example):
  ```sh
  forge script script/DeployTrueFund.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
  ```

## 🎯 Learning Objectives

- Practice smart contract architecture and security
- Implement transparent donation logic
- Use events for on-chain tracking
- Explore admin and access control patterns
- Learn best practices for Solidity and Foundry

## 📚 Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Chainlink Docs](https://docs.chain.link/)

---

**Status:** 🟡 Learning in Progress

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
