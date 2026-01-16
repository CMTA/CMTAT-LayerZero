// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Setup} from "./Setup.s.sol";

import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SendTokensTest is Setup {
    using OptionsBuilder for bytes;

    function test_sendTokensAtoB() public {
        uint256 amount = 10e6;

        SendParam memory sendParam = SendParam({
            dstEid: eidB,
            to: bytes32(uint256(uint160(admin))),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: OptionsBuilder.newOptions().addExecutorLzReceiveOption(900_000, 0),
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        uint256 balanceBefore = IERC20(adapterA.token()).balanceOf(admin);

        vm.startPrank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        uint256 balanceAfter = IERC20(adapterA.token()).balanceOf(admin);

        assertEq(balanceBefore - balanceAfter, amount);
    }
}
