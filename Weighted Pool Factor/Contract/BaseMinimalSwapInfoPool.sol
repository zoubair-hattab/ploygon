// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BasePool.sol";
import "../interfaces/IMinimalSwapInfoPool.sol";

/**
 * @dev Extension of `BasePool`, adding a handler for `IMinimalSwapInfoPool.onSwap`.
 *
 * Derived contracts must implement `_onSwapGivenIn` and `_onSwapGivenOut` along with `BasePool`'s virtual functions.
 */
abstract contract BaseMinimalSwapInfoPool is IMinimalSwapInfoPool, BasePool {
    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        BasePool(
            vault,
            tokens.length == 2 ? IVault.PoolSpecialization.TWO_TOKEN : IVault.PoolSpecialization.MINIMAL_SWAP_INFO,
            name,
            symbol,
            tokens,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    // Swap Hooks

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external view virtual override returns (uint256) {
        uint256 scalingFactorTokenIn = _scalingFactor(request.tokenIn);
        uint256 scalingFactorTokenOut = _scalingFactor(request.tokenOut);

        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // Fees are subtracted before scaling, to reduce the complexity of the rounding direction analysis.
            request.amount = _subtractSwapFeeAmount(request.amount);

            // All token amounts are upscaled.
            balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
            balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);
            request.amount = _upscale(request.amount, scalingFactorTokenIn);

            uint256 amountOut = _onSwapGivenIn(request, balanceTokenIn, balanceTokenOut);

            // amountOut tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountOut, scalingFactorTokenOut);
        } else {
            // All token amounts are upscaled.
            balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);
            balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);
            request.amount = _upscale(request.amount, scalingFactorTokenOut);

            uint256 amountIn = _onSwapGivenOut(request, balanceTokenIn, balanceTokenOut);

            // amountIn tokens are entering the Pool, so we round up.
            amountIn = _downscaleUp(amountIn, scalingFactorTokenIn);

            // Fees are added after scaling happens, to reduce the complexity of the rounding direction analysis.
            return _addSwapFeeAmount(amountIn);
        }
    }


    function _onSwapGivenIn(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal view virtual returns (uint256);

    function _onSwapGivenOut(
        SwapRequest memory swapRequest,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal view virtual returns (uint256);
}