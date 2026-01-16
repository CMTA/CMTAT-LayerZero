// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FileHelpers} from "./FileHelpers.sol";

abstract contract BaseScript is Script, FileHelpers {
    uint256 transient pk;

    function run() public loadPk {
        string memory chainName = vm.prompt("Enter chain name (see foundry.toml for available chains)");

        exec(chainName);
    }

    function exec(string memory chainName) public virtual;

    modifier loadPk() {
        pk = vm.envUint("PRIVATE_KEY");
        _;
    }
}
