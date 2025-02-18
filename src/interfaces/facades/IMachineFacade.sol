// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface IMachineFacade {
    /// @dev Emitted when a machine is created.
    /// @param owner Machine owner address.
    /// @param metadata IPLD-encoded machine metadata (HashMap<String, String>).
    event MachineCreated(address indexed owner, bytes metadata);

    /// @dev Emitted when a machine is initialized.
    /// @param machineAddress Machine address.
    event MachineInitialized(address machineAddress);
}
