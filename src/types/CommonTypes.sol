// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

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
