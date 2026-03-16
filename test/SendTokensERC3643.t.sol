// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {LayerZeroAdapter} from "../src/LayerZeroAdapter.sol";
import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {IMintableBurnable} from "@layerzerolabs/oft-evm/contracts/interfaces/IMintableBurnable.sol";

import {TestBase} from "./utils/TestBase.sol";

import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Wrapper that makes CMTAT compatible with LayerZero's IMintableBurnable interface.
 *
 * @dev CMTAT's burn(address,uint256) and mint(address,uint256) return void, but
 *      LayerZero's IMintableBurnable requires them to return bool. Solidity 0.8.x
 *      reverts when calling a void-returning function through an interface that declares
 *      a bool return — even if the return value is discarded. This wrapper bridges the gap.
 *
 *      In production, either use a CMTAT version that returns bool, or deploy a similar
 *      wrapper and grant it MINTER_ROLE + BURNER_ROLE instead of the adapter directly.
 */
contract CMTATMintableBurnableWrapper is IMintableBurnable {
    CMTATStandalone public immutable token;

    constructor(CMTATStandalone _token) {
        token = _token;
    }

    function mint(address _to, uint256 _amount) external returns (bool) {
        token.mint(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external returns (bool) {
        token.burn(_from, _amount);
        return true;
    }
}

contract SetupERC3643 is TestBase {
    using OptionsBuilder for bytes;

    uint32 eidA = 1;
    uint32 eidB = 2;

    CMTATStandalone cmtatA;
    LayerZeroAdapter adapterA;

    CMTATStandalone cmtatB;
    LayerZeroAdapter adapterB;

    address admin = address(this);

    function setUp() public virtual override {
        vm.deal(admin, 100 ether);

        setUpEndpoints(2, LibraryType.UltraLightNode);

        vm.startPrank(admin);

        cmtatA = _deployCMTAT(admin, "Token A", "A");
        cmtatB = _deployCMTAT(admin, "Token B", "B");

        adapterA = _deployAdapterERC3643WithWrapper(cmtatA, endpoints[eidA], admin);
        adapterB = _deployAdapterERC3643WithWrapper(cmtatB, endpoints[eidB], admin);

        address[] memory adapters = new address[](2);
        adapters[0] = address(adapterA);
        adapters[1] = address(adapterB);
        this.wireOApps(adapters);

        cmtatA.mint(admin, 100 * 10e6);

        vm.stopPrank();
    }

    /**
     * @notice Deploy ERC-3643 adapter using a bool-returning wrapper around CMTAT.
     * @dev Required because CMTAT's burn/mint return void, not bool as IMintableBurnable requires.
     */
    function _deployAdapterERC3643WithWrapper(CMTATStandalone cmtat, address endpoint, address delegateAdmin)
        internal
        returns (LayerZeroAdapter adapter)
    {
        CMTATMintableBurnableWrapper wrapper = new CMTATMintableBurnableWrapper(cmtat);
        // Wrapper holds the burn/mint roles; adapter calls through the wrapper
        cmtat.grantRole(cmtat.MINTER_ROLE(), address(wrapper));
        cmtat.grantRole(cmtat.BURNER_ROLE(), address(wrapper));
        adapter = new LayerZeroAdapter(address(cmtat), address(wrapper), endpoint, delegateAdmin);
    }

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
}

contract SendTokensERC3643Test is SetupERC3643 {
    // ============ Cross-chain Transfer Tests (T1) ============

    function test_3643_sendTokensAtoB() public {
        uint256 amount = 10e6;

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        uint256 balanceBeforeA = IERC20(adapterA.token()).balanceOf(admin);
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        uint256 balanceAfterA = IERC20(adapterA.token()).balanceOf(admin);
        assertEq(balanceBeforeA - balanceAfterA, amount);

        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        uint256 balanceAfterB = IERC20(adapterB.token()).balanceOf(admin);
        assertEq(balanceAfterB - balanceBeforeB, amount);
    }

    function test_3643_sendTokensBtoA() public {
        uint256 amount = 10e6;

        // First bridge tokens to chain B
        SendParam memory sendParamAtoB = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFeeAtoB = adapterA.quoteSend(sendParamAtoB, false);

        vm.prank(admin);
        adapterA.send{value: msgFeeAtoB.nativeFee}(sendParamAtoB, msgFeeAtoB, admin);
        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        // Now send back from B to A
        uint256 balanceBeforeA = IERC20(adapterA.token()).balanceOf(admin);
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        SendParam memory sendParamBtoA = _buildSendParam(eidA, admin, amount);
        MessagingFee memory msgFeeBtoA = adapterB.quoteSend(sendParamBtoA, false);

        vm.prank(admin);
        adapterB.send{value: msgFeeBtoA.nativeFee}(sendParamBtoA, msgFeeBtoA, admin);

        uint256 balanceAfterB = IERC20(adapterB.token()).balanceOf(admin);
        assertEq(balanceBeforeB - balanceAfterB, amount);

        verifyPackets(eidA, addressToBytes32(address(adapterA)));

        uint256 balanceAfterA = IERC20(adapterA.token()).balanceOf(admin);
        assertEq(balanceAfterA - balanceBeforeA, amount);
    }

    function test_3643_sendToDifferentRecipient() public {
        uint256 amount = 10e6;
        address recipient = address(0xBEEF);

        SendParam memory sendParam = _buildSendParam(eidB, recipient, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        verifyPackets(eidB, addressToBytes32(address(adapterB)));

        assertEq(IERC20(adapterB.token()).balanceOf(recipient), amount);
    }

    // ============ Pause Tests (T2) ============

    function test_3643_pauseBlocksSend() public {
        uint256 amount = 10e6;

        vm.prank(admin);
        adapterA.pause();

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);
    }

    function test_3643_pauseOnDestinationBlocksCredit() public {
        uint256 amount = 10e6;
        uint256 balanceBeforeB = IERC20(adapterB.token()).balanceOf(admin);

        // Pause destination adapter before the message is delivered
        vm.prank(admin);
        adapterB.pause();

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        // Delivery fails silently at the LayerZero layer — tokens are NOT minted
        vm.expectRevert();
        this.verifyPackets(eidB, addressToBytes32(address(adapterB)));

        // Confirm no tokens were credited on the destination
        assertEq(IERC20(adapterB.token()).balanceOf(admin), balanceBeforeB);
    }

    function test_3643_unpauseResumesSend() public {
        uint256 amount = 10e6;

        vm.startPrank(admin);
        adapterA.pause();
        adapterA.unpause();
        vm.stopPrank();

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        verifyPackets(eidB, addressToBytes32(address(adapterB)));
        assertEq(IERC20(adapterB.token()).balanceOf(admin), amount);
    }

    // ============ Access Control Tests (T2) ============

    function test_3643_onlyOwnerCanPause() public {
        address notOwner = address(0xDEAD);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        vm.prank(notOwner);
        adapterA.pause();
    }

    function test_3643_onlyOwnerCanUnpause() public {
        vm.prank(admin);
        adapterA.pause();

        address notOwner = address(0xDEAD);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        vm.prank(notOwner);
        adapterA.unpause();
    }

    // ============ Error Path Tests (T3) ============

    function test_3643_wrapperWithoutBurnerRoleRevertsOnSend() public {
        // Deploy a wrapper without BURNER_ROLE (i.e., roles not granted to it)
        CMTATMintableBurnableWrapper wrapperNoRole = new CMTATMintableBurnableWrapper(cmtatA);
        LayerZeroAdapter adapterNoRole;

        vm.startPrank(admin);
        adapterNoRole = new LayerZeroAdapter(address(cmtatA), address(wrapperNoRole), endpoints[eidA], admin);
        adapterNoRole.setPeer(eidB, bytes32(uint256(uint160(address(adapterB)))));
        vm.stopPrank();

        uint256 amount = 10e6;
        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterNoRole.quoteSend(sendParam, false);

        // wrapperNoRole has no BURNER_ROLE — burn should revert with AccessControl error
        vm.expectRevert();
        vm.prank(admin);
        adapterNoRole.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);
    }

    function test_3643_wrapperWithoutMinterRoleBlocksCredit() public {
        // Deploy destination adapter whose wrapper has no MINTER_ROLE
        CMTATMintableBurnableWrapper wrapperNoRole = new CMTATMintableBurnableWrapper(cmtatB);
        LayerZeroAdapter adapterBNoRole;

        vm.startPrank(admin);
        adapterBNoRole = new LayerZeroAdapter(address(cmtatB), address(wrapperNoRole), endpoints[eidB], admin);
        adapterA.setPeer(eidB, bytes32(uint256(uint160(address(adapterBNoRole)))));
        adapterBNoRole.setPeer(eidA, bytes32(uint256(uint160(address(adapterA)))));
        vm.stopPrank();

        uint256 amount = 10e6;
        uint256 balanceBeforeB = IERC20(adapterBNoRole.token()).balanceOf(admin);

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);

        // Destination mint should fail — wrapperNoRole has no MINTER_ROLE on cmtatB
        vm.expectRevert();
        this.verifyPackets(eidB, addressToBytes32(address(adapterBNoRole)));

        // Confirm no tokens were credited on the destination
        assertEq(IERC20(adapterBNoRole.token()).balanceOf(admin), balanceBeforeB);
    }

    function test_3643_revertOnInsufficientBalance() public {
        uint256 balance = IERC20(adapterA.token()).balanceOf(admin);
        uint256 amount = balance + 1;

        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);

        vm.expectRevert();
        vm.prank(admin);
        adapterA.send{value: msgFee.nativeFee}(sendParam, msgFee, admin);
    }

    // ============ View Function Tests ============

    function test_3643_tokenReturnsCorrectAddress() public view {
        assertEq(adapterA.token(), address(cmtatA));
        assertEq(adapterB.token(), address(cmtatB));
    }

    function test_3643_approvalRequiredReturnsFalse() public view {
        assertFalse(adapterA.approvalRequired());
        assertFalse(adapterB.approvalRequired());
    }

    function test_3643_quoteSendReturnsNonZeroFee() public view {
        uint256 amount = 10e6;
        SendParam memory sendParam = _buildSendParam(eidB, admin, amount);
        MessagingFee memory msgFee = adapterA.quoteSend(sendParam, false);
        assertGt(msgFee.nativeFee, 0);
    }
}
