// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {LayerZeroAdapterERC7802} from "../src/LayerZeroAdapterERC7802.sol";

contract DeployAdapter is BaseScript {
    function exec(string memory chain) public override loadPk {
        vm.createSelectFork(chain);

        address admin = vm.addr(pk);

        console.log("Admin:", admin);

        CMTATStandalone cmtat = CMTATStandalone(readContractAddress(chain, "CMTATStandalone"));

        vm.startBroadcast(pk);
        LayerZeroAdapterERC7802 adapter =
            new LayerZeroAdapterERC7802(address(cmtat), getLayerZeroEndpoint(chain), admin);
        cmtat.grantRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter));
        vm.stopBroadcast();

        writeContractAddress(chain, address(adapter), "LayerZeroAdapter");

        console.log(GREEN, "LayerZeroAdapter deployed to:", address(adapter), RESET);
    }
}
