// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ProxyPatterns - Upgradeable proxy pattern demonstrations
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates UUPS, Transparent, and Minimal proxy patterns
/// @dev Chapter 9: Advanced Solidity Patterns - Proxy Contracts

// ============ Minimal Proxy (EIP-1167 Clone) ============

/// @notice Factory for creating minimal proxies (clones)
/// @dev Minimal proxies delegate all calls to an implementation
contract CloneFactory {
    event CloneCreated(address indexed clone, address indexed implementation);

    /// @notice Create a minimal proxy clone
    /// @param implementation The implementation contract to clone
    /// @return clone The address of the new clone
    function createClone(address implementation) external returns (address clone) {
        // EIP-1167 minimal proxy bytecode
        // 3d602d80600a3d3981f3363d3d373d3d3d363d73{implementation}5af43d82803e903d91602b57fd5bf3
        bytes20 implementationBytes = bytes20(implementation);

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), implementationBytes)
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            clone := create(0, ptr, 0x37)
        }

        require(clone != address(0), "Clone creation failed");
        emit CloneCreated(clone, implementation);
    }

    /// @notice Create a clone with deterministic address (CREATE2)
    function createCloneDeterministic(address implementation, bytes32 salt)
        external
        returns (address clone)
    {
        bytes20 implementationBytes = bytes20(implementation);

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), implementationBytes)
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            clone := create2(0, ptr, 0x37, salt)
        }

        require(clone != address(0), "Clone creation failed");
        emit CloneCreated(clone, implementation);
    }

    /// @notice Predict the address of a deterministic clone
    function predictCloneAddress(address implementation, bytes32 salt)
        external
        view
        returns (address predicted)
    {
        bytes20 implementationBytes = bytes20(implementation);
        bytes32 bytecodeHash;

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), implementationBytes)
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            bytecodeHash := keccak256(ptr, 0x37)
        }

        predicted = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))
            )
        );
    }
}

// ============ Simple Implementation for Clones ============

/// @notice Simple token implementation that can be cloned
contract CloneableToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool private initialized;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Initialize the clone (replaces constructor)
    function initialize(string memory _name, string memory _symbol, uint256 _initialSupply)
        external
    {
        require(!initialized, "Already initialized");
        initialized = true;

        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
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

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

// ============ UUPS Proxy Pattern ============

/// @notice UUPS Proxy - upgrade logic lives in implementation
/// @dev EIP-1822: Universal Upgradeable Proxy Standard
contract UUPSProxy {
    // EIP-1967 storage slot for implementation
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation, bytes memory data) {
        _setImplementation(implementation);
        if (data.length > 0) {
            (bool success,) = implementation.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    function _setImplementation(address implementation) private {
        require(implementation.code.length > 0, "Not a contract");
        assembly {
            sstore(IMPLEMENTATION_SLOT, implementation)
        }
    }

    function _getImplementation() internal view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    fallback() external payable {
        address impl = _getImplementation();
        assembly {
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

/// @notice Base contract for UUPS implementations
abstract contract UUPSUpgradeable {
    // EIP-1967 storage slot
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    error NotUUPS();
    error Unauthorized();

    /// @notice Upgrade to a new implementation
    /// @dev Override _authorizeUpgrade to add access control
    function upgradeTo(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, "");
    }

    /// @notice Upgrade and call initialization
    function upgradeToAndCall(address newImplementation, bytes memory data) external {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, data);
    }

    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        // Verify new implementation supports UUPS
        try UUPSUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != IMPLEMENTATION_SLOT) revert NotUUPS();
        } catch {
            revert NotUUPS();
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Upgrade call failed");
        }
    }

    /// @notice Returns the storage slot used for implementation
    function proxiableUUID() external pure returns (bytes32) {
        return IMPLEMENTATION_SLOT;
    }

    /// @notice Override this to add authorization logic
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

/// @notice Example UUPS implementation
contract CounterV1 is UUPSUpgradeable {
    address public owner;
    uint256 public count;
    bool private initialized;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }

    function increment() external {
        count += 1;
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert Unauthorized();
    }
}

/// @notice Upgraded version with new functionality
contract CounterV2 is UUPSUpgradeable {
    address public owner;
    uint256 public count;
    bool private initialized;

    // New state variable (append only!)
    uint256 public lastIncremented;

    function initialize(address _owner) external {
        require(!initialized, "Already initialized");
        initialized = true;
        owner = _owner;
    }

    function increment() external {
        count += 1;
        lastIncremented = block.timestamp;
    }

    // New function in V2
    function decrement() external {
        count -= 1;
        lastIncremented = block.timestamp;
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert Unauthorized();
    }
}

// ============ Transparent Proxy Pattern ============

/// @notice Transparent Proxy - admin functions in proxy, not implementation
/// @dev Admin calls go to proxy, user calls delegated to implementation
contract TransparentProxy {
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    constructor(address implementation, address admin, bytes memory data) {
        _setImplementation(implementation);
        _setAdmin(admin);

        if (data.length > 0) {
            (bool success,) = implementation.delegatecall(data);
            require(success, "Initialization failed");
        }
    }

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function upgradeTo(address newImplementation) external ifAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function changeAdmin(address newAdmin) external ifAdmin {
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }

    function implementation() external ifAdmin returns (address) {
        return _getImplementation();
    }

    function admin() external ifAdmin returns (address) {
        return _getAdmin();
    }

    function _setImplementation(address impl) private {
        require(impl.code.length > 0, "Not a contract");
        assembly {
            sstore(IMPLEMENTATION_SLOT, impl)
        }
    }

    function _getImplementation() private view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    function _setAdmin(address _admin) private {
        assembly {
            sstore(ADMIN_SLOT, _admin)
        }
    }

    function _getAdmin() private view returns (address adm) {
        assembly {
            adm := sload(ADMIN_SLOT)
        }
    }

    function _fallback() private {
        address impl = _getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
