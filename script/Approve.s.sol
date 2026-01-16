// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";
import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

contract Approve is BaseScript {
    function exec(string memory chain) public override loadPk {
        uint256 amount = type(uint256).max;
        exec(chain, amount);
    }

    function exec(string memory chain, uint256 amount) public loadPk {
        vm.createSelectFork(chain);

        LayerZeroAdapter adapter = LayerZeroAdapter(readContractAddress(chain, "LayerZeroAdapter"));
        CMTATStandalone cmtat = CMTATStandalone(readContractAddress(chain, "CMTATStandalone"));
        vm.startBroadcast(pk);
        cmtat.approve(address(adapter), amount);
        vm.stopBroadcast();
    }
}
