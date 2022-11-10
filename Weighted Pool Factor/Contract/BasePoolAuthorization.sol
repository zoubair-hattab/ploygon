// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;

import "./Authentication.sol";
import "../interfaces/IAuthorizer.sol";

import "./BasePool.sol";

abstract contract BasePoolAuthorization is Authentication {
    address private immutable _owner;

    address private constant _DELEGATE_OWNER = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;

    constructor(address owner) {
        _owner = owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        if ((getOwner() != _DELEGATE_OWNER) && _isOwnerOnlyAction(actionId)) {
            // Only the owner can perform "owner only" actions, unless the owner is delegated.
            return msg.sender == getOwner();
        } else {
            // Non-owner actions are always processed via the Authorizer, as "owner only" ones are when delegated.
            return _getAuthorizer().canPerform(actionId, account, address(this));
        }
    }

    function _isOwnerOnlyAction(bytes32 actionId) private view returns (bool) {
        // This implementation hardcodes the setSwapFeePercentage action identifier.
        return actionId == getActionId(BasePool.setSwapFeePercentage.selector);
    }

    function _getAuthorizer() internal view virtual returns (IAuthorizer);
}