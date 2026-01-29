// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Counter - Simple contract to test
/// @author Mastering EVM (2025 Edition)
/// @notice A basic counter for demonstrating Foundry testing
/// @dev Chapter 11: Testing & Verification - Contract Under Test
contract Counter {
    uint256 public count;
    address public owner;

    event CountIncremented(uint256 indexed newCount, address indexed by);
    event CountDecremented(uint256 indexed newCount, address indexed by);
    event CountSet(uint256 indexed newCount, address indexed by);

    error NotOwner();
    error CounterUnderflow();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function increment() external {
        count += 1;
        emit CountIncremented(count, msg.sender);
    }

    function decrement() external {
        if (count == 0) revert CounterUnderflow();
        count -= 1;
        emit CountDecremented(count, msg.sender);
    }

    function setCount(uint256 _count) external onlyOwner {
        count = _count;
        emit CountSet(count, msg.sender);
    }

    function incrementBy(uint256 amount) external {
        count += amount;
        emit CountIncremented(count, msg.sender);
    }
}
