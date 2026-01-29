// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title AccessControl - Secure access control patterns
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates owner, roles, and multi-sig patterns
/// @dev Chapter 10: Smart Contract Security - Access Control

// ============ VULNERABLE PATTERNS ============

/// @notice VULNERABLE: tx.origin for auth
/// @dev NEVER use tx.origin for authorization
contract VulnerableTxOrigin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice VULNERABLE: Phishing attack possible
    /// @dev Attacker can create contract that calls this while victim is tx.origin
    function withdrawAll() external {
        // VULNERABLE: tx.origin is the EOA that initiated the transaction
        // An attacker contract can trick user into calling it, then call this
        require(tx.origin == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
}

/// @notice Attacker contract for tx.origin exploit
contract TxOriginAttacker {
    VulnerableTxOrigin public target;
    address public attacker;

    constructor(address _target) {
        target = VulnerableTxOrigin(_target);
        attacker = msg.sender;
    }

    /// @notice Victim calls this thinking it's a normal function
    function claimReward() external {
        // tx.origin is still the victim
        // This call will pass the tx.origin check!
        target.withdrawAll();
    }

    receive() external payable {
        // Receive stolen funds
        payable(attacker).transfer(address(this).balance);
    }
}

// ============ SECURE: BASIC OWNERSHIP ============

/// @notice Simple single-owner pattern
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner();
    error ZeroAddress();

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Transfer ownership (one-step - risky!)
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Renounce ownership (irreversible!)
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

/// @notice Two-step ownership transfer (safer)
contract Ownable2Step {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner();
    error NotPendingOwner();
    error ZeroAddress();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Step 1: Propose new owner
    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    /// @notice Step 2: New owner accepts
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner();

        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        pendingOwner = address(0);
    }
}

// ============ SECURE: ROLE-BASED ACCESS CONTROL ============

/// @notice Role-based access control (RBAC)
contract RoleBasedAccess {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Role => Account => Has role
    mapping(bytes32 => mapping(address => bool)) private _roles;

    // Role => Admin role that can grant/revoke
    mapping(bytes32 => bytes32) private _roleAdmin;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(
        bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole
    );

    error MissingRole(bytes32 role, address account);

    constructor() {
        // Setup initial admin
        _grantRole(ADMIN_ROLE, msg.sender);

        // Admin role is its own admin (can grant to others)
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        // Admin can grant operator and pauser roles
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
    }

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert MissingRole(role, msg.sender);
        }
        _;
    }

    /// @notice Check if account has role
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /// @notice Get admin role for a role
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmin[role];
    }

    /// @notice Grant role to account
    function grantRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /// @notice Revoke role from account
    function revokeRole(bytes32 role, address account) external onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /// @notice Renounce your own role
    function renounceRole(bytes32 role) external {
        _revokeRole(role, msg.sender);
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    // ============ Example Protected Functions ============

    bool public paused;
    uint256 public value;

    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        paused = false;
    }

    function operate(uint256 _value) external onlyRole(OPERATOR_ROLE) {
        require(!paused, "Paused");
        value = _value;
    }

    function adminFunction() external onlyRole(ADMIN_ROLE) {
        // Only admin can call
    }
}

// ============ SECURE: MULTI-SIGNATURE ============

/// @notice Simple multi-sig wallet
contract MultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required; // Required confirmations

    Transaction[] public transactions;
    // txId => owner => confirmed
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(uint256 indexed txId, address indexed owner);
    event RevokeConfirmation(uint256 indexed txId, address indexed owner);
    event ExecuteTransaction(uint256 indexed txId);

    error NotOwner();
    error TxNotExists();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error TxNotConfirmed();
    error NotEnoughConfirmations();
    error TxFailed();
    error InvalidRequired();
    error InvalidOwners();
    error DuplicateOwner();

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length == 0) revert InvalidOwners();
        if (_required == 0 || _required > _owners.length) revert InvalidRequired();

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert InvalidOwners();
            if (isOwner[owner]) revert DuplicateOwner();

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxNotExists();
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        if (isConfirmed[_txId][msg.sender]) revert TxAlreadyConfirmed();
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Submit a new transaction
    function submitTransaction(address _to, uint256 _value, bytes calldata _data)
        external
        onlyOwner
        returns (uint256 txId)
    {
        txId = transactions.length;

        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false, confirmations: 0})
        );

        emit SubmitTransaction(txId, _to, _value, _data);
    }

    /// @notice Confirm a pending transaction
    function confirmTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.confirmations += 1;
        isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(_txId, msg.sender);
    }

    /// @notice Execute a confirmed transaction
    function executeTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];

        if (transaction.confirmations < required) {
            revert NotEnoughConfirmations();
        }

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) revert TxFailed();

        emit ExecuteTransaction(_txId);
    }

    /// @notice Revoke your confirmation
    function revokeConfirmation(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (!isConfirmed[_txId][msg.sender]) revert TxNotConfirmed();

        Transaction storage transaction = transactions[_txId];
        transaction.confirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;

        emit RevokeConfirmation(_txId, msg.sender);
    }

    /// @notice Get transaction details
    function getTransaction(uint256 _txId)
        external
        view
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations)
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmations
        );
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}

// ============ SECURE: TIMELOCK ============

/// @notice Timelock for governance actions
contract Timelock {
    uint256 public constant MIN_DELAY = 1 days;
    uint256 public constant MAX_DELAY = 30 days;

    address public admin;
    uint256 public delay;

    // txHash => queued
    mapping(bytes32 => bool) public queuedTransactions;

    event NewDelay(uint256 indexed newDelay);
    event QueueTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, bytes data, uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, bytes data, uint256 eta
    );
    event CancelTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, bytes data, uint256 eta
    );

    error NotAdmin();
    error DelayOutOfRange();
    error TxNotQueued();
    error TxStillLocked();
    error TxExpired();
    error TxFailed();

    constructor(uint256 _delay) {
        if (_delay < MIN_DELAY || _delay > MAX_DELAY) revert DelayOutOfRange();
        admin = msg.sender;
        delay = _delay;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// @notice Queue a transaction for execution
    function queueTransaction(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
        returns (bytes32 txHash)
    {
        require(eta >= block.timestamp + delay, "ETA too soon");

        txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, data, eta);
    }

    /// @notice Execute a queued transaction after delay
    function executeTransaction(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
        returns (bytes memory)
    {
        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));

        if (!queuedTransactions[txHash]) revert TxNotQueued();
        if (block.timestamp < eta) revert TxStillLocked();
        if (block.timestamp > eta + 14 days) revert TxExpired();

        queuedTransactions[txHash] = false;

        (bool success, bytes memory returnData) = target.call{value: value}(data);
        if (!success) revert TxFailed();

        emit ExecuteTransaction(txHash, target, value, data, eta);
        return returnData;
    }

    /// @notice Cancel a queued transaction
    function cancelTransaction(address target, uint256 value, bytes calldata data, uint256 eta)
        external
        onlyAdmin
    {
        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = false;
        emit CancelTransaction(txHash, target, value, data, eta);
    }

    receive() external payable {}
}
