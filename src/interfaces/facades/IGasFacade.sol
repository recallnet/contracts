// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface IGasFacade {
    /// @dev Emitted when a gas sponsor is set.
    /// @param sponsor Gas sponsor address.
    event GasSponsorSet(address sponsor);

    /// @dev Emitted when a gas sponsor is unset.
    event GasSponsorUnset();
}
