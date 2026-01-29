// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title DataTypes - Solidity data type demonstrations
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates all major Solidity data types
/// @dev Chapter 8: Solidity Fundamentals - Understanding data types
contract DataTypes {
    // ============ Value Types ============

    // Boolean
    bool public isActive = true;

    // Integers (signed and unsigned)
    uint256 public maxUint = type(uint256).max; // 2^256 - 1
    int256 public minInt = type(int256).min; // -2^255
    uint8 public smallNumber = 255; // 0 to 255
    int8 public signedSmall = -128; // -128 to 127

    // Address types
    address public owner;
    address payable public treasury;

    // Fixed-size byte arrays
    bytes32 public hash;
    bytes1 public singleByte = 0xff;

    // Enums
    enum Status {
        Pending, // 0
        Active, // 1
        Completed, // 2
        Cancelled // 3
    }
    Status public currentStatus = Status.Pending;

    // ============ Reference Types ============

    // Dynamic arrays
    uint256[] public numbers;

    // Fixed arrays
    uint256[5] public fixedNumbers;

    // Mappings
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    // Structs
    struct User {
        address account;
        uint256 balance;
        bool isRegistered;
        string name;
    }

    mapping(address => User) public users;
    User[] public userList;

    // Dynamic bytes and strings
    bytes public dynamicBytes;
    string public greeting = "Hello, EVM!";

    // ============ Constructor ============

    constructor() {
        owner = msg.sender;
        treasury = payable(msg.sender);
        hash = keccak256(abi.encodePacked("Mastering EVM"));
    }

    // ============ Value Type Operations ============

    /// @notice Toggle the isActive boolean
    function toggleActive() external {
        isActive = !isActive;
    }

    /// @notice Demonstrate safe math (Solidity 0.8+ built-in)
    function safeAddition(uint256 a, uint256 b) external pure returns (uint256) {
        // This will revert on overflow automatically
        return a + b;
    }

    /// @notice Demonstrate unchecked math (use carefully!)
    function uncheckedAddition(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            // This will wrap around on overflow
            return a + b;
        }
    }

    // ============ Enum Operations ============

    /// @notice Update the current status
    function setStatus(Status _status) external {
        currentStatus = _status;
    }

    /// @notice Check if status is active
    function isStatusActive() external view returns (bool) {
        return currentStatus == Status.Active;
    }

    // ============ Array Operations ============

    /// @notice Add a number to the dynamic array
    function addNumber(uint256 _num) external {
        numbers.push(_num);
    }

    /// @notice Remove the last number from the array
    function removeLastNumber() external {
        require(numbers.length > 0, "Array is empty");
        numbers.pop();
    }

    /// @notice Get the length of the numbers array
    function getNumbersLength() external view returns (uint256) {
        return numbers.length;
    }

    /// @notice Get all numbers (be careful with large arrays!)
    function getAllNumbers() external view returns (uint256[] memory) {
        return numbers;
    }

    // ============ Mapping Operations ============

    /// @notice Set balance for an address
    function setBalance(address _account, uint256 _balance) external {
        balances[_account] = _balance;
    }

    /// @notice Set allowance (nested mapping)
    function setAllowance(address _spender, uint256 _amount) external {
        allowances[msg.sender][_spender] = _amount;
    }

    // ============ Struct Operations ============

    /// @notice Register a new user
    function registerUser(string calldata _name) external {
        require(!users[msg.sender].isRegistered, "Already registered");

        User memory newUser = User({
            account: msg.sender,
            balance: 0,
            isRegistered: true,
            name: _name
        });

        users[msg.sender] = newUser;
        userList.push(newUser);
    }

    /// @notice Get user info
    function getUser(address _account)
        external
        view
        returns (address account, uint256 balance, bool isRegistered, string memory name)
    {
        User storage user = users[_account];
        return (user.account, user.balance, user.isRegistered, user.name);
    }

    // ============ Bytes and String Operations ============

    /// @notice Set the greeting string
    function setGreeting(string calldata _greeting) external {
        greeting = _greeting;
    }

    /// @notice Get greeting length (in bytes, not characters!)
    function getGreetingLength() external view returns (uint256) {
        return bytes(greeting).length;
    }

    /// @notice Concatenate strings (Solidity 0.8.12+)
    function concatStrings(string calldata _a, string calldata _b)
        external
        pure
        returns (string memory)
    {
        return string.concat(_a, _b);
    }
}
