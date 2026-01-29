// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title UpgradeableTokenV1 - First version of upgradeable token
/// @author Mastering EVM (2025 Edition)
/// @notice UUPS upgradeable token implementation
/// @dev Chapter 12: Deployment & Upgrades - Upgradeable Contracts

// ============ UUPS PROXY ============

/// @notice Minimal UUPS Proxy
contract ERC1967Proxy {
    // EIP-1967 implementation slot
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation, bytes memory data) {
        assembly {
            sstore(IMPLEMENTATION_SLOT, implementation)
        }
        if (data.length > 0) {
            (bool success,) = implementation.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    fallback() external payable {
        assembly {
            let impl := sload(IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

// ============ IMPLEMENTATION V1 ============

/// @notice Version 1 of the token
contract UpgradeableTokenV1 {
    // Storage layout (MUST be maintained in upgrades)
    // Slot 0
    address public owner;
    // Slot 1
    bool private initialized;
    // Slot 2
    string public name;
    // Slot 3
    string public symbol;
    // Slot 4
    uint256 public totalSupply;
    // Slot 5+
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // EIP-1967 implementation slot
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Upgraded(address indexed implementation);

    error NotOwner();
    error AlreadyInitialized();
    error InsufficientBalance();
    error NotUUPS();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Initialize the token (replaces constructor)
    function initialize(string memory _name, string memory _symbol, uint256 _initialSupply)
        external
    {
        if (initialized) revert AlreadyInitialized();
        initialized = true;

        name = _name;
        symbol = _symbol;
        owner = msg.sender;

        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice UUPS upgrade function
    function upgradeTo(address newImplementation) external onlyOwner {
        // Verify new implementation is UUPS compatible
        try UpgradeableTokenV1(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != IMPLEMENTATION_SLOT) revert NotUUPS();
        } catch {
            revert NotUUPS();
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);
    }

    /// @notice Required for UUPS
    function proxiableUUID() external pure returns (bytes32) {
        return IMPLEMENTATION_SLOT;
    }

    /// @notice Returns version for tracking
    function version() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}

// ============ IMPLEMENTATION V2 ============

/// @notice Version 2 with additional features
contract UpgradeableTokenV2 is UpgradeableTokenV1 {
    // IMPORTANT: Only ADD new storage at the end!
    // Never modify existing storage layout!

    // New storage (appended to V1 layout)
    mapping(address => bool) public blacklisted;
    bool public paused;

    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    error Paused_();
    error Blacklisted_();

    /// @notice Override version
    function version() external pure override returns (string memory) {
        return "2.0.0";
    }

    /// @notice V2 feature: pause transfers
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice V2 feature: blacklist addresses
    function blacklist(address account) external onlyOwner {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(address account) external onlyOwner {
        blacklisted[account] = false;
        emit Unblacklisted(account);
    }

    /// @notice Override transfer with new checks
    function transfer(address to, uint256 amount) external override returns (bool) {
        if (paused) revert Paused_();
        if (blacklisted[msg.sender] || blacklisted[to]) revert Blacklisted_();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}

// ============ STORAGE GAP PATTERN ============

/// @notice Example showing storage gap for future-proofing
contract UpgradeableBase {
    address public owner;
    bool private initialized;

    // Reserve storage slots for future base contract additions
    // This allows adding to the base without breaking child storage
    uint256[50] private __gap;

    function __UpgradeableBase_init() internal {
        require(!initialized);
        initialized = true;
        owner = msg.sender;
    }
}

/// @notice Child contract with reserved gap
contract UpgradeableChild is UpgradeableBase {
    string public name;
    uint256 public value;

    // Reserve storage for this contract's future additions
    uint256[48] private __gap;

    function initialize(string memory _name) external {
        __UpgradeableBase_init();
        name = _name;
    }
}
