// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {MintBurnOFTAdapter} from "@layerzerolabs/oft-evm/contracts/MintBurnOFTAdapter.sol";
import {IMintableBurnable} from "@layerzerolabs/oft-evm/contracts/interfaces/IMintableBurnable.sol";

/**
 * @title LayerZeroAdapter
 * @notice LayerZero OFT adapter for tokens implementing IMintableBurnable (ERC-3643 compatible)
 * @dev The token must implement IMintableBurnable interface with mint/burn returning bool.
 *      The minterBurner address must have mint/burn permissions on the token.
 */
contract LayerZeroAdapter is MintBurnOFTAdapter, Pausable {
    constructor(address _token, address _minterBurner, address _lzEndpoint, address _delegate)
        MintBurnOFTAdapter(_token, IMintableBurnable(_minterBurner), _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override
        whenNotPaused
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        return super._debit(_from, _amountLD, _minAmountLD, _dstEid);
    }

    function _credit(address _to, uint256 _amountLD, uint32 _srcEid)
        internal
        override
        whenNotPaused
        returns (uint256 amountReceivedLD)
    {
        return super._credit(_to, _amountLD, _srcEid);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
