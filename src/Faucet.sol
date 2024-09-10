// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error TryLater();
error InvalidFunding(address from, uint256 value);

event Funding(address indexed from, uint256 value);

contract Faucet is Ownable {
    /// For rate limiting
    mapping(address => uint256) internal _nextRequestAt;
    /// Amount to drip
    uint256 internal _dripAmount = 100;

    constructor() Ownable(msg.sender) {}

    /// Current drip amount
    function dripAmount() external view returns (uint256) {
        return _dripAmount;
    }

    /// Current faucet supply
    function supply() external view returns (uint256) {
        return address(this).balance;
    }

    /// Fund the faucet
    function fund() external payable {
        if (msg.value <= 0) {
            revert InvalidFunding(msg.sender, msg.value);
        }

        emit Funding(msg.sender, msg.value);
    }

    /// Used to send the tokens
    /// @param recipient The address of the tokens recipient
    function drip(address payable recipient) external {
        if (recipient == address(0)) {
            revert InvalidFunding(recipient, _dripAmount);
        }

        if (_nextRequestAt[recipient] > block.timestamp) {
            revert TryLater();
        }

        recipient.transfer(_dripAmount);

        _nextRequestAt[recipient] = block.timestamp + (5 minutes);
    }

    /// Used to set the drip amount per request
    /// @dev This method is restricted and should be called only by the owner
    /// @param amt The new drip amount for the tokens per request
    function setDripAmount(uint256 amt) external onlyOwner {
        _dripAmount = amt;
    }
}
