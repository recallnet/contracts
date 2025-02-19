// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface IMachineFacade {
    /// @dev Emitted when a machine is created.
    /// @param kind Machine kind, i.e., bucket (0) or timehub (1).
    /// @param owner Machine owner address.
    /// @param metadata IPLD-encoded machine metadata (HashMap<String, String>).
    event MachineCreated(uint8 indexed kind, address indexed owner, bytes metadata);

    /// @dev Emitted when a machine is initialized.
    /// @param kind Machine kind, i.e., bucket (0) or timehub (1).
    /// @param machineAddress Machine address.
    event MachineInitialized(uint8 indexed kind, address machineAddress);
}
