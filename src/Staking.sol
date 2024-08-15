// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable rewardsPerHour = 1000; // 0.01%

    uint256 public stakeBalance = 0;

    event Deposit(address sender, uint256 amount);
    event Withdraw(address sender, uint256 amount);
    event Claim(address sender, uint256 amount);
    event Compound(address sender, uint256 amount);

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastUpdated;
    mapping(address => uint256) public claimed;

    constructor(IERC20 token_) {
        token = token_;
    }

    function rewardBalance() external view returns (uint256) {
        return _rewardBalance();
    }

    function _rewardBalance() internal view returns (uint256) {
        return token.balanceOf(address(this)) - stakeBalance;
    }

    function deposit(uint256 amount_) external {
        _deposit(amount_);
    }

    function _deposit(uint256 amount_) internal {
        token.safeTransferFrom(msg.sender, address(this), amount_);
        balanceOf[msg.sender] += amount_;
        lastUpdated[msg.sender] = block.timestamp;
        stakeBalance += amount_;
        emit Deposit(msg.sender, amount_);
    }

    function rewards(address address_) external view returns (uint256) {
        return _rewards(address_);
    }

    function _rewards(address address_) internal view returns (uint256) {
        return (block.timestamp - lastUpdated[address_]) * balanceOf[address_] / (rewardsPerHour * 1 hours);
    }

    function claim() external {
        uint256 amount = _rewards(msg.sender);
        token.safeTransfer(msg.sender, amount);
        _update(amount);
        emit Claim(msg.sender, amount);
    }

    function _update(uint256 amount_) internal {
        claimed[msg.sender] += amount_;
        lastUpdated[msg.sender] = block.timestamp;
    }

    function compound() external {
        _compound();
    }

    function _compound() internal {
        uint256 amount = _rewards(msg.sender);
        balanceOf[msg.sender] += amount;
        stakeBalance += amount;
        _update(amount);
        emit Compound(msg.sender, amount);
    }

    function withdraw(uint256 amount_) external {
        require(balanceOf[msg.sender] >= amount_, "Insufficient funds");
        _compound();
        balanceOf[msg.sender] -= amount_;
        stakeBalance -= amount_;
        token.safeTransfer(msg.sender, amount_);
        emit Withdraw(msg.sender, amount_);
    }
}
