// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title SimpleVault - Contract for invariant testing
/// @author Mastering EVM (2025 Edition)
/// @notice A simple vault for demonstrating invariant testing
/// @dev Chapter 11: Testing & Verification - Contract for Invariant Tests
contract SimpleVault {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    error InsufficientBalance();
    error ZeroAmount();
    error ZeroAddress();

    /// @notice Deposit ETH into the vault
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH from the vault
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        totalDeposits -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Transfer balance to another user
    function transfer(address to, uint256 amount) external {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    /// @notice Get user balance
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
