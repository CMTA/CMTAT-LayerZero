// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./utils/BaseScript.s.sol";

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";

import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

contract SendTokens is BaseScript {
    using OptionsBuilder for bytes;

    function exec(string memory chain) public override {
        string memory targetChain = vm.prompt("Enter target chain name (see foundry.toml for available chains)");
        uint256 amount = vm.parseUint(vm.prompt("Enter amount to send (without decimals)"));

        exec(chain, targetChain, amount);
    }

    function exec(string memory chain, string memory targetChain, uint256 amount) public loadPk {
        vm.createSelectFork(chain);

        LayerZeroAdapter adapter = LayerZeroAdapter(readContractAddress(chain, "LayerZeroAdapter"));

        amount = amount * 10 ** CMTATStandalone(adapter.token()).decimals();

        SendParam memory sendParam = SendParam({
            dstEid: getEID(targetChain),
            to: bytes32(uint256(uint160(vm.addr(pk)))),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0),
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory msgFee = adapter.quoteSend(sendParam, false);

        vm.startBroadcast(pk);
        adapter.send{value: msgFee.nativeFee}(sendParam, msgFee, vm.addr(pk));

        console.log(GREEN, "Tokens sent successfully", RESET);
    }
}
