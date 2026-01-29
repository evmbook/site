// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Inheritance - Solidity inheritance patterns
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates single, multiple, and interface inheritance
/// @dev Chapter 8: Solidity Fundamentals - Inheritance

// ============ Interfaces ============

/// @notice Interface defining required functions
interface IAnimal {
    function speak() external view returns (string memory);
    function move() external view returns (string memory);
}

/// @notice Another interface for feeding
interface IFeedable {
    function feed(uint256 amount) external;
    function getHunger() external view returns (uint256);
}

// ============ Abstract Contracts ============

/// @notice Abstract contract with partial implementation
/// @dev Cannot be deployed directly
abstract contract Animal is IAnimal {
    string public name;
    uint256 public age;
    uint256 internal hunger = 100;

    event AnimalCreated(string name, uint256 age);
    event AnimalFed(uint256 amount, uint256 newHunger);

    constructor(string memory _name, uint256 _age) {
        name = _name;
        age = _age;
        emit AnimalCreated(_name, _age);
    }

    /// @notice Must be implemented by child contracts
    function speak() external view virtual returns (string memory);

    /// @notice Default implementation (can be overridden)
    function move() external view virtual returns (string memory) {
        return "The animal moves";
    }

    /// @notice Internal helper
    function _feed(uint256 amount) internal {
        if (hunger >= amount) {
            hunger -= amount;
        } else {
            hunger = 0;
        }
        emit AnimalFed(amount, hunger);
    }
}

// ============ Base Contracts for Multiple Inheritance ============

/// @notice Provides ownership functionality
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @notice Provides pause functionality
contract Pausable {
    bool public paused;

    event Paused();
    event Unpaused();

    error ContractPaused();

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    function _pause() internal {
        paused = true;
        emit Paused();
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused();
    }
}

// ============ Concrete Implementations ============

/// @notice Dog implementation - single inheritance
contract Dog is Animal, IFeedable {
    string public breed;

    constructor(string memory _name, uint256 _age, string memory _breed) Animal(_name, _age) {
        breed = _breed;
    }

    /// @notice Implements abstract function
    function speak() external view override returns (string memory) {
        return string.concat(name, " says: Woof!");
    }

    /// @notice Overrides default implementation
    function move() external view override returns (string memory) {
        return string.concat(name, " runs on four legs");
    }

    /// @notice Implements IFeedable
    function feed(uint256 amount) external override {
        _feed(amount);
    }

    /// @notice Implements IFeedable
    function getHunger() external view override returns (uint256) {
        return hunger;
    }
}

/// @notice Cat implementation - demonstrates different behavior
contract Cat is Animal, IFeedable {
    bool public isIndoor;

    constructor(string memory _name, uint256 _age, bool _isIndoor) Animal(_name, _age) {
        isIndoor = _isIndoor;
    }

    function speak() external view override returns (string memory) {
        return string.concat(name, " says: Meow!");
    }

    function move() external view override returns (string memory) {
        if (isIndoor) {
            return string.concat(name, " lounges on the couch");
        }
        return string.concat(name, " prowls through the garden");
    }

    function feed(uint256 amount) external override {
        _feed(amount);
    }

    function getHunger() external view override returns (uint256) {
        return hunger;
    }
}

// ============ Multiple Inheritance ============

/// @notice Demonstrates multiple inheritance (diamond pattern)
/// @dev Order matters! Most base-like to most derived
contract Pet is Animal, Ownable, Pausable, IFeedable {
    uint256 public lastFed;

    constructor(string memory _name, uint256 _age) Animal(_name, _age) Ownable() {
        lastFed = block.timestamp;
    }

    function speak() external view override returns (string memory) {
        return string.concat(name, " makes a sound");
    }

    function feed(uint256 amount) external override whenNotPaused {
        _feed(amount);
        lastFed = block.timestamp;
    }

    function getHunger() external view override returns (uint256) {
        return hunger;
    }

    /// @notice Only owner can pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Only owner can unpause
    function unpause() external onlyOwner {
        _unpause();
    }
}

// ============ Using super for Parent Calls ============

/// @notice Demonstrates calling parent functions with super
contract SpecialDog is Dog {
    bool public isGoodBoy = true;

    constructor(string memory _name, uint256 _age, string memory _breed)
        Dog(_name, _age, _breed)
    {}

    /// @notice Override with additional behavior
    function speak() external view override returns (string memory) {
        // Could call parent: super.speak() but need to handle external call
        if (isGoodBoy) {
            return string.concat(name, " says: WOOF WOOF! (excitedly)");
        }
        return string.concat(name, " says: Woof!");
    }

    function setGoodBoy(bool _isGoodBoy) external {
        isGoodBoy = _isGoodBoy;
    }
}

// ============ Factory Pattern ============

/// @notice Factory for creating different animal types
contract AnimalFactory {
    event DogCreated(address indexed dog, string name);
    event CatCreated(address indexed cat, string name);

    function createDog(string calldata _name, uint256 _age, string calldata _breed)
        external
        returns (address)
    {
        Dog dog = new Dog(_name, _age, _breed);
        emit DogCreated(address(dog), _name);
        return address(dog);
    }

    function createCat(string calldata _name, uint256 _age, bool _isIndoor)
        external
        returns (address)
    {
        Cat cat = new Cat(_name, _age, _isIndoor);
        emit CatCreated(address(cat), _name);
        return address(cat);
    }
}
