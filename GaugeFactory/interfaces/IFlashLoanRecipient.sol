// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../interfaces/IERC20.sol";

interface IFlashLoanRecipient {
  
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}