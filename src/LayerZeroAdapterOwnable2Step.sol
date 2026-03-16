// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/* ==== OpenZeppelin === */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {LayerZeroAdapter} from "./LayerZeroAdapter.sol";

/**
 * @title LayerZeroAdapterOwnable2Step
 * @notice LayerZero OFT adapter for tokens implementing IMintableBurnable (ERC-3643 compatible)
 * @dev Ownable2Step wrapper over LayerZeroAdapter to avoid logic duplication.
 */
contract LayerZeroAdapterOwnable2Step is LayerZeroAdapter, Ownable2Step {
    constructor(address _token, address _minterBurner, address _lzEndpoint, address _delegate)
        LayerZeroAdapter(_token, _minterBurner, _lzEndpoint, _delegate)
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
