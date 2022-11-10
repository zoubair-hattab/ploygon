// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;

interface IDistributor {
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 amount);
}