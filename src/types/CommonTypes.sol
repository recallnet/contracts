// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

/// @dev Environment helper for setting the chain environment in scripts or contracts.
/// @param Local: Local (localnet or devnet) chain
/// @param Testnet: Testnet chain
/// @param Mainnet: Mainnet chain
/// @param Foundry: Testing environment only within `forge test`
enum Environment {
    Local,
    Testnet,
    Mainnet,
    Foundry
}

/// @dev A key-value pair.
struct KeyValue {
    string key;
    string value;
}
