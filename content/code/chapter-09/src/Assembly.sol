// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Assembly - Inline assembly patterns
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates Yul/inline assembly for gas optimization
/// @dev Chapter 9: Advanced Solidity Patterns - Inline Assembly
contract Assembly {
    // ============ Basic Operations ============

    /// @notice Add two numbers using assembly
    function assemblyAdd(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := add(a, b)
        }
    }

    /// @notice Multiple operations in assembly
    function assemblyMath(uint256 a, uint256 b)
        external
        pure
        returns (uint256 sum, uint256 product, uint256 quotient)
    {
        assembly {
            sum := add(a, b)
            product := mul(a, b)
            // div by zero returns 0 in assembly (no revert!)
            quotient := div(a, b)
        }
    }

    // ============ Memory Operations ============

    /// @notice Read and write to memory
    function memoryOperations() external pure returns (bytes32 value) {
        assembly {
            // Get free memory pointer
            let ptr := mload(0x40)

            // Store value at ptr
            mstore(ptr, 0x123456)

            // Load value back
            value := mload(ptr)

            // Update free memory pointer (ptr + 32 bytes)
            mstore(0x40, add(ptr, 0x20))
        }
    }

    /// @notice Efficient memory copy
    function memoryCopy(bytes calldata data) external pure returns (bytes memory) {
        bytes memory result = new bytes(data.length);

        assembly {
            // Copy calldata to memory
            // result points to length, add 32 to get data start
            calldatacopy(add(result, 0x20), data.offset, data.length)
        }

        return result;
    }

    // ============ Storage Operations ============

    uint256 private storedValue;
    mapping(uint256 => uint256) private map;

    /// @notice Direct storage slot access
    function storageSlotAccess(uint256 slot) external view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }

    /// @notice Write to storage slot directly
    function writeStorageSlot(uint256 slot, bytes32 value) external {
        assembly {
            sstore(slot, value)
        }
    }

    /// @notice Calculate mapping slot
    function getMappingSlot(uint256 key, uint256 mappingSlot)
        external
        pure
        returns (bytes32 slot)
    {
        assembly {
            // keccak256(key . slot)
            mstore(0x00, key)
            mstore(0x20, mappingSlot)
            slot := keccak256(0x00, 0x40)
        }
    }

    /// @notice Read mapping value via slot calculation
    function readMapping(uint256 key) external view returns (uint256 value) {
        assembly {
            // map is at slot 1 (after storedValue at slot 0)
            mstore(0x00, key)
            mstore(0x20, 1) // slot of mapping
            let slot := keccak256(0x00, 0x40)
            value := sload(slot)
        }
    }

    // ============ Calldata Operations ============

    /// @notice Extract function selector from calldata
    function getSelector() external pure returns (bytes4 selector) {
        assembly {
            // Load first 4 bytes of calldata
            selector := calldataload(0)
        }
    }

    /// @notice Efficient calldata parameter reading
    function readCalldataParams(bytes calldata data)
        external
        pure
        returns (bytes32 first, bytes32 second)
    {
        assembly {
            // Read 32 bytes starting at data.offset
            first := calldataload(data.offset)
            // Read next 32 bytes
            second := calldataload(add(data.offset, 0x20))
        }
    }

    // ============ Control Flow ============

    /// @notice If-else in assembly
    function assemblyConditional(uint256 x) external pure returns (uint256 result) {
        assembly {
            // if x > 10
            if gt(x, 10) { result := mul(x, 2) }
            // else (using iszero for negation)
            if iszero(gt(x, 10)) { result := add(x, 5) }
        }
    }

    /// @notice Switch statement in assembly
    function assemblySwitch(uint256 x) external pure returns (uint256 result) {
        assembly {
            switch x
            case 0 { result := 100 }
            case 1 { result := 200 }
            case 2 { result := 300 }
            default { result := 999 }
        }
    }

    /// @notice For loop in assembly
    function assemblyLoop(uint256 n) external pure returns (uint256 sum) {
        assembly {
            // for (let i := 0; i < n; i++)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } { sum := add(sum, i) }
        }
    }

    // ============ Bit Operations ============

    /// @notice Pack two uint128s into one uint256
    function pack(uint128 a, uint128 b) external pure returns (uint256 packed) {
        assembly {
            // Shift a left by 128 bits and OR with b
            packed := or(shl(128, a), b)
        }
    }

    /// @notice Unpack uint256 into two uint128s
    function unpack(uint256 packed) external pure returns (uint128 a, uint128 b) {
        assembly {
            // Upper 128 bits
            a := shr(128, packed)
            // Lower 128 bits (mask with 128 1s)
            b := and(packed, 0xffffffffffffffffffffffffffffffff)
        }
    }

    /// @notice Check if bit is set
    function isBitSet(uint256 value, uint8 bitIndex) external pure returns (bool) {
        assembly {
            // Shift 1 left by bitIndex, AND with value
            // If result is non-zero, bit is set
            mstore(0x00, and(value, shl(bitIndex, 1)))
            return(0x00, 0x20)
        }
    }

    // ============ Low-Level Calls ============

    /// @notice Make a low-level call with assembly
    function assemblyCall(address target, bytes calldata data)
        external
        returns (bool success, bytes memory returnData)
    {
        assembly {
            // Allocate memory for return data
            let ptr := mload(0x40)

            // Copy calldata to memory
            calldatacopy(ptr, data.offset, data.length)

            // Make the call
            success := call(gas(), target, 0, ptr, data.length, 0, 0)

            // Get return data size
            let returnSize := returndatasize()

            // Allocate memory for return data
            returnData := mload(0x40)
            mstore(returnData, returnSize)
            mstore(0x40, add(add(returnData, 0x20), returnSize))

            // Copy return data
            returndatacopy(add(returnData, 0x20), 0, returnSize)
        }
    }

    /// @notice Efficient ETH transfer
    function assemblyTransfer(address to, uint256 amount) external returns (bool success) {
        assembly {
            // call(gas, address, value, inputOffset, inputSize, outputOffset, outputSize)
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
    }

    // ============ Gas-Efficient Patterns ============

    /// @notice Revert with custom error (gas efficient)
    function efficientRevert(uint256 x) external pure {
        assembly {
            if iszero(x) {
                // Store error selector: keccak256("ZeroValue()")[:4]
                mstore(0x00, 0x7c946ed7)
                revert(0x1c, 0x04) // Revert with 4 bytes
            }
        }
    }

    /// @notice Return early (skip Solidity overhead)
    function earlyReturn(uint256 x) external pure returns (uint256) {
        assembly {
            if gt(x, 100) {
                mstore(0x00, x)
                return(0x00, 0x20)
            }
        }
        return x * 2;
    }

    /// @notice Efficient array sum (no bounds checking)
    function efficientSum(uint256[] calldata arr) external pure returns (uint256 sum) {
        assembly {
            let len := arr.length
            let offset := arr.offset

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                sum := add(sum, calldataload(add(offset, mul(i, 0x20))))
            }
        }
    }

    // ============ Contract Introspection ============

    /// @notice Get contract's own code
    function getCode() external view returns (bytes memory code) {
        assembly {
            let size := codesize()
            code := mload(0x40)
            mstore(code, size)
            codecopy(add(code, 0x20), 0, size)
            mstore(0x40, add(add(code, 0x20), size))
        }
    }

    /// @notice Get code of another address
    function getExtCode(address target) external view returns (bytes memory code) {
        assembly {
            let size := extcodesize(target)
            code := mload(0x40)
            mstore(code, size)
            extcodecopy(target, add(code, 0x20), 0, size)
            mstore(0x40, add(add(code, 0x20), size))
        }
    }

    /// @notice Get code hash of address
    function getCodeHash(address target) external view returns (bytes32 hash) {
        assembly {
            hash := extcodehash(target)
        }
    }
}

