// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Setup} from "./Setup.s.sol";

import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {console} from "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SendTokensTest is Setup {
    using OptionsBuilder for bytes;

    // ============ Helpers ============

    function _buildSendParam(uint32 dstEid, address to, uint256 amount) internal pure returns (SendParam memory) {
        return SendParam({
            dstEid: dstEid,
            to: bytes32(uint256(uint160(to))),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: OptionsBuilder.newOptions().addExecutorLzReceiveOption(900_000, 0),
            composeMsg: "",
            oftCmd: ""
        });
    }

    // ============ Cross-chain Transfer Tests ============

    function test_sendTokensAtoB() public {
        uint256 amount = 10e6;

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        uint256 balanceBeforeA = IERC20(adapterA.token()).balanceOf(admin);
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        // Verify source chain debit
        uint256 balanceAfterA = IERC20(adapterA.token()).balanceOf(admin);
        assertEq(balanceBeforeA - balanceAfterA, amount);

        // Process cross-chain message and verify destination credit
        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        uint256 balanceAfterB = IERC20(adapterB.token()).balanceOf(admin);
        assertEq(balanceAfterB - balanceBeforeB, amount);
    }

    function test_sendTokensBtoA() public {
        uint256 amount = 10e6;

        // First send tokens to chain B
        SendParam memory sendParamAtoB = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFeeAtoB = adapterA.quoteSend(sendParamAtoB, false);

        vm.prank(admin);
        adapterA.send{value: msgFeeAtoB.nativeFee}(sendParamAtoB, msgFeeAtoB, admin);
        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        // Now send tokens back from B to A
        uint256 balanceBeforeA = IERC20(adapterA.token()).balanceOf(admin);
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        SendParam memory sendParamBtoA = _buildSendParam(eidA, admin, amount);
        MessagingFee memory msgFeeBtoA = adapterB.quoteSend(sendParamBtoA, false);

        vm.prank(admin);
        adapterB.send{value: msgFeeBtoA.nativeFee}(sendParamBtoA, msgFeeBtoA, admin);

        // Verify source chain B debit
        uint256 balanceAfterB = IERC20(adapterB.token()).balanceOf(admin);
        assertEq(balanceBeforeB - balanceAfterB, amount);

        // Process cross-chain message and verify destination credit on A
        verifyPackets(eidA, addressToBytes32(address(adapterA)));

        uint256 balanceAfterA = IERC20(adapterA.token()).balanceOf(admin);
        assertEq(balanceAfterA - balanceBeforeA, amount);
    }

    function test_sendToDifferentRecipient() public {
        uint256 amount = 10e6;
        address recipient = address(0xBEEF);

        SendParam memory sendParam = _buildSendParam(eidB, recipient, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        assertEq(IERC20(adapterB.token()).balanceOf(recipient), amount);
    }

    // ============ Pause Tests ============

    function test_pauseBlocksSend() public {
        uint256 amount = 10e6;

        vm.prank(admin);
        adapterA.pause();

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);
    }

    function test_unpauseResumesSend() public {
        uint256 amount = 10e6;

        // Pause then unpause
        vm.startPrank(admin);
        adapterA.pause();
        adapterA.unpause();
        vm.stopPrank();

        // Should work now
        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        // Verify it went through
        verifyPackets(eidB, addressToBytes32(address(adapterB)));
        assertEq(IERC20(adapterB.token()).balanceOf(admin), amount);
    }

    // ============ Access Control Tests ============

    function test_onlyOwnerCanPause() public {
        address notOwner = address(0xDEAD);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        vm.prank(notOwner);
        adapterA.pause();
    }

    function test_onlyOwnerCanUnpause() public {
        vm.prank(admin);
        adapterA.pause();

        address notOwner = address(0xDEAD);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        vm.prank(notOwner);
        adapterA.unpause();
    }

    // ============ Edge Case Tests ============

    function test_revertOnInsufficientBalance() public {
        uint256 balance = IERC20(adapterA.token()).balanceOf(admin);
        uint256 amount = balance + 1; // More than available

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.expectRevert();
        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);
    }

    function test_zeroAmountNoBalanceChange() public {
        uint256 balanceBeforeA = IERC20(adapterA.token()).balanceOf(admin);
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        SendParam memory sendParam = _buildSendParam(eidB, admin, 0);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        // Zero amount transfer succeeds but no balance change
        assertEq(IERC20(adapterA.token()).balanceOf(admin), balanceBeforeA);
        assertEq(IERC20(adapterB.token()).balanceOf(admin), balanceBeforeB);
    }

    // ============ Quote Tests ============

    function test_quoteSendReturnsNonZeroFee() public view {
        uint256 amount = 10e6;

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        assertGt(msgFee.nativeFee, 0);
    }

    // ============ View Function Tests ============

    function test_tokenReturnsCorrectAddress() public view {
        assertEq(adapterA.token(), address(cmtatA));
        assertEq(adapterB.token(), address(cmtatB));
    }

    function test_approvalRequiredReturnsFalse() public view {
        assertFalse(adapterA.approvalRequired());
        assertFalse(adapterB.approvalRequired());
    }
}
