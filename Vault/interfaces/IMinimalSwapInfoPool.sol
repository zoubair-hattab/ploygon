// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IBasePool.sol";


interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}