// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title CommonVulnerabilities - Common vulnerability patterns and fixes
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates frequent security issues and secure alternatives
/// @dev Chapter 10: Smart Contract Security - Common Vulnerabilities

// ============ INTEGER OVERFLOW (PRE-0.8) ============

/// @notice In Solidity < 0.8, this would overflow!
/// @dev Solidity 0.8+ has built-in overflow checks
contract OverflowDemo {
    /// @notice Safe in 0.8+ - would overflow in earlier versions
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b; // Reverts on overflow in 0.8+
    }

    /// @notice Intentional unchecked math (use carefully!)
    function uncheckedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a + b; // Can overflow!
        }
    }

    /// @notice Safe pattern when you need unchecked but want safety
    function safeUncheckedIncrement(uint256 x) external pure returns (uint256) {
        require(x < type(uint256).max, "Would overflow");
        unchecked {
            return x + 1;
        }
    }
}

// ============ DENIAL OF SERVICE (DoS) ============

/// @notice VULNERABLE: Loop over unbounded array
contract VulnerableDoS {
    address[] public users;
    mapping(address => uint256) public balances;

    function addUser(address user) external {
        users.push(user);
        balances[user] = 1 ether;
    }

    /// @notice VULNERABLE: Can run out of gas with many users
    function distributeRewards(uint256 amount) external {
        // If users array is huge, this will run out of gas
        for (uint256 i = 0; i < users.length; i++) {
            balances[users[i]] += amount;
        }
    }
}

/// @notice SECURE: Paginated distribution
contract SecureDoSMitigation {
    address[] public users;
    mapping(address => uint256) public balances;
    uint256 public lastProcessedIndex;

    /// @notice Process users in batches
    function distributeRewards(uint256 amount, uint256 batchSize) external {
        uint256 end = lastProcessedIndex + batchSize;
        if (end > users.length) {
            end = users.length;
        }

        for (uint256 i = lastProcessedIndex; i < end; i++) {
            balances[users[i]] += amount;
        }

        lastProcessedIndex = end;

        // Reset when done
        if (lastProcessedIndex >= users.length) {
            lastProcessedIndex = 0;
        }
    }
}

/// @notice VULNERABLE: External call in loop
contract VulnerableExternalCallLoop {
    address[] public recipients;
    mapping(address => uint256) public amounts;

    /// @notice VULNERABLE: One revert blocks all payments
    function payAll() external {
        for (uint256 i = 0; i < recipients.length; i++) {
            // If one recipient reverts, entire batch fails
            payable(recipients[i]).transfer(amounts[recipients[i]]);
        }
    }
}

/// @notice SECURE: Pull payment pattern
contract SecurePullPayment {
    mapping(address => uint256) public pendingWithdrawals;

    function credit(address recipient, uint256 amount) internal {
        pendingWithdrawals[recipient] += amount;
    }

    /// @notice Users pull their own funds
    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingWithdrawals[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}

// ============ FRONT-RUNNING ============

/// @notice VULNERABLE: Front-runnable token approval
contract VulnerableFrontRun {
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice VULNERABLE: Attacker can front-run approval change
    /// @dev User changes approval from 100 to 50, attacker sees tx,
    ///      front-runs to spend 100, then spends new 50 = 150 total!
    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
    }
}

/// @notice SECURE: Increase/decrease pattern
contract SecureApproval {
    mapping(address => mapping(address => uint256)) public allowance;

    error AllowanceBelowZero();

    /// @notice Set to zero first, then new amount
    function approve(address spender, uint256 amount) external {
        // Force user to set to 0 first, then set new value
        // This is a workaround - better to use increaseAllowance
        allowance[msg.sender][spender] = amount;
    }

    /// @notice SECURE: Atomically increase allowance
    function increaseAllowance(address spender, uint256 addedValue) external {
        allowance[msg.sender][spender] += addedValue;
    }

    /// @notice SECURE: Atomically decrease allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) external {
        uint256 currentAllowance = allowance[msg.sender][spender];
        if (currentAllowance < subtractedValue) revert AllowanceBelowZero();
        allowance[msg.sender][spender] = currentAllowance - subtractedValue;
    }
}

/// @notice SECURE: Commit-reveal pattern for sensitive operations
contract CommitReveal {
    struct Commit {
        bytes32 hash;
        uint256 blockNumber;
    }

    mapping(address => Commit) public commits;
    uint256 public constant REVEAL_DELAY = 2; // blocks

    event Committed(address indexed user, bytes32 hash);
    event Revealed(address indexed user, bytes32 value);

    error TooSoon();
    error InvalidReveal();
    error NoCommit();

    /// @notice Step 1: Commit hash of your action
    function commit(bytes32 hash) external {
        commits[msg.sender] = Commit({hash: hash, blockNumber: block.number});
        emit Committed(msg.sender, hash);
    }

    /// @notice Step 2: Reveal after delay
    function reveal(bytes32 value, bytes32 salt) external {
        Commit storage c = commits[msg.sender];

        if (c.hash == bytes32(0)) revert NoCommit();
        if (block.number < c.blockNumber + REVEAL_DELAY) revert TooSoon();
        if (keccak256(abi.encodePacked(value, salt)) != c.hash) revert InvalidReveal();

        delete commits[msg.sender];

        // Now execute the action with 'value'
        emit Revealed(msg.sender, value);
    }

    /// @notice Helper to compute commit hash off-chain
    function computeHash(bytes32 value, bytes32 salt) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, salt));
    }
}

