# AI Agent Based Automatic DeFi Yield Rebalancer

(concept project to demonstrate tokensource agent design, do not try on mainnet)

## Overview

This project is a Solidity-based smart contract for automated yield rebalancing across different DeFi protocols. It focuses on Aave v3 integration and compatibility with Safe smart accounts. The contract optimizes yield by automatically shifting funds between liquidity pools based on predefined parameters while considering tax implications through adjustable rebalancing thresholds.

## Key Features

- **Automated Yield Optimization:** Monitors and rebalances funds between liquidity pools based on APY differences.
- **Aave v3 Integration:** Seamlessly supports deposits, withdrawals, borrowing, and repaying within Aave v3.
- **Safe Smart Account Compatibility:** Executes transactions via a Safe multisig wallet for enhanced security.
- **Configurable Rebalancing:** Allows setting thresholds for minimum APY differences and safety margins to control frequency and risk.
- **Tax-Aware Design:** Includes mechanisms to adjust rebalancing triggers to mitigate tax impacts.
- **Oracle-Based APY:** Utilizes Chainlink oracles for real-time APY data.
- **Modular Architecture:** Features clean interfaces for easy expansion and customization.

## Agent Elements in the System

The system contains several components that can be considered "agents," performing distinct roles:

1. **Smart Contract Acting as an Agent:**
   - The `YieldRebalancer` contract itself acts as an “agent,” automating yield optimization by monitoring and shifting funds across liquidity pools based on predefined logic.

2. **Chainlink Oracle as an Information Agent:**
   - The oracle-based APY retrieval serves as an information agent, fetching real-time data from external sources for decision-making (`getPoolApyFromOracle`).

3. **Safe Smart Account:**
   - The Safe multisig wallet functions as a governance agent, ensuring secure and approved execution of critical transactions.

4. **Rebalancing Logic:**
   - The rebalancing mechanism in the contract (triggered by functions like `executeRebalance`) acts as an operational agent, dynamically managing liquidity between pools based on APY differences and defined thresholds.

## Technical Architecture

The core of the project is a Solidity smart contract named `YieldRebalancer`, designed with the following structure:

1. **Liquidity Pool Management:** Manages pool information using a `LiquidityPool` struct.
2. **APY Tracking:** Retrieves APY data via Chainlink oracles using the `AggregatorV3Interface`.
3. **Rebalancing Logic:** Triggers rebalancing based on APY differences and predefined thresholds.
4. **Aave Integration:** Interfaces with Aave v3 using `ILendingPool` and `IDataProvider`.
5. **Safe Compatibility:** Executes transactions through `Safe.sol` for multisig approval.
6. **Configurable Parameters:** Offers adjustable settings such as `minRebalanceThreshold`, `safetyMarginApplied`, and pool configurations.

## Smart Contract Details

### Key Functions

- **`registerLiquidityPool`**: Registers a liquidity pool with its details (ID, name, token address, oracle, and type).
- **`updatePoolBalance`**: Updates the balance of a liquidity pool.
- **`updatePoolApyOracle`**: Updates the oracle address for a specific liquidity pool.
- **`setMinRebalanceThreshold`**: Sets the minimum APY difference to trigger rebalancing.
- **`setSafetyMarginApplied`**: Configures the safety margin to account for slippage.
- **`depositToAave`**: Deposits a specified amount into Aave.
- **`withdrawFromAave`**: Withdraws a specified amount from Aave.
- **`borrowFromAave`**: Borrows a specified amount from Aave.
- **`repayToAave`**: Repays a specified amount to Aave.
- **`executeRebalance`**: Rebalances funds between two liquidity pools.
- **`getPoolApyFromOracle`**: Fetches APY data from a Chainlink oracle.
- **`getPoolDetails`**: Retrieves details of a specific pool.
- **`getAllPoolIds`**: Lists all registered pool IDs.
- **`getMinRebalanceThreshold`**: Returns the minimum APY threshold.
- **`getSafetyMarginApplied`**: Retrieves the configured safety margin.
- **`getLastRebalanceTime`**: Gets the timestamp of the last rebalance.

### Dependencies

- **Solidity Compiler:** Version 0.8.0 or higher.
- **Safe Contracts:** `@safe-global/safe-contracts` for Safe account integration.
- **Chainlink Contracts:** `@chainlink/contracts` for oracle integration.

## Getting Started

### Prerequisites

- **Node.js and npm/yarn**: For dependency installation.
- **Hardhat or Foundry**: For development, testing, and deployment.
- **Wallet**: Metamask or similar for contract interaction.
- **Safe Account**: Required for multisig control.
- **Testnet ETH**: For testing on test networks.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tokensource/yield-rebalancer-agent
   cd yield-rebalancer-agent
