# TrueFund

A blockchain-based donation platform for transparent, direct giving to verified recipients such as charities, mosques, or individuals in need. Built as a learning project to explore smart contract development, security, and best practices.

## 🚀 Project Overview

TrueFund allows an admin to register recipient wallets for organizations. Donors can send ETH directly to these wallets, with every donation tracked on-chain via events. Funds never stay in the contract, ensuring maximum transparency and trust.

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
