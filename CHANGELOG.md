# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This changelog is based on the release made on [CMTA fork](https://github.com/CMTA/CMTAT-LayerZero).

## [0.1.0] - 2026-01-30

### Added

#### Adapters
- `LayerZeroAdapterERC7802`: OFT adapter for ERC-7802 tokens (`crosschainMint`/`crosschainBurn`)
- `LayerZeroAdapter`: OFT adapter for ERC-3643 tokens (`mint`/`burn`)
- Pause functionality on both adapters

#### Deployment Scripts
- `DeployAdapter.s.sol`: Deploy ERC-7802 adapter
- `DeployAdapterERC3643.s.sol`: Deploy ERC-3643 adapter
- `DeployToken.s.sol`, `WireAdapters.s.sol`, `Mint.s.sol`, `Approve.s.sol`, `SendTokens.s.sol`

#### Tests
- Cross-chain transfer tests
- Deployment verification tests for both adapters
- Shared test utilities (`TestBase.sol`)

### Dependencies
- LayerZero OFT EVM v4.0.1
- OpenZeppelin Contracts v5.5.0
- CMTAT (submodule)
