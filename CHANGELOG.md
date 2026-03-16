# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This changelog is based on the release made on [CMTA fork](https://github.com/CMTA/CMTAT-LayerZero).

## [0.3.0]

### Added

#### Adapters
- `LayerZeroAdapterOwnable2Step`: ERC-3643 (`IMintableBurnable`) adapter with two-step ownership transfer
- `LayerZeroAdapterERC7802Ownable2Step`: ERC-7802 adapter with two-step ownership transfer

#### Deployment Scripts
- `DeployAdapterOwnable2Step.s.sol`: Deploy ERC-7802 adapter using `Ownable2Step`
- `DeployAdapterERC3643Ownable2Step.s.sol`: Deploy ERC-3643 adapter using `Ownable2Step`

#### Tests
- `Ownable2StepAdapters.t.sol`: Coverage for ownership transfer flow, pending owner behavior, and owner-gated pause permissions on both new adapter variants

### Changed

- Update CMTAT library to CMTAT [v3.2.0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0)
- Update OpenZeppelin Contracts to v5.6.0
- Update Solidity version to 0.8.34
- Update `README.md` with:
  - Adapter ownership model documentation (`Ownable` vs `Ownable2Step`)
  - Deployment options for `Ownable2Step` adapter scripts
  - Updated project structure and script/test references
- Update `TestBase.sol` with `_deployAdapterERC7802Ownable2Step()` and `_deployAdapterERC3643Ownable2Step()` helpers

## [0.2.0]

Commit: `8f4938027766af8d1a38c0884835316411d1e522`

### Changed

- Update README
- Update CMTAT library to CMTAT [v3.2.0-rc2](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0-rc2)

## [0.1.0]

### Added

#### Adapters
- `LayerZeroAdapterERC7802`: OFT adapter for ERC-7802 tokens (`crosschainMint`/`crosschainBurn`)
- `LayerZeroAdapter`: OFT adapter for ERC-3643 tokens (`mint`/`burn`)
- Pause functionality on both adapters through `PauseModule`

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
