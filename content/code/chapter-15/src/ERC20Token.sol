// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC20
/// @notice Standard ERC-20 interface
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title IERC20Metadata
/// @notice Optional metadata extension for ERC-20
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/// @title ERC20
/// @notice Gas-optimized ERC-20 implementation
/// @dev Implements ERC-20 with standard metadata extension
contract ERC20 is IERC20, IERC20Metadata {
    /// @notice Token balances
    mapping(address => uint256) private _balances;

    /// @notice Token allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Total supply of tokens
    uint256 private _totalSupply;

    /// @notice Token name
    string private _name;

    /// @notice Token symbol
    string private _symbol;

    /// @notice Token decimals (default 18)
    uint8 private immutable _decimals;

    /// @notice Errors
    error InsufficientBalance(address account, uint256 balance, uint256 needed);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error TransferToZeroAddress();
    error ApproveToZeroAddress();
    error MintToZeroAddress();
    error BurnFromZeroAddress();
    error BurnExceedsBalance(address account, uint256 balance, uint256 amount);

    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param decimals_ Token decimals (typically 18)
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /// @inheritdoc IERC20Metadata
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Increase allowance atomically
    /// @param spender Address to increase allowance for
    /// @param addedValue Amount to increase by
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /// @notice Decrease allowance atomically
    /// @param spender Address to decrease allowance for
    /// @param subtractedValue Amount to decrease by
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        if (currentAllowance < subtractedValue) {
            revert InsufficientAllowance(spender, currentAllowance, subtractedValue);
        }
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /// @notice Internal transfer logic
    function _transfer(address from, address to, uint256 amount) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, fromBalance, amount);
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /// @notice Internal mint logic
    function _mint(address to, uint256 amount) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();

        _totalSupply += amount;
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    /// @notice Internal burn logic
    function _burn(address from, uint256 amount) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert BurnExceedsBalance(from, fromBalance, amount);
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /// @notice Internal approve logic
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (spender == address(0)) revert ApproveToZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Spend allowance (used in transferFrom)
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];

        // Infinite approval optimization
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

/// @title ERC20Mintable
/// @notice ERC-20 with minting capability
contract ERC20Mintable is ERC20 {
    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {
        owner = msg.sender;
    }

    /// @notice Mint new tokens (owner only)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burn tokens from caller
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

/// @title ERC20Burnable
/// @notice ERC-20 with burn capability for any holder
contract ERC20Burnable is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply,
        address initialHolder
    ) ERC20(name_, symbol_, decimals_) {
        _mint(initialHolder, initialSupply);
    }

    /// @notice Burn tokens from caller
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Burn tokens from another account (requires allowance)
    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }
}

/// @title ERC20Capped
/// @notice ERC-20 with maximum supply cap
contract ERC20Capped is ERC20Mintable {
    uint256 public immutable cap;

    error CapExceeded(uint256 requested, uint256 cap);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 cap_
    ) ERC20Mintable(name_, symbol_, decimals_) {
        require(cap_ > 0, "Cap must be > 0");
        cap = cap_;
    }

    /// @notice Override mint to enforce cap
    function _mint(address to, uint256 amount) internal override {
        uint256 newSupply;
        unchecked {
            newSupply = totalSupply() + amount;
        }
        if (newSupply > cap) {
            revert CapExceeded(newSupply, cap);
        }
        super._mint(to, amount);
    }

    /// @notice Get total supply (needed for cap check)
    function totalSupply() public view returns (uint256) {
        return IERC20(address(this)).totalSupply();
    }
}

/// @title ERC20Permit
/// @notice ERC-20 with EIP-2612 permit (gasless approvals)
contract ERC20Permit is ERC20 {
    /// @notice EIP-712 domain separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice EIP-2612 permit typehash
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Nonces for permit
    mapping(address => uint256) public nonces;

    /// @notice Errors
    error PermitExpired();
    error InvalidSignature();

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Approve via signature (EIP-2612)
    /// @param owner Token owner
    /// @param spender Spender to approve
    /// @param value Amount to approve
    /// @param deadline Signature expiry timestamp
    /// @param v Signature v
    /// @param r Signature r
    /// @param s Signature s
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) revert PermitExpired();

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0) || signer != owner) revert InvalidSignature();

        _approve(owner, spender, value);
    }
}

/// @title WETH
/// @notice Wrapped Ether - canonical implementation
contract WETH is ERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor() ERC20("Wrapped Ether", "WETH", 18) {}

    /// @notice Deposit ETH and receive WETH
    receive() external payable {
        deposit();
    }

    /// @notice Deposit ETH and receive WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw WETH and receive ETH
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
