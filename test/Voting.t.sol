// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Voting} from "../src/token/Voting.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VotingTest is Test {
    Voting public voting;
    address public owner;
    address public alice;
    address public bob;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        voting = new Voting();
        
        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testOwnership() public view {
        assertEq(voting.owner(), owner);
    }

    function testAllocateVotes() public {
        // Allocate 5 votes to Alice
        voting.allocateVotes(alice, 5);
        
        // Check allocation
        (uint256 voteCount, uint256 expiryTimestamp) = voting.voteAllocations(alice);
        assertEq(voteCount, 5, "Alice's vote count should be 5");
        
        // Check timestamp (roughly)
        uint256 expectedExpiry = block.timestamp + 7 days;
        assertApproxEqAbs(expiryTimestamp, expectedExpiry, 1, "Expiry should be about a week from now");
    }
    
    function testAllocateVotesRequiresOwner() public {
        // Try to allocate votes as Alice (not owner)
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        voting.allocateVotes(bob, 5);
    }

    function testVoting() public {
        // Allocate 3 votes to Alice
        voting.allocateVotes(alice, 3);
        
        // Alice votes
        vm.prank(alice);
        bool success = voting.vote();
        assertTrue(success, "Vote should succeed");
        
        // Check remaining votes
        (uint256 voteCount, ) = voting.voteAllocations(alice);
        assertEq(voteCount, 2, "Alice should have 2 votes remaining");
        
        // Vote again
        vm.prank(alice);
        success = voting.vote();
        assertTrue(success, "Second vote should succeed");
        
        // Check remaining votes again
        (voteCount, ) = voting.voteAllocations(alice);
        assertEq(voteCount, 1, "Alice should have 1 vote remaining");
    }
    
    function testCannotVoteWithoutAllocation() public {
        // Bob tries to vote without allocation
        vm.prank(bob);
        // For an address with no allocation, the expiryTimestamp is 0, so it's actually expired
        vm.expectRevert("Votes expired");
        voting.vote();
    }
    
    function testCannotVoteAfterDepleted() public {
        // Allocate 1 vote to Alice
        voting.allocateVotes(alice, 1);
        
        // Alice votes once
        vm.prank(alice);
        voting.vote();
        
        // Try to vote again
        vm.prank(alice);
        vm.expectRevert("No votes available");
        voting.vote();
    }
    
    function testVoteExpiration() public {
        // Allocate 5 votes to Alice
        voting.allocateVotes(alice, 5);
        
        // Move time forward one week + 1 second
        vm.warp(block.timestamp + 7 days + 1 seconds);
        
        // Alice tries to vote after expiration
        vm.prank(alice);
        vm.expectRevert("Votes expired");
        voting.vote();
    }
    
    function testHasVotes() public {
        // Allocate 3 votes to Alice
        voting.allocateVotes(alice, 3);
        
        // Check if Alice has votes
        bool hasVotes = voting.hasVotes(alice);
        assertTrue(hasVotes, "Alice should have votes");
        
        // Bob should not have votes
        hasVotes = voting.hasVotes(bob);
        assertFalse(hasVotes, "Bob should not have votes");
        
        // Alice votes all 3 times
        vm.startPrank(alice);
        voting.vote();
        voting.vote();
        voting.vote();
        vm.stopPrank();
        
        // Alice should not have votes anymore
        hasVotes = voting.hasVotes(alice);
        assertFalse(hasVotes, "Alice should not have votes after using all");
    }
    
    function testGetRemainingVotes() public {
        // Allocate 5 votes to Alice
        voting.allocateVotes(alice, 5);
        
        // Check remaining votes
        uint256 remaining = voting.getRemainingVotes(alice);
        assertEq(remaining, 5, "Alice should have 5 votes");
        
        // Alice votes twice
        vm.startPrank(alice);
        voting.vote();
        voting.vote();
        vm.stopPrank();
        
        // Check remaining votes again
        remaining = voting.getRemainingVotes(alice);
        assertEq(remaining, 3, "Alice should have 3 votes remaining");
        
        // Move time forward past expiration
        vm.warp(block.timestamp + 7 days + 1 seconds);
        
        // Check remaining votes after expiration
        remaining = voting.getRemainingVotes(alice);
        assertEq(remaining, 0, "Expired votes should return 0");
    }
    
    function testReallocation() public {
        // Allocate 3 votes to Alice
        voting.allocateVotes(alice, 3);
        
        // Alice uses 1 vote
        vm.prank(alice);
        voting.vote();
        
        // Check remaining
        uint256 remaining = voting.getRemainingVotes(alice);
        assertEq(remaining, 2, "Alice should have 2 votes remaining");
        
        // Reallocate 5 votes to Alice
        voting.allocateVotes(alice, 5);
        
        // Check new allocation
        remaining = voting.getRemainingVotes(alice);
        assertEq(remaining, 5, "Alice should have 5 votes after reallocation");
    }
    
    function testMultipleUsers() public {
        // Allocate votes to Alice and Bob
        voting.allocateVotes(alice, 3);
        voting.allocateVotes(bob, 2);
        
        // Both vote
        vm.prank(alice);
        voting.vote();
        
        vm.prank(bob);
        voting.vote();
        
        // Check remaining
        uint256 aliceVotes = voting.getRemainingVotes(alice);
        uint256 bobVotes = voting.getRemainingVotes(bob);
        
        assertEq(aliceVotes, 2, "Alice should have 2 votes remaining");
        assertEq(bobVotes, 1, "Bob should have 1 vote remaining");
    }
} 