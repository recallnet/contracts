// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is Ownable(msg.sender) {
    // Vote allocation structure
    struct VoteAllocation {
        uint256 voteCount;
        uint256 expiryTimestamp;
    }
    
    // Mapping to track vote allocations by address
    mapping(address => VoteAllocation) public voteAllocations;
    
    // Week duration in seconds (7 days)
    uint256 private constant WEEK_DURATION = 7 * 24 * 60 * 60;
    
    // Events
    event VotesAllocated(address indexed voter, uint256 voteCount, uint256 expiryTimestamp);
    event VoteCast(address indexed voter, uint256 remainingVotes);
    
    /**
     * @notice Allocate votes to an address
     * @param voter Address to allocate votes to
     * @param voteCount Number of votes to allocate
     */
    function allocateVotes(address voter, uint256 voteCount) external onlyOwner {
        // Set expiry timestamp to the end of the current week
        uint256 expiryTimestamp = block.timestamp + WEEK_DURATION;
        
        // Overwrite any existing allocation
        voteAllocations[voter] = VoteAllocation({
            voteCount: voteCount,
            expiryTimestamp: expiryTimestamp
        });
        
        emit VotesAllocated(voter, voteCount, expiryTimestamp);
    }
    
    /**
     * @notice Cast a vote
     * @dev Reduces the caller's vote count by 1 if they have unexpired votes
     * @return success Whether the vote was successfully cast
     */
    function vote() external returns (bool success) {
        VoteAllocation storage allocation = voteAllocations[msg.sender];
        
        // Check if votes are still valid
        require(block.timestamp < allocation.expiryTimestamp, "Votes expired");
        require(allocation.voteCount > 0, "No votes available");
        
        // Reduce vote count
        allocation.voteCount -= 1;
        
        emit VoteCast(msg.sender, allocation.voteCount);
        return true;
    }
    
    /**
     * @notice Check if an address has votes remaining
     * @param voter Address to check
     * @return hasVotes Whether the address has unexpired votes remaining
     */
    function hasVotes(address voter) external view returns (bool hasVotes) {
        VoteAllocation memory allocation = voteAllocations[voter];
        return allocation.voteCount > 0 && block.timestamp < allocation.expiryTimestamp;
    }
    
    /**
     * @notice Get the remaining vote count for an address
     * @param voter Address to check
     * @return The number of votes remaining (0 if expired)
     */
    function getRemainingVotes(address voter) external view returns (uint256) {
        VoteAllocation memory allocation = voteAllocations[voter];
        
        // Return 0 if votes have expired
        if (block.timestamp >= allocation.expiryTimestamp) {
            return 0;
        }
        
        return allocation.voteCount;
    }
}
