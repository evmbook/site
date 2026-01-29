// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ErrorHandling - Error handling patterns in Solidity
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates require, revert, assert, and custom errors
/// @dev Chapter 8: Solidity Fundamentals - Error Handling
contract ErrorHandling {
    // ============ State Variables ============

    mapping(address => uint256) public balances;
    address public owner;
    bool public paused;

    // ============ Custom Errors (Gas Efficient!) ============

    /// @notice Error for insufficient balance
    /// @param available The available balance
    /// @param required The required balance
    error InsufficientBalance(uint256 available, uint256 required);

    /// @notice Error for unauthorized access
    error Unauthorized();

    /// @notice Error for invalid address
    error InvalidAddress(address provided);

    /// @notice Error for contract paused
    error ContractPaused();

    /// @notice Error with no parameters
    error TransferFailed();

    /// @notice Error for zero amount
    error ZeroAmount();

    // ============ Events ============

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
    }

    // ============ Using require() ============

    /// @notice Deposit with require validation
    /// @dev require() is good for input validation
    function depositWithRequire() external payable {
        // require(condition, "error message")
        // If condition is false, reverts with message
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(!paused, "Contract is paused");

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw with require validation
    function withdrawWithRequire(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!paused, "Contract is paused");

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    // ============ Using Custom Errors (Recommended!) ============

    /// @notice Deposit with custom error validation
    /// @dev Custom errors save gas and provide better error info
    function depositWithCustomError() external payable {
        if (msg.value == 0) revert ZeroAmount();
        if (paused) revert ContractPaused();

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw with custom error validation
    function withdrawWithCustomError(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        if (paused) revert ContractPaused();

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Transfer between accounts
    function transfer(address to, uint256 amount) external {
        if (to == address(0)) revert InvalidAddress(to);
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    // ============ Using assert() ============

    /// @notice Demonstrate assert (for invariants only!)
    /// @dev assert() should only check conditions that should NEVER be false
    /// @dev If assert fails, it indicates a bug in the contract
    function demonstrateAssert(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 result = a + b;

        // This should mathematically always be true
        // If it's false, there's a bug (like overflow in older Solidity)
        assert(result >= a);

        return result;
    }

    // ============ Using revert() Directly ============

    /// @notice Complex validation with revert
    /// @dev revert() useful for complex conditional logic
    function complexOperation(uint256 amount, bool option1, bool option2) external view {
        if (paused) {
            revert ContractPaused();
        }

        if (option1 && option2) {
            revert("Cannot select both options");
        }

        if (!option1 && !option2) {
            revert("Must select at least one option");
        }

        if (amount > balances[msg.sender]) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }

        // Continue with operation...
    }

    // ============ Try/Catch for External Calls ============

    /// @notice Safely call an external contract
    /// @dev try/catch only works with external calls and contract creation
    function safeExternalCall(address target, bytes calldata data)
        external
        returns (bool success, bytes memory result)
    {
        try IExternalContract(target).someFunction(data) returns (bytes memory returnData) {
            // Call succeeded
            return (true, returnData);
        } catch Error(string memory reason) {
            // Revert with reason string (require/revert with message)
            return (false, bytes(reason));
        } catch Panic(uint256 errorCode) {
            // Panic (assert failure, overflow, etc.)
            // Error codes: 0x01 = assert, 0x11 = overflow, 0x12 = div by zero
            return (false, abi.encode(errorCode));
        } catch (bytes memory lowLevelData) {
            // Low-level revert (revert without message, custom errors)
            return (false, lowLevelData);
        }
    }

    /// @notice Safe contract creation with try/catch
    function safeCreateContract(uint256 initialValue)
        external
        returns (address newContract)
    {
        try new SimpleContract(initialValue) returns (SimpleContract created) {
            return address(created);
        } catch {
            // Creation failed
            return address(0);
        }
    }

    // ============ Admin Functions ============

    /// @notice Pause the contract
    function pause() external {
        if (msg.sender != owner) revert Unauthorized();
        paused = true;
    }

    /// @notice Unpause the contract
    function unpause() external {
        if (msg.sender != owner) revert Unauthorized();
        paused = false;
    }

    // ============ View Functions ============

    /// @notice Get balance of an account
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice Receive function to accept ETH
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}

// ============ Helper Contracts ============

interface IExternalContract {
    function someFunction(bytes calldata data) external returns (bytes memory);
}

contract SimpleContract {
    uint256 public value;

    constructor(uint256 _value) {
        require(_value > 0, "Value must be positive");
        value = _value;
    }
}

// ============ Gas Comparison Example ============

/// @notice Demonstrates gas difference between require and custom errors
contract GasComparison {
    error CustomError();

    /// @notice Uses require with string - MORE GAS
    function withRequire(uint256 x) external pure returns (uint256) {
        require(x > 0, "Value must be greater than zero");
        return x * 2;
    }

    /// @notice Uses custom error - LESS GAS (~50+ gas saved)
    function withCustomError(uint256 x) external pure returns (uint256) {
        if (x == 0) revert CustomError();
        return x * 2;
    }

    /// @notice Uses require without string - SIMILAR to custom error
    function withRequireNoString(uint256 x) external pure returns (uint256) {
        require(x > 0);
        return x * 2;
    }
}
