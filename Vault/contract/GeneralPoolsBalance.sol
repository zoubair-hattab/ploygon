// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./EnumerableMap.sol";
import "../interfaces/IERC20.sol";

import "./BalanceAllocation.sol";

abstract contract GeneralPoolsBalance {
    using BalanceAllocation for bytes32;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    mapping(bytes32 => EnumerableMap.IERC20ToBytes32Map) internal _generalPoolsBalances;

    function _registerGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            // EnumerableMaps require an explicit initial value when creating a key-value pair: we use zero, the same
            // value that is found in uninitialized storage, which corresponds to an empty balance.
            bool added = poolBalances.set(tokens[i], 0);
            _require(added, Errors.TOKEN_ALREADY_REGISTERED);
        }
    }

    /**
     * @dev Deregisters a list of tokens in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * Requirements:
     *
     * - `tokens` must be registered in the Pool
     * - `tokens` must have zero balance in the Vault
     * - `tokens` must not contain duplicates
     */
    function _deregisterGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);
            _require(currentBalance.isZero(), Errors.NONZERO_TOKEN_BALANCE);

            // We don't need to check remove's return value, since _getGeneralPoolBalance already checks that the token
            // was registered.
            poolBalances.remove(token);
        }
    }

    /**
     * @dev Sets the balances of a General Pool's tokens to `balances`.
     *
     * WARNING: this assumes `balances` has the same length and order as the Pool's tokens.
     */
    function _setGeneralPoolBalances(bytes32 poolId, bytes32[] memory balances) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < balances.length; ++i) {
            // Since we assume all balances are properly ordered, we can simply use `unchecked_setAt` to avoid one less
            // storage read per token.
            poolBalances.unchecked_setAt(i, balances[i]);
        }
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a General Pool from cash into managed.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _generalPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a General Pool from managed into cash.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _generalPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    /**
     * @dev Sets `token`'s managed balance in a General Pool to `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _setGeneralPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateGeneralPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    /**
     * @dev Sets `token`'s balance in a General Pool to the result of the `mutation` function when called with the
     * current balance and `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _updateGeneralPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private returns (int256) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);

        bytes32 newBalance = mutation(currentBalance, amount);
        poolBalances.set(token, newBalance);

        return newBalance.managedDelta(currentBalance);
    }

    /**
     * @dev Returns an array with all the tokens and balances in a General Pool. The order may change when tokens are
     * registered or deregistered.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     */
    function _getGeneralPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        tokens = new IERC20[](poolBalances.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            // Because the iteration is bounded by `tokens.length`, which matches the EnumerableMap's length, we can use
            // `unchecked_at` as we know `i` is a valid token index, saving storage reads.
            (tokens[i], balances[i]) = poolBalances.unchecked_at(i);
        }
    }

    /**
     * @dev Returns the balance of a token in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * Requirements:
     *
     * - `token` must be registered in the Pool
     */
    function _getGeneralPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return _getGeneralPoolBalance(poolBalances, token);
    }

    /**
     * @dev Same as `_getGeneralPoolBalance` but using a Pool's storage pointer, which saves gas in repeated reads and
     * writes.
     */
    function _getGeneralPoolBalance(EnumerableMap.IERC20ToBytes32Map storage poolBalances, IERC20 token)
        private
        view
        returns (bytes32)
    {
        return poolBalances.get(token, Errors.TOKEN_NOT_REGISTERED);
    }

    /**
     * @dev Returns true if `token` is registered in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     */
    function _isGeneralPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return poolBalances.contains(token);
    }
}