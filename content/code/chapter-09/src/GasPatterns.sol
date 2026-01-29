// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title GasPatterns - Gas optimization patterns
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates common gas optimization techniques
/// @dev Chapter 9: Advanced Solidity Patterns - Gas Optimization
contract GasPatterns {
    // ============ Storage Packing ============

    // BAD: Uses 3 storage slots (96 bytes stored, but 3 * 32 = 96 bytes allocated)
    struct UserBad {
        uint256 balance; // Slot 0
        uint256 lastUpdate; // Slot 1
        address owner; // Slot 2 (only uses 20 bytes, wastes 12)
    }

    // GOOD: Uses 2 storage slots
    struct UserGood {
        uint256 balance; // Slot 0 (32 bytes)
        uint96 lastUpdate; // Slot 1 (12 bytes) - fits in same slot as address
        address owner; // Slot 1 (20 bytes)
    }

    // BETTER: Uses 2 storage slots with more data
    struct UserBetter {
        uint128 balance; // Slot 0 (16 bytes)
        uint64 lastUpdate; // Slot 0 (8 bytes)
        uint64 nonce; // Slot 0 (8 bytes) - fills slot 0
        address owner; // Slot 1 (20 bytes)
        uint32 level; // Slot 1 (4 bytes)
        uint32 exp; // Slot 1 (4 bytes)
        bool isActive; // Slot 1 (1 byte)
        // 3 bytes remaining in slot 1
    }

    mapping(address => UserGood) public users;

    // ============ Calldata vs Memory ============

    /// @notice BAD: Uses memory (copies data)
    function processArrayBad(uint256[] memory data) external pure returns (uint256 sum) {
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
    }

    /// @notice GOOD: Uses calldata (no copy)
    function processArrayGood(uint256[] calldata data) external pure returns (uint256 sum) {
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
    }

    /// @notice GOOD: String in calldata
    function processStringGood(string calldata text) external pure returns (uint256) {
        return bytes(text).length;
    }

    // ============ Caching Storage Variables ============

    uint256 public counter;

    /// @notice BAD: Multiple storage reads
    function incrementBad() external {
        counter += 1; // SLOAD
        counter += 1; // SLOAD again
        counter += 1; // SLOAD again
    }

    /// @notice GOOD: Cache in memory
    function incrementGood() external {
        uint256 _counter = counter; // Single SLOAD
        _counter += 1;
        _counter += 1;
        _counter += 1;
        counter = _counter; // Single SSTORE
    }

    // ============ Loop Optimizations ============

    uint256[] public values;

    /// @notice BAD: Storage length in loop condition
    function sumBad() external view returns (uint256 sum) {
        for (uint256 i = 0; i < values.length; i++) {
            // values.length is read from storage every iteration!
            sum += values[i];
        }
    }

    /// @notice GOOD: Cache length
    function sumGood() external view returns (uint256 sum) {
        uint256 len = values.length; // Cache length
        for (uint256 i = 0; i < len; i++) {
            sum += values[i];
        }
    }

    /// @notice BETTER: Unchecked increment (safe in loops)
    function sumBetter() external view returns (uint256 sum) {
        uint256 len = values.length;
        for (uint256 i = 0; i < len;) {
            sum += values[i];
            unchecked {
                ++i;
            } // Safe: i < len
        }
    }

    // ============ Immutable vs Constant ============

    // BEST: Known at compile time
    uint256 public constant MAX_SUPPLY = 1000000;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(...)");

    // GOOD: Set once at deployment, embedded in bytecode
    address public immutable deployer;
    uint256 public immutable deployTime;

    // OK: Regular storage (costs gas to read)
    address public admin;

    constructor() {
        deployer = msg.sender; // Stored in bytecode, not storage
        deployTime = block.timestamp;
        admin = msg.sender; // Stored in storage
    }

    /// @notice Compare access costs
    function accessComparison() external view returns (address, address) {
        // Reading immutable: ~3 gas (from bytecode)
        address d = deployer;
        // Reading storage: ~2100 gas (cold) or ~100 gas (warm)
        address a = admin;
        return (d, a);
    }

    // ============ Short-Circuit Evaluation ============

    /// @notice Use cheaper checks first
    function checkConditions(address user, uint256 amount) external view returns (bool) {
        // GOOD: Cheap checks first
        // 1. Comparison (3 gas)
        // 2. Comparison (3 gas)
        // 3. Storage read (2100 gas cold)
        return amount > 0 && amount <= MAX_SUPPLY && users[user].balance >= amount;
    }

    // ============ Event Optimization ============

    // BAD: Storing data on-chain is expensive
    mapping(address => string) public userNames;

    function setNameBad(string calldata name) external {
        userNames[msg.sender] = name; // Expensive storage
    }

    // GOOD: Emit event instead (if you don't need on-chain access)
    event NameSet(address indexed user, string name);

    function setNameGood(string calldata name) external {
        emit NameSet(msg.sender, name); // ~375 gas base + 8 gas per byte
    }

    // ============ Batch Operations ============

    /// @notice BAD: Multiple transactions
    function transferOne(address to, uint256 amount) external {
        // 21000 base gas PER transaction
        users[to].balance += amount;
    }

    /// @notice GOOD: Batch in one transaction
    function transferBatch(address[] calldata recipients, uint256[] calldata amounts) external {
        // Only 21000 base gas total
        require(recipients.length == amounts.length, "Length mismatch");

        uint256 len = recipients.length;
        for (uint256 i = 0; i < len;) {
            users[recipients[i]].balance += amounts[i];
            unchecked {
                ++i;
            }
        }
    }

    // ============ Error Optimization ============

    /// @notice BAD: String error messages
    function requireWithString(uint256 x) external pure {
        require(x > 0, "Value must be greater than zero"); // Stores string
    }

    /// @notice GOOD: Custom errors
    error ZeroValue();

    function requireWithCustomError(uint256 x) external pure {
        if (x == 0) revert ZeroValue(); // Only 4-byte selector
    }

    // ============ Function Selector Optimization ============

    // Function selectors are sorted, and lower selectors are checked first
    // Functions called frequently should have lower selectors

    // To get a specific selector, you can rename functions:
    // "transfer(address,uint256)" = 0xa9059cbb
    // "transfer_ooa(address,uint256)" = 0x00000001 (if you find the right suffix)

    // In practice: just be aware that function order in dispatch affects gas slightly

    // ============ Zero vs Non-Zero Storage ============

    /// @notice Demonstrate storage cost differences
    function storageDemo() external {
        // Writing non-zero to zero slot: 20,000 gas (SSTORE)
        // Writing non-zero to non-zero slot: 2,900 gas
        // Writing zero to non-zero slot: 2,900 gas + 4,800 gas refund = net ~0 gas
        // Writing zero to zero slot: 2,900 gas (no refund, slot already zero)
    }

    /// @notice Using zero as "deleted" state
    mapping(uint256 => uint256) public data;

    function deleteData(uint256 key) external {
        // Setting to 0 gets a gas refund
        delete data[key]; // Equivalent to data[key] = 0;
    }

    // ============ Avoiding Redundant Checks ============

    /// @notice BAD: Double SafeMath in Solidity 0.8+
    function badMath(uint256 a, uint256 b) external pure returns (uint256) {
        // Solidity 0.8+ already has overflow checking
        // Using SafeMath library adds redundant checks
        return a + b; // Already checked!
    }

    /// @notice When you KNOW overflow is impossible, use unchecked
    function sumWithMax(uint256 a, uint256 b, uint256 max) external pure returns (uint256) {
        require(a <= max && b <= max - a, "Would overflow");
        unchecked {
            return a + b; // We verified it's safe
        }
    }

    // ============ Efficient Comparison ============

    /// @notice Comparing to zero is slightly cheaper than other values
    function isPositive(uint256 x) external pure returns (bool) {
        // return x > 0;     // 3 gas
        return x != 0; // 3 gas (but clearer intent)
    }

    /// @notice Ternary vs conditional
    function absoluteDiff(uint256 a, uint256 b) external pure returns (uint256) {
        // Slightly more efficient than if/else
        return a > b ? a - b : b - a;
    }
}

// ============ Gas Measurement Helper ============

/// @notice Helper to measure gas of operations
contract GasMeter {
    event GasUsed(string operation, uint256 gasUsed);

    function measureGas(address target, bytes calldata data)
        external
        returns (uint256 gasUsed, bytes memory result)
    {
        uint256 gasBefore = gasleft();
        (bool success, bytes memory returnData) = target.call(data);
        gasUsed = gasBefore - gasleft();

        require(success, "Call failed");
        result = returnData;

        emit GasUsed("external call", gasUsed);
    }
}
