// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


contract FactoryWidePauseWindow {
    // solhint-disable not-rely-on-time

    uint256 private constant _INITIAL_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _BUFFER_PERIOD_DURATION = 30 days;

  
    uint256 private immutable _poolsPauseWindowEndTime;

    constructor() {
        _poolsPauseWindowEndTime = block.timestamp + _INITIAL_PAUSE_WINDOW_DURATION;
    }


    function getPauseConfiguration() public view returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _poolsPauseWindowEndTime) {
            // The buffer period is always the same since its duration is related to how much time is needed to respond
            // to a potential emergency. The Pause Window duration however decreases as the end time approaches.

            pauseWindowDuration = _poolsPauseWindowEndTime - currentTime; // No need for checked arithmetic.
            bufferPeriodDuration = _BUFFER_PERIOD_DURATION;
        } else {
            // After the end time, newly created Pools have no Pause Window, nor Buffer Period (since they are not
            // pausable in the first place).

            pauseWindowDuration = 0;
            bufferPeriodDuration = 0;
        }
    }
}