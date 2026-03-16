# CMTAT-LayerZero: Main Points to Understand the Codebase

## 1) Core architecture
- This repo bridges CMTAT tokens across chains through LayerZero OFT adapters.
- Bridging logic is intentionally outside the token contract, inside adapter contracts.
- The key invariant is supply consistency: tokens are debited on source and credited on destination.

## 2) Adapter variants
- `src/LayerZeroAdapter.sol`: ERC-3643-compatible mint/burn adapter (`IMintableBurnable`).
- `src/LayerZeroAdapterERC7802.sol`: ERC-7802 adapter (`crosschainBurn` / `crosschainMint`).
- `src/LayerZeroAdapterOwnable2Step.sol`: ERC-3643 adapter with `Ownable2Step`.
- `src/LayerZeroAdapterERC7802Ownable2Step.sol`: ERC-7802 adapter with `Ownable2Step`.

## 3) Access and security model
- Adapters are owner-managed OApps (LayerZero peer/delegate settings are owner-gated).
- `src/modules/PauseModule.sol` provides emergency `pause()` / `unpause()` hooks.
- Pause authorization is delegated to adapter `_authorizePause()` and currently owner-only.
- Required token roles:
  - ERC-7802 adapters: `CROSS_CHAIN_ROLE`.
  - ERC-3643 adapters: `MINTER_ROLE` + `BURNER_ROLE`.

## 4) Test structure
- Shared helpers are in `test/utils/TestBase.sol` (token/adapter deployment + role checks).
- `test/DeployAdapter.t.sol` validates deployment assumptions and role wiring.
- `test/SendTokens.t.sol` validates end-to-end send, pause behavior, and access checks.
- `test/Ownable2StepAdapters.t.sol` validates two-step ownership flows on new variants.

## 5) Scripts and ops flow
- Deploy scripts are in `script/`:
  - `DeployAdapter.s.sol` (ERC-7802)
  - `DeployAdapterERC3643.s.sol` (ERC-3643)
  - `WireAdapters.s.sol` (peer wiring)
  - `Approve.s.sol` and `SendTokens.s.sol` for token approval/send operations.
- `deployments.json` stores per-chain deployed addresses used by scripts.

## 6) Practical reading order
1. `README.md` for workflow and assumptions.
2. Adapter contracts in `src/`.
3. `PauseModule` and ownership model.
4. `test/utils/TestBase.sol` then tests in `test/`.
5. Deployment/wiring scripts in `script/`.
