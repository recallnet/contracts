// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface ITimehubFacade {
    /// @dev Emitted when an event is pushed to a timehub.
    /// @param index Event index.
    /// @param timestamp Event timestamp.
    /// @param cid Event Cid.
    event EventPushed(uint256 index, uint256 timestamp, bytes cid);
}