// ============ SIGNATURE MALLEABILITY ============

/// @notice VULNERABLE: Signature can be modified while remaining valid
contract VulnerableSignature {
    mapping(bytes32 => bool) public usedSignatures;

    /// @notice VULNERABLE: Malleable signatures
    function executeWithSig(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external {
        // This hash doesn't include the signature itself
        // Attacker can modify (v, r, s) to create different but valid signature
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Invalid signature");

        bytes32 sigHash = keccak256(abi.encodePacked(v, r, s));
        require(!usedSignatures[sigHash], "Signature already used");
        usedSignatures[sigHash] = true;

        // Execute...
    }
}

/// @notice SECURE: Use EIP-712 and check s value
contract SecureSignature {
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant ACTION_TYPEHASH = keccak256("Action(address user,uint256 nonce,bytes data)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    error InvalidSignature();
    error InvalidS();

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH, keccak256("SecureContract"), keccak256("1"), block.chainid, address(this)
            )
        );
    }

    /// @notice SECURE: Proper signature validation
    function executeWithSig(address user, bytes calldata data, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // Check for signature malleability
        // s must be in lower half of curve order
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert InvalidS();
        }

        bytes32 structHash = keccak256(abi.encode(ACTION_TYPEHASH, user, nonces[user]++, keccak256(data)));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address signer = ecrecover(digest, v, r, s);
        if (signer != user || signer == address(0)) {
            revert InvalidSignature();
        }

        // Execute action...
    }
}

// ============ UNCHECKED RETURN VALUES ============

/// @notice VULNERABLE: Not checking return values
contract VulnerableReturnValue {
    /// @notice VULNERABLE: transfer might fail silently for some tokens
    function withdrawToken(address token, uint256 amount) external {
        // Some tokens don't revert on failure, they return false
        IERC20(token).transfer(msg.sender, amount);
        // No check if transfer succeeded!
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @notice SECURE: Check return values
contract SecureReturnValue {
    error TransferFailed();

    /// @notice SECURE: Check transfer return value
    function withdrawToken(address token, uint256 amount) external {
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    /// @notice SECURE: Use safeTransfer pattern
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));

        // Check both call success and return value
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }
}

// ============ DELEGATECALL VULNERABILITIES ============

/// @notice VULNERABLE: Unprotected delegatecall
contract VulnerableDelegatecall {
    address public owner;
    uint256 public balance;

    /// @notice VULNERABLE: Anyone can delegatecall anything!
    function execute(address target, bytes calldata data) external {
        (bool success,) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

/// @notice Attacker can call this via delegatecall to overwrite storage
contract MaliciousContract {
    function attack() external {
        // This runs in context of VulnerableDelegatecall
        // owner is at slot 0
        assembly {
            sstore(0, caller()) // Become owner!
        }
    }
}

/// @notice SECURE: Restricted delegatecall
contract SecureDelegatecall {
    address public owner;
    mapping(address => bool) public allowedTargets;

    error NotOwner();
    error TargetNotAllowed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addAllowedTarget(address target) external onlyOwner {
        allowedTargets[target] = true;
    }

    /// @notice SECURE: Only allow pre-approved targets
    function execute(address target, bytes calldata data) external onlyOwner {
        if (!allowedTargets[target]) revert TargetNotAllowed();
        (bool success,) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

// ============ SELF-DESTRUCT ISSUES ============

/// @notice Note: SELFDESTRUCT behavior changed in EIP-6780 (March 2024)
/// @dev Now only destroys contract if created in same tx
contract SelfDestructDemo {
    /// @notice Post EIP-6780: Only transfers ETH, doesn't destroy unless same-tx created
    function destroy(address payable recipient) external {
        // This will:
        // - Always transfer all ETH to recipient
        // - Only destroy contract code if created in same transaction
        selfdestruct(recipient);
    }
}

/// @notice VULNERABLE: Relying on address balance
contract VulnerableBalanceCheck {
    /// @notice VULNERABLE: Contract can receive ETH via selfdestruct
    /// @dev Even without receive/fallback, selfdestruct can force ETH
    function hasNoBalance() external view returns (bool) {
        // This can be false even if contract has no receive()!
        return address(this).balance == 0;
    }
}

/// @notice SECURE: Track deposits explicitly
contract SecureBalanceTracking {
    uint256 public trackedBalance;

    function deposit() external payable {
        trackedBalance += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(trackedBalance >= amount, "Insufficient tracked balance");
        trackedBalance -= amount;
        // Use tracked balance, not address(this).balance
        payable(msg.sender).transfer(amount);
    }
}
