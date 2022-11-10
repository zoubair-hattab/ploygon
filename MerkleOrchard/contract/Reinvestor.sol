// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseWeightedPool.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IVault.sol";
import "./EnumerableSet.sol";

import "./PoolTokenCache.sol";
import "../interfaces/IDistributorCallback.sol";

contract Reinvestor is PoolTokenCache, IDistributorCallback {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(IVault _vault) PoolTokenCache(_vault) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _initializeArrays(bytes32 poolId, IERC20[] memory tokens)
        internal
        view
        returns (uint256[] memory amountsIn, IVault.UserBalanceOp[] memory leftoverOps)
    {
        uint256 joinTokensCount;
        uint256 leftoverTokensCount;
        for (uint256 t; t < tokens.length; t++) {
            if (poolHasToken(poolId, address(tokens[t]))) {
                joinTokensCount++;
            }
        }
        leftoverTokensCount = tokens.length - joinTokensCount;

        amountsIn = new uint256[](poolTokensLength(poolId));

        leftoverOps = new IVault.UserBalanceOp[](leftoverTokensCount);
    }

    function _populateArrays(
        bytes32 poolId,
        address recipient,
        IERC20[] memory tokens,
        uint256[] memory internalBalances,
        uint256[] memory amountsIn,
        IVault.UserBalanceOp[] memory leftoverOps
    ) internal view {
        uint256 leftoverOpsIdx;

        for (uint256 t; t < tokens.length; t++) {
            address token = address(tokens[t]);

            if (poolHasToken(poolId, token)) {
                amountsIn[_poolTokenIndex(poolId, token)] = internalBalances[t];
            } else {
                leftoverOps[leftoverOpsIdx] = IVault.UserBalanceOp({
                    asset: IAsset(token),
                    amount: internalBalances[t], // callbackAmounts have been subtracted
                    sender: address(this),
                    recipient: payable(recipient),
                    kind: IVault.UserBalanceOpKind.WITHDRAW_INTERNAL
                });
                leftoverOpsIdx++;
            }
        }
    }

    struct CallbackParams {
        address payable recipient;
        bytes32 poolId;
        IERC20[] tokens;
    }

    /**
     * @notice Reinvests tokens in a specified pool
     * @param callbackData - the encoded function arguments
     * recipient - the recipient of the bpt and leftover funds
     * poolId - The pool to receive the tokens
     * tokens - The tokens that were received
     */
    function distributorCallback(bytes calldata callbackData) external override {
        CallbackParams memory params = abi.decode(callbackData, (CallbackParams));

        ensurePoolTokenSetSaved(params.poolId);

        IAsset[] memory assets = _getAssets(params.poolId);

        (uint256[] memory amountsIn, IVault.UserBalanceOp[] memory leftoverOps) = _initializeArrays(
            params.poolId,
            params.tokens
        );

        uint256[] memory internalBalances = vault.getInternalBalance(address(this), params.tokens);
        _populateArrays(params.poolId, params.recipient, params.tokens, internalBalances, amountsIn, leftoverOps);

        _joinPool(params.poolId, params.recipient, assets, amountsIn);
        vault.manageUserBalance(leftoverOps);
    }

    function _joinPool(
        bytes32 poolId,
        address recipient,
        IAsset[] memory assets,
        uint256[] memory amountsIn
    ) internal {
        bytes memory userData = abi.encode(
            BaseWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            uint256(0)
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(assets, amountsIn, userData, true);

        vault.joinPool(poolId, address(this), recipient, request);
    }
}