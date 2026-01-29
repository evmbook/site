// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Visibility - Function and state variable visibility
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates public, private, internal, and external visibility
/// @dev Chapter 8: Solidity Fundamentals - Understanding visibility
contract Visibility {
    // ============ State Variable Visibility ============

    // Public: Getter automatically generated, accessible everywhere
    uint256 public publicVar = 1;

    // Private: Only accessible within this contract
    uint256 private privateVar = 2;

    // Internal: Accessible within this contract and derived contracts
    uint256 internal internalVar = 3;

    // Note: There is no "external" for state variables

    // ============ Function Visibility ============

    /// @notice Public function - can be called internally and externally
    /// @dev Creates larger bytecode as it supports both call types
    function publicFunction() public pure returns (string memory) {
        return "I am public";
    }

    /// @notice External function - can only be called from outside
    /// @dev More gas efficient for external calls, uses calldata
    function externalFunction() external pure returns (string memory) {
        return "I am external";
    }

    /// @notice Internal function - only this contract and children
    function internalFunction() internal pure returns (string memory) {
        return "I am internal";
    }

    /// @notice Private function - only this contract
    function privateFunction() private pure returns (string memory) {
        return "I am private";
    }

    // ============ Demonstrating Access ============

    /// @notice Demonstrates calling different visibility functions
    function demonstrateAccess() external view returns (uint256, uint256, uint256) {
        // Can access all state variables from within the contract
        uint256 a = publicVar;
        uint256 b = privateVar;
        uint256 c = internalVar;

        // Can call public and internal functions
        publicFunction();
        internalFunction();
        privateFunction();

        // Cannot call external functions internally with this.
        // this.externalFunction() works but wastes gas

        return (a, b, c);
    }

    /// @notice External caller to demonstrate visibility
    function callPublic() external pure returns (string memory) {
        // External functions cannot call external functions on same contract
        // without this. prefix (which costs more gas)
        return publicFunction(); // This works because public
    }
}

/// @title Child - Demonstrates inherited visibility
/// @dev Shows what a child contract can access
contract Child is Visibility {
    /// @notice Demonstrates access from child contract
    function childAccess() external view returns (uint256, uint256) {
        // Can access public and internal state variables
        uint256 a = publicVar;
        // uint256 b = privateVar; // ERROR: private not accessible
        uint256 c = internalVar;

        // Can call public and internal functions
        publicFunction();
        internalFunction();
        // privateFunction(); // ERROR: private not accessible

        return (a, c);
    }
}

/// @title External Contract - Demonstrates external access
/// @dev Shows what an unrelated contract can access
contract ExternalContract {
    Visibility public target;

    constructor(address _target) {
        target = Visibility(_target);
    }

    /// @notice Demonstrates access from external contract
    function externalAccess() external view returns (uint256) {
        // Can only access public state variables (via getter)
        uint256 a = target.publicVar();
        // target.privateVar(); // No getter exists
        // target.internalVar(); // No getter exists

        // Can call public and external functions
        target.publicFunction();
        target.externalFunction();
        // target.internalFunction(); // ERROR: not accessible
        // target.privateFunction(); // ERROR: not accessible

        return a;
    }
}
