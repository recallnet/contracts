// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface IConfigFacade {
    /// @dev Emitted when the network config admin is set.
    /// @param admin Admin config address.
    event ConfigAdminSet(address admin);

    /// @dev Emitted when the network config is set.
    /// @param blobCapacity The total storage capacity of the subnet.
    /// @param tokenCreditRate The token to credit rate.
    /// @param blobCreditDebitInterval Epoch interval at which to debit all credit accounts.
    /// @param blobMinTtl The minimum epoch duration a blob can be stored.
    /// @param blobDefaultTtl The default epoch duration a blob is stored.
    event ConfigSet(
        uint256 blobCapacity,
        uint256 tokenCreditRate,
        uint256 blobCreditDebitInterval,
        uint256 blobMinTtl,
        uint256 blobDefaultTtl
    );
}
