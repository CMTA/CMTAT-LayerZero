// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";
import {LayerZeroAdapterERC7802} from "../src/LayerZeroAdapterERC7802.sol";
import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {TestBase} from "./utils/TestBase.sol";

contract DeployAdapterERC7802Test is TestBase {
    uint32 eid = 1;

    CMTATStandalone cmtat;
    LayerZeroAdapterERC7802 adapter;

    address admin = address(this);

    function setUp() public override {
        vm.deal(admin, 100 ether);
        setUpEndpoints(1, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        // Deploy using shared helpers (simulating DeployAdapter.s.sol)
        cmtat = _deployCMTAT(admin, "Test Token", "TEST");
        adapter = _deployAdapterERC7802(cmtat, endpoints[eid], admin);

        vm.stopPrank();
    }

    // ============ Deployment Verification Tests ============

    function test_adapterDeployedCorrectly() public view {
        assertEq(adapter.token(), address(cmtat));
        assertEq(adapter.owner(), admin);
    }

    function test_crossChainRoleGranted() public view {
        _verifyAdapterERC7802Roles(cmtat, address(adapter));
    }

    function test_approvalRequiredReturnsFalse() public view {
        assertFalse(adapter.approvalRequired());
    }

    function test_adapterCanCallCrosschainBurn() public {
        // Mint tokens to admin
        vm.prank(admin);
        cmtat.mint(admin, 1000e6);

        // Verify adapter has permission to burn via crosschainBurn
        _verifyAdapterERC7802Roles(cmtat, address(adapter));
    }

    function test_adapterCanCallCrosschainMint() public view {
        // Verify adapter has permission to mint via crosschainMint
        _verifyAdapterERC7802Roles(cmtat, address(adapter));
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

contract DeployAdapterERC3643Test is TestBase {
    uint32 eid = 1;

    CMTATStandalone cmtat;
    LayerZeroAdapter adapter;

    address admin = address(this);

    function setUp() public override {
        vm.deal(admin, 100 ether);
        setUpEndpoints(1, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        // Deploy using shared helpers (simulating DeployAdapterERC3643.s.sol)
        cmtat = _deployCMTAT(admin, "Test Token", "TEST");
        adapter = _deployAdapterERC3643(cmtat, endpoints[eid], admin);

        vm.stopPrank();
    }

    // ============ Deployment Verification Tests ============

    function test_adapterDeployedCorrectly() public view {
        assertEq(adapter.token(), address(cmtat));
        assertEq(adapter.owner(), admin);
    }

    function test_minterAndBurnerRolesGranted() public view {
        _verifyAdapterERC3643Roles(cmtat, address(adapter));
    }

    function test_approvalRequiredReturnsFalse() public view {
        assertFalse(adapter.approvalRequired());
    }

    function test_adapterCanMint() public view {
        _verifyAdapterERC3643Roles(cmtat, address(adapter));
    }

    function test_adapterCanBurn() public view {
        _verifyAdapterERC3643Roles(cmtat, address(adapter));
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
