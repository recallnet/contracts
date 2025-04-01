// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Error thrown when a user tries to request tokens too soon
error TryLater();

/// @dev Error thrown when the faucet is empty
error FaucetEmpty();

/// @dev Error thrown when an invalid funding amount is provided
/// @param from The address attempting to fund
/// @param value The invalid funding amount
error InvalidFunding(address from, uint256 value);

/// @dev Event emitted when the faucet is funded
/// @param from The address that funded the faucet
/// @param value The amount of tokens funded
event Funding(address indexed from, uint256 value);

/// @dev Error thrown when a transfer fails
/// @param recipient The address of the recipient
error TransferFailed(address recipient);

/// @title Faucet Contract
/// @dev A simple faucet contract for distributing tokens
contract Faucet is Ownable {
    /// @dev Mapping to store authorized callers
    mapping(address => bool) internal _authorizedCallers;

    /// @dev Mapping to store the next allowed request time for each key
    mapping(string => uint256) internal _nextRequestAt;

    /// @dev Amount of tokens to drip per request
    uint256 internal _dripAmount = 5 ether;

    /// @dev Error thrown when caller is not authorized
    error UnauthorizedCaller(address caller);

    /// @dev Initializes the Faucet contract
    /// @dev Sets the contract deployer as the initial owner
    constructor() Ownable(msg.sender) {}

    /// @dev Returns the current drip amount
    /// @return The amount of tokens distributed per drip
    function dripAmount() external view returns (uint256) {
        return _dripAmount;
    }

    /// @dev Returns the current faucet supply
    /// @return The balance of tokens in the faucet
    function supply() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Allows users to fund the faucet
    /// @dev Reverts if the funding amount is 0 or less
    function fund() external payable {
        if (msg.value == 0) {
            revert InvalidFunding(msg.sender, msg.value);
        }

        emit Funding(msg.sender, msg.value);
    }

    /// @dev Authorizes a caller to use the drip function
    /// @param caller The address to authorize
    function authorizeCaller(address caller) external onlyOwner {
        _authorizedCallers[caller] = true;
    }

    /// @dev Removes authorization from a caller
    /// @param caller The address to deauthorize
    function deauthorizeCaller(address caller) external onlyOwner {
        _authorizedCallers[caller] = false;
    }

    /// @dev Distributes tokens to the specified recipient
    /// @dev Reverts if the caller is neither the owner nor authorized
    /// @param recipient The address to receive the tokens
    /// @param keys Array of keys to identify the recipient used in the _nextRequestAt mapping
    function drip(address payable recipient, string[] calldata keys) external {
        if (!_authorizedCallers[msg.sender] && owner() != msg.sender) {
            revert UnauthorizedCaller(msg.sender);
        }

        uint256 amount = _dripAmount;

        if (address(this).balance < amount) {
            revert FaucetEmpty();
        }

        uint256 keysLength = keys.length;
        for (uint256 i; i < keysLength; ++i) {
            if (_nextRequestAt[keys[i]] > block.timestamp) {
                revert TryLater();
            }
            _nextRequestAt[keys[i]] = block.timestamp + (12 hours);
        }

        // Handle transfer result
        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert TransferFailed(recipient);
        }
    }

    /// @dev Sets the amount of tokens to distribute per request
    /// @dev Can only be called by the contract owner
    /// @param amt The new drip amount
    function setDripAmount(uint256 amt) external onlyOwner {
        _dripAmount = amt;
    }
}
