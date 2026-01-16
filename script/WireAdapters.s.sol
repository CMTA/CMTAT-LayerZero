// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";

contract WireAdapters is BaseScript {
    function exec(string memory chain) public override {
        string memory targetChain = vm.prompt("Enter target chain name (see foundry.toml for available chains)");

        exec(chain, targetChain);
    }

    function exec(string memory chain, string memory targetChain) public loadPk {
        vm.createSelectFork(chain);

        LayerZeroAdapter adapter = LayerZeroAdapter(readContractAddress(chain, "LayerZeroAdapter"));
        address targetAdapter = readContractAddress(targetChain, "LayerZeroAdapter");
        vm.startBroadcast(pk);
        adapter.setPeer(getEID(targetChain), bytes32(uint256(uint160(targetAdapter))));

        console.log(GREEN, "Adapters wired successfully", RESET);
    }

    // function exec(string[] memory chains) public {
    //     for (uint256 i = 0; i < chains.length; i++) {
    //         for (uint256 j = 0; j < chains.length; j++) {
    //             if (j == i) continue;

    //             exec(chains[i], chains[j]);
    //         }
    //     }
    // }
}
