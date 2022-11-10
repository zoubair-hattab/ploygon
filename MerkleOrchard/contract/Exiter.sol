// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IVault.sol";
import "../interfaces/IBasePool.sol";
import "./BaseWeightedPool.sol";

import "./PoolTokenCache.sol";
import "../interfaces/IDistributorCallback.sol";

contract Exiter is PoolTokenCache, IDistributorCallback {
    constructor(IVault _vault) PoolTokenCache(_vault) {
        // solhint-disable-previous-line no-empty-blocks
    }

    struct CallbackParams {
        address[] pools;
        address payable recipient;
    }

    function distributorCallback(bytes calldata callbackData) external override {
        CallbackParams memory params = abi.decode(callbackData, (CallbackParams));

        for (uint256 p; p < params.pools.length; p++) {
            address poolAddress = params.pools[p];

            IBasePool poolContract = IBasePool(poolAddress);
            bytes32 poolId = poolContract.getPoolId();
            ensurePoolTokenSetSaved(poolId);

            IERC20 pool = IERC20(poolAddress);
            _exitPool(pool, poolId, params.recipient);
        }
    }

    /**
     * @notice Exits the pool
     * Exiting to a single token would look like:
     * bytes memory userData = abi.encode(
     * BaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
     * bptBalance,
     * tokenIndexOut
     * );
     */
    function _exitPool(
        IERC20 pool,
        bytes32 poolId,
        address payable recipient
    ) internal {
        IAsset[] memory assets = _getAssets(poolId);
        uint256[] memory minAmountsOut = new uint256[](assets.length);

        uint256 bptAmountIn = pool.balanceOf(address(this));

        bytes memory userData = abi.encode(BaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptAmountIn);
        bool toInternalBalance = false;

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            assets,
            minAmountsOut,
            userData,
            toInternalBalance
        );
        vault.exitPool(poolId, address(this), recipient, request);
    }
}