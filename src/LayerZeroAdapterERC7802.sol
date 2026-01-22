// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC7802} from "@openzeppelin/contracts/interfaces/draft-IERC7802.sol";

contract LayerZeroAdapterERC7802 is OFTAdapter, Pausable {
    constructor(address _token, address _lzEndpoint, address _delegate)
        OFTAdapter(_token, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override
        whenNotPaused
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        IERC7802(address(innerToken)).crosschainBurn(_from, amountSentLD);
    }

    function _credit(address _to, uint256 _amountLD, uint32)
        internal
        override
        whenNotPaused
        returns (uint256 amountReceivedLD)
    {
        amountReceivedLD = _amountLD;
        IERC7802(address(innerToken)).crosschainMint(_to, _amountLD);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function approvalRequired() external pure override returns (bool) {
        return false;
    }
}
