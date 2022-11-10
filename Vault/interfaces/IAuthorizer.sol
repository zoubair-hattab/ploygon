// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

interface IAuthorizer {
 
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}