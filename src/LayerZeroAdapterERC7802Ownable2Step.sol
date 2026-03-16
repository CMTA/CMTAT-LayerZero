// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/* ==== OpenZeppelin === */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {LayerZeroAdapterERC7802} from "./LayerZeroAdapterERC7802.sol";

/**
 * @title LayerZeroAdapterERC7802Ownable2Step
 * @notice LayerZero OFT adapter for tokens implementing ERC-7802
 * @dev Ownable2Step wrapper over LayerZeroAdapterERC7802 to avoid logic duplication.
 */
contract LayerZeroAdapterERC7802Ownable2Step is LayerZeroAdapterERC7802, Ownable2Step {
    constructor(address _token, address _lzEndpoint, address _delegate)
        LayerZeroAdapterERC7802(_token, _lzEndpoint, _delegate)
    {}

    function transferOwnership(address newOwner) public virtual override(Ownable, Ownable2Step) onlyOwner {
        Ownable2Step.transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }

    /**
     * @notice Accept ownership and automatically sync the LayerZero delegate to the new owner.
     * @dev Without auto-sync, the previous owner would retain OApp configuration authority on the
     *      endpoint until `setDelegate()` is called manually.
     */
    function acceptOwnership() public virtual override {
        super.acceptOwnership();
        setDelegate(msg.sender);
    }
}
