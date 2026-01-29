// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Modifiers - Custom modifiers and access control
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates modifier patterns for access control and validation
/// @dev Chapter 8: Solidity Fundamentals - Modifiers
contract Modifiers {
    // ============ State Variables ============

    address public owner;
    address public pendingOwner;
    bool public paused;
    uint256 public value;

    mapping(address => bool) public admins;
    mapping(address => uint256) public lastAction;

    uint256 public constant COOLDOWN = 1 hours;

    // ============ Events ============

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event ValueUpdated(uint256 indexed oldValue, uint256 indexed newValue);

    // ============ Errors (Custom errors are more gas efficient) ============

    error NotOwner();
    error NotAdmin();
    error NotPendingOwner();
    error ContractPaused();
    error ContractNotPaused();
    error CooldownNotElapsed(uint256 timeRemaining);
    error ZeroAddress();
    error InvalidValue();

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
        emit AdminAdded(msg.sender);
    }

    // ============ Modifiers ============

    /// @notice Restricts function to owner only
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Restricts function to admins
    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin();
        _;
    }

    /// @notice Prevents execution when paused
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    /// @notice Only allows execution when paused
    modifier whenPaused() {
        if (!paused) revert ContractNotPaused();
        _;
    }

    /// @notice Enforces a cooldown between actions
    modifier cooldown() {
        uint256 timeSince = block.timestamp - lastAction[msg.sender];
        if (timeSince < COOLDOWN) {
            revert CooldownNotElapsed(COOLDOWN - timeSince);
        }
        _;
        lastAction[msg.sender] = block.timestamp;
    }

    /// @notice Validates address is not zero
    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert ZeroAddress();
        _;
    }

    /// @notice Validates value is within range
    modifier validValue(uint256 _value) {
        if (_value == 0 || _value > 1000000) revert InvalidValue();
        _;
    }

    /// @notice Modifier with code before AND after function execution
    modifier withLogs() {
        // Code before function
        emit ValueUpdated(value, value);

        _; // Function executes here

        // Code after function (useful for reentrancy guards)
    }

    // ============ Ownership Functions ============

    /// @notice Start ownership transfer (two-step pattern)
    /// @param newOwner The address to transfer ownership to
    function transferOwnership(address newOwner) external onlyOwner validAddress(newOwner) {
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Accept ownership (must be called by pending owner)
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner();

        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, owner);
    }

    // ============ Admin Functions ============

    /// @notice Add a new admin
    function addAdmin(address _admin) external onlyOwner validAddress(_admin) {
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /// @notice Remove an admin
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    // ============ Pause Functions ============

    /// @notice Pause the contract
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // ============ Value Functions ============

    /// @notice Update the value (demonstrates multiple modifiers)
    function updateValue(uint256 _newValue)
        external
        onlyAdmin
        whenNotPaused
        cooldown
        validValue(_newValue)
    {
        uint256 oldValue = value;
        value = _newValue;
        emit ValueUpdated(oldValue, _newValue);
    }

    /// @notice Read function (no modifiers needed for pure reads)
    function getValue() external view returns (uint256) {
        return value;
    }

    // ============ Utility Functions ============

    /// @notice Check time until cooldown expires
    function timeUntilCooldown(address _user) external view returns (uint256) {
        uint256 timeSince = block.timestamp - lastAction[_user];
        if (timeSince >= COOLDOWN) {
            return 0;
        }
        return COOLDOWN - timeSince;
    }
}
