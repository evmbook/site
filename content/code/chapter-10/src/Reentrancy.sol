// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Reentrancy - Demonstrating reentrancy vulnerabilities and protections
/// @author Mastering EVM (2025 Edition)
/// @notice Shows vulnerable code and secure patterns
/// @dev Chapter 10: Smart Contract Security - Reentrancy Attacks

// ============ VULNERABLE CONTRACT - DO NOT USE IN PRODUCTION ============

/// @notice VULNERABLE: Classic reentrancy vulnerability
/// @dev This contract is intentionally vulnerable for educational purposes
contract VulnerableBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /// @notice VULNERABLE: State update AFTER external call
    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // VULNERABLE: External call BEFORE state update
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        // State update happens AFTER the call
        // Attacker can re-enter before this line executes
        balances[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

/// @notice Attacker contract that exploits reentrancy
contract ReentrancyAttacker {
    VulnerableBank public target;
    uint256 public attackCount;

    constructor(address _target) {
        target = VulnerableBank(_target);
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ether");

        // First, deposit some ETH
        target.deposit{value: msg.value}();

        // Then trigger the reentrancy
        target.withdraw();
    }

    // This gets called when the vulnerable contract sends ETH
    receive() external payable {
        attackCount++;
        // Re-enter if there's still ETH in the contract
        if (address(target).balance >= 1 ether) {
            target.withdraw();
        }
    }

    function getStolen() external view returns (uint256) {
        return address(this).balance;
    }
}

// ============ SECURE PATTERNS ============

/// @notice Pattern 1: Checks-Effects-Interactions (CEI)
/// @dev Always update state BEFORE making external calls
contract SecureBankCEI {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // CHECKS: Verify conditions
        // (already done above)

        // EFFECTS: Update state FIRST
        balances[msg.sender] = 0;

        // INTERACTIONS: External call LAST
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, balance);
    }
}

/// @notice Pattern 2: Reentrancy Guard (Mutex)
/// @dev Use a lock to prevent reentrant calls
contract SecureBankGuard {
    mapping(address => uint256) public balances;

    // Reentrancy lock
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private _status = NOT_ENTERED;

    error ReentrancyGuardReentrantCall();

    modifier nonReentrant() {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /// @notice Protected by reentrancy guard
    function withdraw() external nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // Even with external call first, reentrancy blocked by guard
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }
}

/// @notice Pattern 3: Transient Storage Guard (EIP-1153)
/// @dev Most gas-efficient reentrancy guard using transient storage
contract SecureBankTransient {
    mapping(address => uint256) public balances;

    // Transient storage slot for guard
    bytes32 private constant GUARD_SLOT = keccak256("REENTRANCY_GUARD");

    error ReentrancyGuard();

    modifier nonReentrant() {
        assembly {
            if tload(GUARD_SLOT) {
                mstore(0, 0x37ed32e8) // ReentrancyGuard()
                revert(0x1c, 0x04)
            }
            tstore(GUARD_SLOT, 1)
        }
        _;
        assembly {
            tstore(GUARD_SLOT, 0)
        }
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}

/// @notice Pattern 4: Pull Payment (safest pattern)
/// @dev Users withdraw their own funds
contract SecureBankPull {
    mapping(address => uint256) public pendingWithdrawals;

    event Credited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Credit user with funds (internal accounting only)
    function credit(address user, uint256 amount) internal {
        pendingWithdrawals[user] += amount;
        emit Credited(user, amount);
    }

    /// @notice User pulls their own funds
    function withdrawPayment() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // CEI pattern: update state before transfer
        pendingWithdrawals[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    receive() external payable {
        credit(msg.sender, msg.value);
    }
}

// ============ CROSS-FUNCTION REENTRANCY ============

/// @notice VULNERABLE: Cross-function reentrancy
/// @dev Reentrancy can occur across multiple functions sharing state
contract VulnerableCrossFunction {
    mapping(address => uint256) public balances;
    mapping(address => bool) public hasBonus;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /// @notice VULNERABLE: Can be exploited via claimBonus
    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }

    /// @notice Can be called during withdraw's external call
    function claimBonus() external {
        require(!hasBonus[msg.sender], "Already claimed");
        require(balances[msg.sender] > 0, "Must have balance");

        hasBonus[msg.sender] = true;
        // Attacker can claim bonus during withdraw() before balance is zeroed
        balances[msg.sender] += 1 ether;
    }
}

/// @notice SECURE: Reentrancy guard protects ALL state-changing functions
contract SecureCrossFunction {
    mapping(address => uint256) public balances;
    mapping(address => bool) public hasBonus;

    uint256 private _status = 1;

    modifier nonReentrant() {
        require(_status == 1, "Reentrant");
        _status = 2;
        _;
        _status = 1;
    }

    function deposit() external payable nonReentrant {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    function claimBonus() external nonReentrant {
        require(!hasBonus[msg.sender], "Already claimed");
        require(balances[msg.sender] > 0, "Must have balance");

        hasBonus[msg.sender] = true;
        balances[msg.sender] += 1 ether;
    }
}

// ============ READ-ONLY REENTRANCY ============

/// @notice VULNERABLE: Read-only reentrancy via view functions
/// @dev External contracts may read stale state during reentrancy
contract VulnerablePriceOracle {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // VULNERABLE: totalDeposits not updated yet during this call
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
        totalDeposits -= balance;
    }

    /// @notice Other contracts may call this during reentrancy
    /// @dev Returns incorrect value if called during withdraw's external call
    function getSharePrice() external view returns (uint256) {
        if (totalDeposits == 0) return 1e18;
        return (address(this).balance * 1e18) / totalDeposits;
    }
}

/// @notice SECURE: Update state before external calls
contract SecurePriceOracle {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    uint256 private _status = 1;

    modifier nonReentrant() {
        require(_status == 1, "Reentrant");
        _status = 2;
        _;
        _status = 1;
    }

    function deposit() external payable nonReentrant {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");

        // Update ALL relevant state before external call
        balances[msg.sender] = 0;
        totalDeposits -= balance;

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    function getSharePrice() external view returns (uint256) {
        if (totalDeposits == 0) return 1e18;
        return (address(this).balance * 1e18) / totalDeposits;
    }
}
