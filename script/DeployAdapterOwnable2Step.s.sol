// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {LayerZeroAdapterERC7802Ownable2Step} from "../src/LayerZeroAdapterERC7802Ownable2Step.sol";

contract DeployAdapterOwnable2Step is BaseScript {
    function exec(string memory chain) public override loadPk {
        vm.createSelectFork(chain);

        address admin = vm.addr(pk);

        console.log("Admin:", admin);

        CMTATStandalone cmtat = CMTATStandalone(readContractAddress(chain, "CMTATStandalone"));

        vm.startBroadcast(pk);
        LayerZeroAdapterERC7802Ownable2Step adapter =
            new LayerZeroAdapterERC7802Ownable2Step(address(cmtat), getLayerZeroEndpoint(chain), admin);
        cmtat.grantRole(cmtat.CROSS_CHAIN_ROLE(), address(adapter));
        vm.stopBroadcast();

        writeContractAddress(chain, address(adapter), "LayerZeroAdapter");

        console.log(GREEN, "LayerZeroAdapterOwnable2Step (ERC-7802) deployed to:", address(adapter), RESET);
    }
}
