// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IVault.sol";

import "./BasePoolFactory.sol";
import "./FactoryWidePauseWindow.sol";
import "./WeightedPool.sol";

contract WeightedPoolFactory is BasePoolFactory, FactoryWidePauseWindow {
    constructor(IVault vault) BasePoolFactory(vault) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Deploys a new `WeightedPool`.
     */
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address) {
        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        address pool = address(
            new WeightedPool(
                getVault(),
                name,
                symbol,
                tokens,
                weights,
                swapFeePercentage,
                pauseWindowDuration,
                bufferPeriodDuration,
                owner
            )
        );
        _register(pool);
        return pool;
    }
}