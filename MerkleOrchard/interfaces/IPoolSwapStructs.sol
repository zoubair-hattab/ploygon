// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {

    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}