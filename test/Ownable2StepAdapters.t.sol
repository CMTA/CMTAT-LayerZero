// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {TestBase} from "./utils/TestBase.sol";
import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LayerZeroAdapterOwnable2Step} from "../src/LayerZeroAdapterOwnable2Step.sol";
import {LayerZeroAdapterERC7802Ownable2Step} from "../src/LayerZeroAdapterERC7802Ownable2Step.sol";

interface IEndpointDelegates {
    function delegates(address oapp) external view returns (address);
}

contract Ownable2StepAdaptersTest is TestBase {
    uint32 internal constant EID = 1;

    address internal admin = address(this);
    address internal newOwner = address(0xBEEF);
    address internal outsider = address(0xCAFE);

    CMTATStandalone internal cmtat;
    LayerZeroAdapterOwnable2Step internal adapter3643;
    LayerZeroAdapterERC7802Ownable2Step internal adapter7802;

    function setUp() public override {
        setUpEndpoints(1, LibraryType.UltraLightNode);

        vm.startPrank(admin);
        cmtat = _deployCMTAT(admin, "Test Token", "TEST");
        adapter3643 = _deployAdapterERC3643Ownable2Step(cmtat, endpoints[EID], admin);
        adapter7802 = _deployAdapterERC7802Ownable2Step(cmtat, endpoints[EID], admin);
        vm.stopPrank();
    }

    function test_3643_transferOwnershipRequiresAccept() public {
        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);

        assertEq(adapter3643.pendingOwner(), newOwner);
        assertEq(adapter3643.owner(), admin);
    }

    function test_7802_transferOwnershipRequiresAccept() public {
        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);

        assertEq(adapter7802.pendingOwner(), newOwner);
        assertEq(adapter7802.owner(), admin);
    }

    function test_3643_onlyPendingOwnerCanAccept() public {
        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, outsider));
        vm.prank(outsider);
        adapter3643.acceptOwnership();

        vm.prank(newOwner);
        adapter3643.acceptOwnership();

        assertEq(adapter3643.owner(), newOwner);
        assertEq(adapter3643.pendingOwner(), address(0));
    }

    function test_7802_onlyPendingOwnerCanAccept() public {
        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, outsider));
        vm.prank(outsider);
        adapter7802.acceptOwnership();

        vm.prank(newOwner);
        adapter7802.acceptOwnership();

        assertEq(adapter7802.owner(), newOwner);
        assertEq(adapter7802.pendingOwner(), address(0));
    }

    function test_3643_newOwnerCanPauseAfterAccept() public {
        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);

        vm.prank(newOwner);
        adapter3643.acceptOwnership();

        vm.prank(newOwner);
        adapter3643.pause();
        assertTrue(adapter3643.paused());
    }

    function test_7802_newOwnerCanPauseAfterAccept() public {
        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);

        vm.prank(newOwner);
        adapter7802.acceptOwnership();

        vm.prank(newOwner);
        adapter7802.pause();
        assertTrue(adapter7802.paused());
    }

    function test_3643_nonOwnerCannotInitiateTransfer() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, outsider));
        vm.prank(outsider);
        adapter3643.transferOwnership(newOwner);
    }

    function test_7802_nonOwnerCannotInitiateTransfer() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, outsider));
        vm.prank(outsider);
        adapter7802.transferOwnership(newOwner);
    }

    function test_3643_oldOwnerCannotPauseAfterTransfer() public {
        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);

        vm.prank(newOwner);
        adapter3643.acceptOwnership();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        vm.prank(admin);
        adapter3643.pause();
    }

    function test_7802_oldOwnerCannotPauseAfterTransfer() public {
        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);

        vm.prank(newOwner);
        adapter7802.acceptOwnership();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        vm.prank(admin);
        adapter7802.pause();
    }

    function test_3643_overwritePendingOwnerInvalidatesPrior() public {
        address secondCandidate = address(0xDEAD);

        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);

        vm.prank(admin);
        adapter3643.transferOwnership(secondCandidate);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
        vm.prank(newOwner);
        adapter3643.acceptOwnership();

        vm.prank(secondCandidate);
        adapter3643.acceptOwnership();
        assertEq(adapter3643.owner(), secondCandidate);
    }

    function test_7802_overwritePendingOwnerInvalidatesPrior() public {
        address secondCandidate = address(0xDEAD);

        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);

        vm.prank(admin);
        adapter7802.transferOwnership(secondCandidate);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
        vm.prank(newOwner);
        adapter7802.acceptOwnership();

        vm.prank(secondCandidate);
        adapter7802.acceptOwnership();
        assertEq(adapter7802.owner(), secondCandidate);
    }

    function test_3643_newOwnerMustSyncDelegate() public {
        IEndpointDelegates ep = IEndpointDelegates(address(adapter3643.endpoint()));

        // Before transfer: delegate is admin
        assertEq(ep.delegates(address(adapter3643)), admin);

        vm.prank(admin);
        adapter3643.transferOwnership(newOwner);
        vm.prank(newOwner);
        adapter3643.acceptOwnership();

        // Delegate is still admin — not auto-updated by ownership transfer
        assertEq(ep.delegates(address(adapter3643)), admin);

        // New owner syncs it
        vm.prank(newOwner);
        adapter3643.setDelegate(newOwner);
        assertEq(ep.delegates(address(adapter3643)), newOwner);
    }

    function test_7802_newOwnerMustSyncDelegate() public {
        IEndpointDelegates ep = IEndpointDelegates(address(adapter7802.endpoint()));

        assertEq(ep.delegates(address(adapter7802)), admin);

        vm.prank(admin);
        adapter7802.transferOwnership(newOwner);
        vm.prank(newOwner);
        adapter7802.acceptOwnership();

        assertEq(ep.delegates(address(adapter7802)), admin);

        vm.prank(newOwner);
        adapter7802.setDelegate(newOwner);
        assertEq(ep.delegates(address(adapter7802)), newOwner);
    }
}
