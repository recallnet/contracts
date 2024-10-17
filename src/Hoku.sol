// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "@openzeppelin/contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {Environment} from "./types/CommonTypes.sol";

/// @title Hoku Token Contract
/// @dev Implements an upgradeable ERC20 token with additional features like pausing and minting
contract Hoku is
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the given environment
    /// @param env The environment in which the contract is deployed
    function initialize(Environment env) public initializer {
        string memory symbol = "HOKU";
        if (env == Environment.Testnet) {
            symbol = "tHOKU";
        }
        __ERC20_init("Hoku", symbol);
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Mints new tokens
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @dev Pauses all token transfers
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses all token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {} // solhint-disable
        // no-empty-blocks
}
