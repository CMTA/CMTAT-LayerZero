// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {CMTATStandalone} from "CMTAT/deployment/CMTATStandalone.sol";

import {Ownable} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";

contract LayerZeroAdapter is OFTAdapter {
    constructor(address _token, address _lzEndpoint, address _delegate)
        OFTAdapter(_token, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        CMTATStandalone(address(innerToken)).crosschainBurn(_from, amountSentLD);
    }

    function _credit(address _to, uint256 _amountLD, uint32) internal override returns (uint256 amountReceivedLD) {
        amountReceivedLD = _amountLD;
        CMTATStandalone(address(innerToken)).crosschainMint(_to, _amountLD);
    }
}
