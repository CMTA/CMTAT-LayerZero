// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {LayerZeroAdapterOwnable2Step} from "../src/LayerZeroAdapterOwnable2Step.sol";

contract DeployAdapterERC3643Ownable2Step is BaseScript {
    function exec(string memory chain) public override loadPk {
        vm.createSelectFork(chain);

        address admin = vm.addr(pk);

        console.log("Admin:", admin);

        CMTATStandalone cmtat = CMTATStandalone(readContractAddress(chain, "CMTATStandalone"));

        vm.startBroadcast(pk);
        // For CMTAT, the minterBurner is the token itself
        LayerZeroAdapterOwnable2Step adapter =
            new LayerZeroAdapterOwnable2Step(address(cmtat), address(cmtat), getLayerZeroEndpoint(chain), admin);
        cmtat.grantRole(cmtat.MINTER_ROLE(), address(adapter));
        cmtat.grantRole(cmtat.BURNER_ROLE(), address(adapter));
        vm.stopBroadcast();

        writeContractAddress(chain, address(adapter), "LayerZeroAdapter");

        console.log(GREEN, "LayerZeroAdapterOwnable2Step (ERC-3643) deployed to:", address(adapter), RESET);
    }
}
