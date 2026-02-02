// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/* ==== OpenZeppelin === */
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title PauseModule
 * @notice Public-facing functions for placing contracts into a paused state.
 */
abstract contract PauseModule is Pausable {
    modifier onlyPauseManager() {
        _authorizePause();
        _;
    }
    /*//////////////////////////////////////////////////////////////
                                PUBLIC
    //////////////////////////////////////////////////////////////*/

    function pause() public onlyPauseManager {
        _pause();
    }

    function unpause() public onlyPauseManager {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL
    //////////////////////////////////////////////////////////////*/

    /* ==== AUTHORIZATION HOOKS === */
    function _authorizePause() internal view virtual;
}
