// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {LayerZeroAdapter} from "../../src/LayerZeroAdapter.sol";
import {LayerZeroAdapterERC7802} from "../../src/LayerZeroAdapterERC7802.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {ICMTATConstructor} from "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import {IERC1643CMTAT} from "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import {IRuleEngine} from "CMTAT/interfaces/engine/IRuleEngine.sol";

import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

/**
 * @title TestBase
 * @notice Shared test utilities for CMTAT LayerZero adapter tests
 * @dev Provides internal helper functions for deploying tokens and adapters
 */
abstract contract TestBase is Test, TestHelperOz5 {
    // ============ Internal Helpers: CMTAT Token ============

    /**
     * @notice Deploy a CMTAT token
     * @param admin The admin address
     * @param name Token name
     * @param symbol Token symbol
     * @param decimals Token decimals
     * @return cmtat The deployed CMTAT token
     */
    function _deployCMTAT(address admin, string memory name, string memory symbol, uint8 decimals)
        internal
        returns (CMTATStandalone cmtat)
    {
        cmtat = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes(name, symbol, decimals),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );
    }

    /**
     * @notice Deploy a CMTAT token with default settings (6 decimals)
     * @param admin The admin address
     * @param name Token name
     * @param symbol Token symbol
     * @return cmtat The deployed CMTAT token
     */
    function _deployCMTAT(address admin, string memory name, string memory symbol)
        internal
        returns (CMTATStandalone cmtat)
    {
        return _deployCMTAT(admin, name, symbol, 6);
    }

    // ============ Internal Helpers: ERC-7802 Adapter ============

    /**
     * @notice Deploy ERC-7802 adapter and grant CROSS_CHAIN_ROLE
     * @param cmtat The CMTAT token
     * @param endpoint The LayerZero endpoint
     * @param admin The admin/delegate address
     * @return adapter The deployed adapter
     */
    function _deployAdapterERC7802(CMTATStandalone cmtat, address endpoint, address admin)
        internal
        returns (LayerZeroAdapterERC7802 adapter)
    {
        adapter = new LayerZeroAdapterERC7802(address(cmtat), endpoint, admin);
        cmtat.grantRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter));
    }

    /**
     * @notice Deploy ERC-7802 adapter without granting roles
     * @param cmtat The CMTAT token
     * @param endpoint The LayerZero endpoint
     * @param admin The admin/delegate address
     * @return adapter The deployed adapter
     */
    function _deployAdapterERC7802NoRoles(CMTATStandalone cmtat, address endpoint, address admin)
        internal
        returns (LayerZeroAdapterERC7802 adapter)
    {
        adapter = new LayerZeroAdapterERC7802(address(cmtat), endpoint, admin);
    }

    // ============ Internal Helpers: ERC-3643 Adapter ============

    /**
     * @notice Deploy ERC-3643 adapter and grant MINTER_ROLE and BURNER_ROLE
     * @param cmtat The CMTAT token (also used as minterBurner)
     * @param endpoint The LayerZero endpoint
     * @param admin The admin/delegate address
     * @return adapter The deployed adapter
     */
    function _deployAdapterERC3643(CMTATStandalone cmtat, address endpoint, address admin)
        internal
        returns (LayerZeroAdapter adapter)
    {
        // For CMTAT, the minterBurner is the token itself
        adapter = new LayerZeroAdapter(address(cmtat), address(cmtat), endpoint, admin);
        cmtat.grantRole(cmtat.MINTER_ROLE(), address(adapter));
        cmtat.grantRole(cmtat.BURNER_ROLE(), address(adapter));
    }

    /**
     * @notice Deploy ERC-3643 adapter without granting roles
     * @param cmtat The CMTAT token (also used as minterBurner)
     * @param endpoint The LayerZero endpoint
     * @param admin The admin/delegate address
     * @return adapter The deployed adapter
     */
    function _deployAdapterERC3643NoRoles(CMTATStandalone cmtat, address endpoint, address admin)
        internal
        returns (LayerZeroAdapter adapter)
    {
        adapter = new LayerZeroAdapter(address(cmtat), address(cmtat), endpoint, admin);
    }

    // ============ Internal Helpers: Role Verification ============

    /**
     * @notice Verify ERC-7802 adapter has required roles
     * @param cmtat The CMTAT token
     * @param adapter The adapter to verify
     */
    function _verifyAdapterERC7802Roles(CMTATStandalone cmtat, address adapter) internal view {
        assertTrue(cmtat.hasRole(cmtat.CROSS_CHAIN_ROLE(), adapter), "Missing CROSS_CHAIN_ROLE");
    }

    /**
     * @notice Verify ERC-3643 adapter has required roles
     * @param cmtat The CMTAT token
     * @param adapter The adapter to verify
     */
    function _verifyAdapterERC3643Roles(CMTATStandalone cmtat, address adapter) internal view {
        assertTrue(cmtat.hasRole(cmtat.MINTER_ROLE(), adapter), "Missing MINTER_ROLE");
        assertTrue(cmtat.hasRole(cmtat.BURNER_ROLE(), adapter), "Missing BURNER_ROLE");
    }
}
