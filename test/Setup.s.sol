// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {LayerZeroAdapterERC7802} from "../src/LayerZeroAdapterERC7802.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {ICMTATConstructor} from "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import {IERC1643CMTAT} from "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import {IRuleEngine} from "CMTAT/interfaces/engine/IRuleEngine.sol";

import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract Setup is Test, TestHelperOz5 {
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

        cmtatA = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes("Token A", "A", 6),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );
        adapterA = new LayerZeroAdapterERC7802(address(cmtatA), endpoints[eidA], admin);

        cmtatB = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes("Token B", "B", 6),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );
        adapterB = new LayerZeroAdapterERC7802(address(cmtatB), endpoints[eidB], admin);

        cmtatA.grantRole(cmtatA.CROSS_CHAIN_ROLE(), address(adapterA));
        cmtatB.grantRole(cmtatB.CROSS_CHAIN_ROLE(), address(adapterB));

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
