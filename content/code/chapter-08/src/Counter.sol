// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Counter - A simple counter contract
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates basic state variables, functions, and events
/// @dev Chapter 8: Solidity Fundamentals - Your first contract
contract Counter {
    // State variable - stored on-chain
    uint256 public count;

    // Events for off-chain tracking
    event CountIncremented(uint256 indexed newCount, address indexed by);
    event CountDecremented(uint256 indexed newCount, address indexed by);
    event CountReset(address indexed by);

    /// @notice Increment the counter by 1
    function increment() external {
        count += 1;
        emit CountIncremented(count, msg.sender);
    }

    /// @notice Decrement the counter by 1
    /// @dev Will revert if count is 0 (underflow protection in Solidity 0.8+)
    function decrement() external {
        count -= 1;
        emit CountDecremented(count, msg.sender);
    }

    /// @notice Reset the counter to 0
    function reset() external {
        count = 0;
        emit CountReset(msg.sender);
    }

    /// @notice Get the current count
    /// @return The current count value
    function getCount() external view returns (uint256) {
        return count;
    }
}
