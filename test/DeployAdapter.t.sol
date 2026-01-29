// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";
import {LayerZeroAdapterERC7802} from "../src/LayerZeroAdapterERC7802.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {ICMTATConstructor} from "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import {IERC1643CMTAT} from "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import {IRuleEngine} from "CMTAT/interfaces/engine/IRuleEngine.sol";

import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract DeployAdapterERC7802Test is Test, TestHelperOz5 {
    uint32 eid = 1;

    CMTATStandalone cmtat;
    LayerZeroAdapterERC7802 adapter;

    address admin = address(this);

    function setUp() public override {
        vm.deal(admin, 100 ether);
        setUpEndpoints(1, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        // Deploy CMTAT token
        cmtat = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes("Test Token", "TEST", 6),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );

        // Deploy adapter (simulating DeployAdapter.s.sol)
        adapter = new LayerZeroAdapterERC7802(address(cmtat), endpoints[eid], admin);
        cmtat.grantRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter));

        vm.stopPrank();
    }

    // ============ Deployment Verification Tests ============

    function test_adapterDeployedCorrectly() public view {
        assertEq(adapter.token(), address(cmtat));
        assertEq(adapter.owner(), admin);
    }

    function test_crossChainRoleGranted() public view {
        assertTrue(cmtat.hasRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter)));
    }

    function test_approvalRequiredReturnsFalse() public view {
        assertFalse(adapter.approvalRequired());
    }

    function test_adapterCanCallCrosschainBurn() public {
        // Mint tokens to admin
        vm.prank(admin);
        cmtat.mint(admin, 1000e6);

        // Verify adapter has permission to burn via crosschainBurn
        // This is called internally by _debit, but we verify the role is set
        assertTrue(cmtat.hasRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter)));
    }

    function test_adapterCanCallCrosschainMint() public {
        // Verify adapter has permission to mint via crosschainMint
        // This is called internally by _credit, but we verify the role is set
        assertTrue(cmtat.hasRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter)));
    }

    function test_pauseFunctionalityExists() public {
        vm.prank(admin);
        adapter.pause();
        assertTrue(adapter.paused());

        vm.prank(admin);
        adapter.unpause();
        assertFalse(adapter.paused());
    }
}

contract DeployAdapterERC3643Test is Test, TestHelperOz5 {
    uint32 eid = 1;

    CMTATStandalone cmtat;
    LayerZeroAdapter adapter;

    address admin = address(this);

    function setUp() public override {
        vm.deal(admin, 100 ether);
        setUpEndpoints(1, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        // Deploy CMTAT token
        cmtat = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes("Test Token", "TEST", 6),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );

        // Deploy adapter (simulating DeployAdapterERC3643.s.sol)
        // For CMTAT, the minterBurner is the token itself
        adapter = new LayerZeroAdapter(address(cmtat), address(cmtat), endpoints[eid], admin);
        cmtat.grantRole(cmtat.MINTER_ROLE(), address(adapter));
        cmtat.grantRole(cmtat.BURNER_ROLE(), address(adapter));

        vm.stopPrank();
    }

    // ============ Deployment Verification Tests ============

    function test_adapterDeployedCorrectly() public view {
        assertEq(adapter.token(), address(cmtat));
        assertEq(adapter.owner(), admin);
    }

    function test_minterRoleGranted() public view {
        assertTrue(cmtat.hasRole(cmtat.MINTER_ROLE(), address(adapter)));
    }

    function test_burnerRoleGranted() public view {
        assertTrue(cmtat.hasRole(cmtat.BURNER_ROLE(), address(adapter)));
    }

    function test_approvalRequiredReturnsFalse() public view {
        assertFalse(adapter.approvalRequired());
    }

    function test_adapterCanMint() public {
        // Verify adapter has permission to mint
        assertTrue(cmtat.hasRole(cmtat.MINTER_ROLE(), address(adapter)));
    }

    function test_adapterCanBurn() public {
        // Verify adapter has permission to burn
        assertTrue(cmtat.hasRole(cmtat.BURNER_ROLE(), address(adapter)));
    }

    function test_pauseFunctionalityExists() public {
        vm.prank(admin);
        adapter.pause();
        assertTrue(adapter.paused());

        vm.prank(admin);
        adapter.unpause();
        assertFalse(adapter.paused());
    }
}
