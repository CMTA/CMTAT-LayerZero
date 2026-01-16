// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {ICMTATConstructor} from "CMTAT/interfaces/technical/ICMTATConstructor.sol";
import {IERC1643CMTAT} from "CMTAT/interfaces/tokenization/draft-IERC1643CMTAT.sol";
import {IRuleEngine} from "CMTAT/interfaces/engine/IRuleEngine.sol";

contract DeployToken is BaseScript {
    function exec(string memory chain) public override loadPk {
        vm.createSelectFork(chain);

        address admin = vm.addr(pk);
        vm.startBroadcast(pk);

        console.log("Admin:", admin);

        CMTATStandalone cmtat = new CMTATStandalone(
            address(0),
            admin,
            ICMTATConstructor.ERC20Attributes("Token", "TKN", 6),
            ICMTATConstructor.ExtraInformationAttributes(
                "TOKEN_ID", IERC1643CMTAT.DocumentInfo("Token Terms", "URL", 0), "Token Information"
            ),
            ICMTATConstructor.Engine(IRuleEngine(address(0)))
        );

        writeContractAddress(chain, address(cmtat), "CMTATStandalone");

        console.log(GREEN);
        console.log("CMTATStandalone deployed to:", address(cmtat), RESET);
    }
}
