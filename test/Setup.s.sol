// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {LayerZeroAdapterERC7802} from "../src/LayerZeroAdapterERC7802.sol";
import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {TestBase} from "./utils/TestBase.sol";

contract Setup is TestBase {
    uint32 eidA = 1;
    uint32 eidB = 2;

    CMTATStandalone cmtatA;
    LayerZeroAdapterERC7802 adapterA;

    CMTATStandalone cmtatB;
    LayerZeroAdapterERC7802 adapterB;

    address admin = address(this);
    string chain = "arbitrum-sepolia";

    function setUp() public override {
        _beforeSetup();
        _setup();
        _afterSetup();
    }

    function _beforeSetup() public virtual {}

    function _setup() public virtual {
        vm.deal(admin, 100 ether);

        setUpEndpoints(2, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        // Deploy tokens using shared helper
        cmtatA = _deployCMTAT(admin, "Token A", "A");
        cmtatB = _deployCMTAT(admin, "Token B", "B");

        // Deploy adapters using shared helper
        adapterA = _deployAdapterERC7802(cmtatA, endpoints[eidA], admin);
        adapterB = _deployAdapterERC7802(cmtatB, endpoints[eidB], admin);

        // Configure and wire the OFTs together
        address[] memory adapters = new address[](2);
        adapters[0] = address(adapterA);
        adapters[1] = address(adapterB);
        this.wireOApps(adapters);

        cmtatA.mint(admin, 100 * 10e6);

        vm.stopPrank();
    }

    function _afterSetup() public virtual {}
}
