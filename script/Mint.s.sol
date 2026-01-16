// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";

contract Mint is BaseScript {
    function exec(string memory chain) public override loadPk {
        uint256 amount = vm.parseUint(vm.prompt("Enter amount to mint (without decimals)"));
        exec(chain, vm.addr(pk), amount);
    }

    function exec(string memory chain, uint256 amount) public loadPk {
        exec(chain, vm.addr(pk), amount);
    }

    function exec(string memory chain, address user, uint256 amount) public loadPk {
        vm.createSelectFork(chain);

        CMTATStandalone cmtat = CMTATStandalone(readContractAddress(chain, "CMTATStandalone"));

        vm.startBroadcast(pk);
        cmtat.mint(user, amount * 10 ** cmtat.decimals());
        vm.stopBroadcast();

        console.log(GREEN, "Tokens minted successfully", RESET);
    }
}
