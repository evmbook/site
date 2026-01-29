// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Libraries - Library patterns in Solidity
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates internal and external libraries
/// @dev Chapter 9: Advanced Solidity Patterns - Libraries

// ============ Internal Library (Embedded) ============

/// @notice Math utilities that get embedded into calling contracts
/// @dev Internal functions are inlined at compile time
library MathLib {
    error Overflow();
    error DivisionByZero();

    /// @notice Safe multiplication with overflow check
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        if (c / a != b) revert Overflow();
        return c;
    }

    /// @notice Safe division
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return a / b;
    }

    /// @notice Calculate percentage
    function percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return (amount * bps) / 10000;
    }

    /// @notice Square root using Babylonian method
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Minimum of two numbers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Maximum of two numbers
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @notice Average without overflow
    function avg(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we use this
        return (a & b) + (a ^ b) / 2;
    }
}

// ============ Library for Structs ============

/// @notice Library operating on a custom struct type
library ArrayLib {
    /// @notice Check if array contains a value
    function contains(uint256[] storage arr, uint256 value) internal view returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) return true;
        }
        return false;
    }

    /// @notice Find index of value (-1 if not found)
    function indexOf(uint256[] storage arr, uint256 value) internal view returns (int256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) return int256(i);
        }
        return -1;
    }

    /// @notice Remove element at index (order not preserved)
    function removeUnordered(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    /// @notice Remove element at index (order preserved, more gas)
    function removeOrdered(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        for (uint256 i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    /// @notice Sum all elements
    function sum(uint256[] storage arr) internal view returns (uint256 total) {
        for (uint256 i = 0; i < arr.length; i++) {
            total += arr[i];
        }
    }
}

// ============ Library for Address Operations ============

/// @notice Address utility functions
library AddressLib {
    error CallFailed();
    error InsufficientBalance();

    /// @notice Check if address is a contract
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Safe ETH transfer
    function safeTransferETH(address to, uint256 amount) internal {
        if (address(this).balance < amount) revert InsufficientBalance();
        (bool success,) = to.call{value: amount}("");
        if (!success) revert CallFailed();
    }

    /// @notice Function call with value
    function functionCallWithValue(address target, bytes memory data, uint256 value)
        internal
        returns (bytes memory)
    {
        require(address(this).balance >= value, "Insufficient balance");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata);
    }

    /// @notice Static call (read-only)
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert CallFailed();
        }
        return returndata;
    }
}

// ============ Library for String Operations ============

/// @notice String utilities
library StringLib {
    /// @notice Convert uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    /// @notice Convert address to string (checksummed)
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }

    /// @notice Convert bytes to hex string
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        bytes16 symbols = "0123456789abcdef";

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = symbols[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Hex length insufficient");
        return string(buffer);
    }

    /// @notice Compare two strings
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /// @notice Concatenate strings
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string.concat(a, b);
    }
}

// ============ Using Libraries ============

/// @notice Contract demonstrating library usage
contract LibraryUser {
    // Attach library functions to types
    using MathLib for uint256;
    using ArrayLib for uint256[];
    using AddressLib for address;
    using StringLib for uint256;
    using StringLib for address;

    uint256[] public numbers;

    /// @notice Demonstrate math library
    function mathExample(uint256 a, uint256 b) external pure returns (uint256, uint256, uint256) {
        // Using library functions as methods on uint256
        uint256 product = a.safeMul(b);
        uint256 quotient = a.safeDiv(b);
        uint256 root = a.sqrt();

        return (product, quotient, root);
    }

    /// @notice Demonstrate percentage calculation
    function calculateFee(uint256 amount, uint256 feeBps) external pure returns (uint256) {
        // 500 bps = 5%
        return amount.percentage(feeBps);
    }

    /// @notice Demonstrate array library
    function arrayExample(uint256 value) external {
        numbers.push(value);

        bool found = numbers.contains(value);
        require(found, "Value should be in array");

        int256 index = numbers.indexOf(value);
        require(index >= 0, "Index should be found");
    }

    /// @notice Get array sum
    function getSum() external view returns (uint256) {
        return numbers.sum();
    }

    /// @notice Demonstrate address library
    function isContractAddress(address addr) external view returns (bool) {
        return addr.isContract();
    }

    /// @notice Demonstrate string library
    function numberToString(uint256 value) external pure returns (string memory) {
        return value.toString();
    }

    /// @notice Demonstrate address to string
    function addressToString(address addr) external pure returns (string memory) {
        return addr.toHexString();
    }

    /// @notice Direct library call (alternative syntax)
    function directCall(uint256 a, uint256 b) external pure returns (uint256) {
        // Can also call library directly
        return MathLib.max(a, b);
    }
}

// ============ External Library (Deployed Separately) ============

/// @notice Library with external functions (deployed as contract)
/// @dev Public/external library functions use DELEGATECALL
library ExternalMathLib {
    /// @notice External function - will be delegatecalled
    /// @dev More gas due to call overhead, but saves deployment size
    function complexCalculation(uint256[] calldata values) external pure returns (uint256 result) {
        for (uint256 i = 0; i < values.length; i++) {
            result += values[i] * values[i];
        }
        result = MathLib.sqrt(result);
    }
}

/// @notice Contract using external library
/// @dev Must link library at deployment time
contract ExternalLibraryUser {
    function calculate(uint256[] calldata values) external pure returns (uint256) {
        return ExternalMathLib.complexCalculation(values);
    }
}
