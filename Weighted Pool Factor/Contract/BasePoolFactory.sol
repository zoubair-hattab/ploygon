// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IVault.sol";
import "../interfaces/IBasePool.sol";


abstract contract BasePoolFactory {
    IVault private immutable _vault;
    mapping(address => bool) private _isPoolFromFactory;

    event PoolCreated(address indexed pool);

    constructor(IVault vault) {
        _vault = vault;
    }

   
    function getVault() public view returns (IVault) {
        return _vault;
    }

    /**
     * @dev Returns true if `pool` was created by this factory.
     */
    function isPoolFromFactory(address pool) external view returns (bool) {
        return _isPoolFromFactory[pool];
    }

    /**
     * @dev Registers a new created pool.
     *
     * Emits a `PoolCreated` event.
     */
    function _register(address pool) internal {
        _isPoolFromFactory[pool] = true;
        emit PoolCreated(pool);
    }
}