# CMTAT LayerZero Integration

A comprehensive integration of CMTAT (Capital Markets and Technology Association Token) with [LayerZero](https://layerzero.network) Protocol for seamless cross-chain token transfers. This project enables CMTAT tokens to be bridged across multiple blockchain networks using [LayerZero's OFT](https://docs.layerzero.network/v2/developers/evm/oft/quickstart) (Omnichain Fungible Token) standard. 

> **Note**: This project has not undergone an audit and is provided as-is without any warranties.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Deployment Guide](#deployment-guide)
- [Usage](#usage)
- [Tracking Transactions](#tracking-transactions)
- [Project Structure](#project-structure)
- [Scripts Reference](#scripts-reference)

## Overview

This project provides a LayerZero adapter for [CMTAT](https://github.com/CMTA/CMTAT/) tokens, enabling cross-chain transfers between supported networks. The adapter implements the OFT (Omnichain Fungible Token) standard, allowing tokens to be burned on the source chain and minted on the destination chain.

### Key Features

- **Cross-Chain Token Transfers**: Seamlessly bridge CMTAT tokens between different blockchain networks
- **LayerZero Integration**: Built on LayerZero V2 protocol for secure and efficient cross-chain messaging
- **CMTAT Compatibility**: Full integration with CMTAT's cross-chain burn/mint functionality build on [ERC-7802](https://eips.ethereum.org/EIPS/eip-7802)
- **Automated Scripts**: Ready-to-use Foundry scripts for deployment and operations

## Prerequisites

Before you begin, ensure you have the following installed:

- CMTAT [v3.2.0-rc0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0-rc0)
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest version)
- [Node.js](https://nodejs.org/) (v18 or higher)
- [pnpm](https://pnpm.io/) (v10.13.1 or higher)

### Environment Variables

> Don't use it for production, only for testing.
> See [getfoundry.sh - Key Management](https://getfoundry.sh/guides/best-practices/key-management/)  to securely broadcasting transactions through a script.

Create a `.env` file by running `cp .env.example .env` in the root directory with the following variables:

```bash
PRIVATE_KEY=your_private_key_here
ETHERSCAN_TOKEN=your_etherscan_api_key_here
```

## Installation

1. **Clone the repository** (including submodules):

```bash
git clone <repository-url>
cd CMTAT-LayerZero
```

2. **Install dependencies**:

```bash
pnpm install
```

3. **Build the project**:

```bash
forge build
```

## Configuration

### Foundry Configuration

The project uses Foundry with the following key settings in `foundry.toml`:

- **Solidity Version**: [0.8.33](https://docs.soliditylang.org/en/v0.8.33/)
- **EVM Version**: Prague
- **Optimizer Runs**: 200
- **Sparse Mode**: Enabled (for faster compilation)
- **Via Ir**: Disabled

### RPC Endpoints

RPC endpoints are configured in `foundry.toml`. You can add or modify endpoints in the `[rpc_endpoints]` section:

```toml
[rpc_endpoints]
mainnet-sepolia = "https://ethereum-sepolia-rpc.publicnode.com"
arbitrum-sepolia = "https://arbitrum-sepolia.gateway.tenderly.co"
```

### Chain Configuration

Chain-specific settings (LayerZero endpoints and EIDs) are defined in `script/utils/Constants.sol`. To add a new chain:

1. Add the LayerZero endpoint address
2. Add the corresponding EID (Endpoint ID)
3. Update the mappings in the `Constants` contract

## Deployment Guide

> Each command first asks for the chain name. You can use the chain names defined in `foundry.toml`.

### Step 1: Deploy CMTAT Token

Deploy the CMTAT token on your source chain:

```bash
pnpm run deploy:token -- --broadcast --verify
```

This will:

- Deploy a new `CMTATStandalone` token contract
- Set you as the admin
- Save the deployment address to `deployments.json`

### Step 2: Deploy LayerZero Adapter

Deploy the LayerZero adapter on the same chain:

```bash
pnpm run deploy:adapter -- --broadcast --verify
```

This will:

- Deploy the `LayerZeroAdapter` contract
- Link it to your CMTAT token
- Grant the `CROSS_CHAIN_ROLE` to the adapter
- Save the adapter address to `deployments.json`

### Step 3: Repeat Steps 1 and 2 for Other Chains

### Step 4: Wire Adapters

Connect the adapters on both chains so they can communicate:

**On source chain (e.g., arbitrum-sepolia):**

```bash
pnpm run wire -- --broadcast --verify
```

**On destination chain (e.g., mainnet-sepolia):**

```bash
pnpm run wire -- --broadcast --verify
```

This sets up peer connections between the adapters, enabling cross-chain communication.

## Usage

### Minting Tokens

Mint tokens on a specific chain:

```bash
pnpm run token:mint -- --broadcast
```

### Approving Tokens (if relevant)

> CMTAT Standard version does not require approval to perform burn/mint or crosschainmint/crosschainburn.
>
> This step is only useful if this project is used with a CMTAT version requiring the standard ERC-20 approval.

Approve the adapter to spend your tokens (required before bridging):

```bash
pnpm run token:approve -- --broadcast
```

### Bridging Tokens

Send tokens from one chain to another:

```bash
pnpm run bridge -- --broadcast
```

This will:

1. Calculate the required LayerZero messaging fee
2. Burn tokens on the source chain
3. Send a cross-chain message via LayerZero
4. Mint tokens on the destination chain (after message delivery)

**Note**: The amount is specified without decimals. The script automatically applies the token's decimal places (6 decimals in this case).

## Tracking Transactions

### LayerZero Scan

All cross-chain transactions can be tracked on [LayerZero Scan](https://testnet.layerzeroscan.com/):

1. **Find your transaction**: Search by transaction hash from the source chain
2. **Monitor status**: Track the message delivery status
3. **View details**: See source/destination chains, amounts, and fees

**Example contracts**: [deployments.json](./deployments.json)

**Example transaction**: [testnet.layerzeroscan.com/tx/0xd2182b0094d015e6670539e9206bbb141d69c1c179e5a544c1b24d6d8e10c84f](https://testnet.layerzeroscan.com/tx/0xd2182b0094d015e6670539e9206bbb141d69c1c179e5a544c1b24d6d8e10c84f)

Made with CMTAT [v3.1.0](https://github.com/CMTA/CMTAT/releases/tag/v3.1.0)

### Transaction Flow

1. **Source Chain**:

   - Tokens are burned via `crosschainBurn()`
   - LayerZero message is sent with destination details
   - Native gas fee is paid for cross-chain messaging

2. **LayerZero Network**:

   - Message is relayed through LayerZero's infrastructure
   - Delivery is verified by DVNs (Decentralized Verifier Networks)

3. **Destination Chain**:

   - Message is received by the adapter
   - Tokens are minted via `crosschainMint()`
   - Recipient receives the tokens

## Project Structure

```
CMTAT-LayerZero/
├── src/
│   └── LayerZeroAdapter.sol      # Main adapter contract
├── script/
│   ├── DeployToken.s.sol         # Deploy CMTAT token
│   ├── DeployAdapter.s.sol       # Deploy LayerZero adapter
│   ├── WireAdapters.s.sol        # Connect adapters across chains
│   ├── Mint.s.sol                # Mint tokens
│   ├── Approve.s.sol             # Approve adapter spending
│   ├── SendTokens.s.sol          # Bridge tokens cross-chain
│   └── utils/
│       ├── BaseScript.s.sol      # Base script utilities
│       ├── Constants.sol         # Chain configuration
│       └── FileHelpers.sol       # Deployment file management
├── lib/
│   ├── CMTAT/                    # CMTAT token contracts (submodule)
│   └── forge-std/                # Foundry standard library
├── test/                         # Test files
├── deployments.json              # Deployment addresses
├── foundry.toml                  # Foundry configuration
└── package.json                  # Node.js dependencies
```

## Scripts Reference

### Available Scripts

All scripts can be run using Foundry's `forge script` command. Here's a quick reference:

| Script          | Purpose                  | Example                                                                                                     |
| --------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `DeployToken`   | Deploy CMTAT token       | `forge script DeployToken -s "exec(string)" arbitrum-sepolia --broadcast`                                   |
| `DeployAdapter` | Deploy LayerZero adapter | `forge script DeployAdapter -s "exec(string)" arbitrum-sepolia --broadcast`                                 |
| `WireAdapters`  | Connect adapters         | `forge script WireAdapters -s "exec(string,string)" arbitrum-sepolia mainnet-sepolia --broadcast`           |
| `Mint`          | Mint tokens              | `forge script Mint -s "exec(string,uint256)" arbitrum-sepolia 1000 --broadcast`                             |
| `Approve`       | Approve adapter          | `forge script Approve -s "exec(string)" arbitrum-sepolia --broadcast`                                       |
| `SendTokens`    | Bridge tokens            | `forge script SendTokens -s "exec(string,string,uint256)" arbitrum-sepolia mainnet-sepolia 100 --broadcast` |

### Script Parameters

- **Chain names**: Use the chain names defined in `foundry.toml` (e.g., `arbitrum-sepolia`, `mainnet-sepolia`)
- **Amounts**: Specify amounts without decimals (the script applies decimals automatically)
- **Broadcast flag**: Use `--broadcast` to actually send transactions (omit for dry-run)

## Security Considerations

1. **Private Keys**: Never expose your private keys. The `.env` file here used in this project should not be used for production. See [getfoundry.sh - Key Management](https://getfoundry.sh/guides/best-practices/key-management/)
2. **Gas Fees**: Ensure you have sufficient native tokens for gas and LayerZero messaging fees
3. **Approvals**: Only approve the adapter when necessary, and consider using time-limited approvals
4. **Testing**: Always test on testnets before deploying to mainnet
5. **Access Control**: The adapter requires `CROSS_CHAIN_ROLE` on the CMTAT token - ensure proper access control

## Troubleshooting

### Common Issues

**Issue**: "Insufficient funds" when bridging

- **Solution**: Ensure you have enough native tokens for both gas and LayerZero messaging fees

**Issue**: Tokens not arriving on destination chain

- **Solution**: Check LayerZero Scan to see if the message was delivered. Delivery can take a few minutes.

## Additional Resources

- [LayerZero Documentation](https://docs.layerzero.network/)
- [CMTAT Documentation](https://github.com/CMTA/CMTAT)
- [Foundry Book](https://book.getfoundry.sh/)
- [LayerZero Scan](https://testnet.layerzeroscan.com/)

## Contributing

Contributions are welcome! Please ensure your code follows the project's style guidelines and includes appropriate tests.
