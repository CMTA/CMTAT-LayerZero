// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/* ==== OpenZeppelin === */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC7802} from "@openzeppelin/contracts/interfaces/draft-IERC7802.sol";
/* ==== LayerZero === */
import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
/* ==== Module === */
import {PauseModule} from "./modules/PauseModule.sol";

/**
 * @title LayerZeroAdapter
 * @notice LayerZero OFT adapter for tokens implementing ERC-7802
 * @dev The minterBurner address must have crosschain mint/burn permissions on the token.
 */
contract LayerZeroAdapterERC7802 is OFTAdapter, PauseModule {
    constructor(address _token, address _lzEndpoint, address _delegate)
        OFTAdapter(_token, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}

    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    /* ==== LayerZero === */
    /**
    * Required because the implementation in OFTAdapter returns true
    */
    function approvalRequired() external pure override(OFTAdapter) returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                               Internal
    //////////////////////////////////////////////////////////////*/
          
    /* ==== LayerZero === */
    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override(OFTAdapter)
        whenNotPaused
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        IERC7802(address(innerToken)).crosschainBurn(_from, amountSentLD);
    }

    function _credit(address _to, uint256 _amountLD, uint32)
        internal
        override(OFTAdapter)
        whenNotPaused
        returns (uint256 amountReceivedLD)
    {
        amountReceivedLD = _amountLD;
        IERC7802(address(innerToken)).crosschainMint(_to, _amountLD);
    }

    /* ==== AUTHORIZATION HOOKS === */
    function _authorizePause() internal view virtual override(PauseModule) onlyOwner {}
}