// ============ Transient Storage (EIP-1153) ============

/// @notice Demonstrates transient storage for reentrancy guards
/// @dev Transient storage is cheaper and auto-clears after transaction
contract TransientStorage {
    // Transient storage slot for reentrancy guard
    bytes32 private constant REENTRANCY_SLOT = keccak256("REENTRANCY_GUARD");

    error ReentrancyGuard();

    modifier nonReentrant() {
        assembly {
            // Check if already entered (TLOAD)
            if tload(REENTRANCY_SLOT) {
                // Store error selector and revert
                mstore(0, 0xab143c06) // ReentrancyGuard selector
                revert(0x1c, 0x04)
            }
            // Set entered flag (TSTORE)
            tstore(REENTRANCY_SLOT, 1)
        }

        _;

        assembly {
            // Clear entered flag (auto-clears anyway, but explicit)
            tstore(REENTRANCY_SLOT, 0)
        }
    }

    /// @notice Protected function
    function protectedFunction() external nonReentrant {
        // Safe from reentrancy
    }

    /// @notice Use transient storage for temporary data
    function useTransient(uint256 value) external returns (uint256) {
        bytes32 slot = keccak256("TEMP_VALUE");

        assembly {
            // Store temporarily (cleared after tx)
            tstore(slot, value)
        }

        // Do something...

        uint256 result;
        assembly {
            // Read back
            result := tload(slot)
        }

        return result;
    }
}
