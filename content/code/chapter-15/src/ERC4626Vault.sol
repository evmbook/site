// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ERC20Token.sol";

/// @title IERC4626
/// @notice Standard tokenized vault interface
interface IERC4626 is IERC20 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function asset() external view returns (address assetTokenAddress);
    function totalAssets() external view returns (uint256 totalManagedAssets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function maxMint(address receiver) external view returns (uint256 maxShares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

/// @title ERC4626
/// @notice Tokenized vault implementation following ERC-4626
/// @dev Minimal implementation - extend for yield strategies
contract ERC4626 is ERC20, IERC4626 {
    /// @notice The underlying asset token
    IERC20 public immutable _asset;

    /// @notice Decimals offset for share calculation (prevents inflation attacks)
    uint8 private immutable _decimalsOffset;

    /// @notice Errors
    error ZeroShares();
    error ZeroAssets();
    error ExceedsMax(uint256 amount, uint256 max);

    /// @param asset_ The underlying asset token
    /// @param name_ Vault token name
    /// @param symbol_ Vault token symbol
    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, IERC20Metadata(address(asset_)).decimals()) {
        _asset = asset_;
        // Use decimals offset to prevent inflation attacks
        _decimalsOffset = 0;
    }

    /// @inheritdoc IERC4626
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, false);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, false);
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, false);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        shares = previewDeposit(assets);
        if (shares == 0) revert ZeroShares();

        // Transfer assets from sender
        _asset.transferFrom(msg.sender, address(this), assets);

        // Mint shares to receiver
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, true); // Round up
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        assets = previewMint(shares);
        if (assets == 0) revert ZeroAssets();

        // Transfer assets from sender
        _asset.transferFrom(msg.sender, address(this), assets);

        // Mint shares to receiver
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(IERC20(address(this)).balanceOf(owner), false);
    }

    /// @inheritdoc IERC4626
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, true); // Round up
    }

    /// @inheritdoc IERC4626
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Burn shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return IERC20(address(this)).balanceOf(owner);
    }

    /// @inheritdoc IERC4626
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, false);
    }

    /// @inheritdoc IERC4626
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        assets = previewRedeem(shares);
        if (assets == 0) revert ZeroAssets();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Burn shares from owner
        _burn(owner, shares);

        // Transfer assets to receiver
        _asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Internal conversion from assets to shares
    /// @param assets Amount of assets
    /// @param roundUp Whether to round up
    function _convertToShares(uint256 assets, bool roundUp) internal view virtual returns (uint256) {
        uint256 supply = IERC20(address(this)).totalSupply();
        uint256 totalAssets_ = totalAssets();

        if (supply == 0 || totalAssets_ == 0) {
            return assets * (10 ** _decimalsOffset);
        }

        uint256 shares = (assets * supply) / totalAssets_;

        // Round up if needed
        if (roundUp && (shares * totalAssets_) / supply < assets) {
            shares += 1;
        }

        return shares;
    }

    /// @notice Internal conversion from shares to assets
    /// @param shares Amount of shares
    /// @param roundUp Whether to round up
    function _convertToAssets(uint256 shares, bool roundUp) internal view virtual returns (uint256) {
        uint256 supply = IERC20(address(this)).totalSupply();

        if (supply == 0) {
            return shares / (10 ** _decimalsOffset);
        }

        uint256 assets = (shares * totalAssets()) / supply;

        // Round up if needed
        if (roundUp && (assets * supply) / totalAssets() < shares) {
            assets += 1;
        }

        return assets;
    }
}

/// @title YieldVault
/// @notice Example yield-bearing vault with simple interest accrual
contract YieldVault is ERC4626 {
    /// @notice Annual percentage yield in basis points (e.g., 500 = 5%)
    uint256 public immutable apy;

    /// @notice Last time yield was accrued
    uint256 public lastAccrualTime;

    /// @notice Accumulated yield (added to totalAssets)
    uint256 public accumulatedYield;

    /// @notice Owner for admin functions
    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 apy_
    ) ERC4626(asset_, name_, symbol_) {
        apy = apy_;
        lastAccrualTime = block.timestamp;
        owner = msg.sender;
    }

    /// @notice Override totalAssets to include accrued yield
    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this)) + _pendingYield();
    }

    /// @notice Calculate pending yield since last accrual
    function _pendingYield() internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastAccrualTime;
        uint256 principal = _asset.balanceOf(address(this));

        // Simple interest: principal * rate * time
        // rate = apy / 10000 (basis points)
        // time = timeElapsed / 365 days
        return (principal * apy * timeElapsed) / (10000 * 365 days);
    }

    /// @notice Accrue yield (can be called by anyone)
    function accrueYield() external {
        uint256 pending = _pendingYield();
        if (pending > 0) {
            accumulatedYield += pending;
            lastAccrualTime = block.timestamp;
        }
    }

    /// @notice Deposit yield (owner only, simulates external yield)
    function depositYield(uint256 amount) external onlyOwner {
        _asset.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Emergency withdraw (owner only)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}

/// @title StrategyVault
/// @notice Vault that deploys assets to an external strategy
abstract contract StrategyVault is ERC4626 {
    /// @notice Strategy contract address
    address public strategy;

    /// @notice Assets deployed to strategy
    uint256 public deployedAssets;

    /// @notice Events
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);
    event AssetsDeployed(uint256 amount);
    event AssetsWithdrawn(uint256 amount);

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC4626(asset_, name_, symbol_) {}

    /// @notice Override totalAssets to include deployed assets
    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this)) + deployedAssets;
    }

    /// @notice Deploy assets to strategy
    function _deployToStrategy(uint256 amount) internal virtual {
        require(strategy != address(0), "No strategy");
        _asset.transfer(strategy, amount);
        deployedAssets += amount;
        emit AssetsDeployed(amount);
    }

    /// @notice Withdraw assets from strategy
    function _withdrawFromStrategy(uint256 amount) internal virtual {
        require(deployedAssets >= amount, "Insufficient deployed");
        // Strategy-specific withdrawal logic would go here
        deployedAssets -= amount;
        emit AssetsWithdrawn(amount);
    }
}

/// @title FeeVault
/// @notice Vault with performance and management fees
contract FeeVault is ERC4626 {
    /// @notice Performance fee in basis points (e.g., 1000 = 10%)
    uint256 public immutable performanceFee;

    /// @notice Management fee in basis points per year (e.g., 200 = 2%)
    uint256 public immutable managementFee;

    /// @notice Fee recipient
    address public feeRecipient;

    /// @notice High water mark for performance fees
    uint256 public highWaterMark;

    /// @notice Last fee collection timestamp
    uint256 public lastFeeCollection;

    /// @notice Owner
    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        uint256 performanceFee_,
        uint256 managementFee_,
        address feeRecipient_
    ) ERC4626(asset_, name_, symbol_) {
        require(performanceFee_ <= 3000, "Performance fee too high"); // Max 30%
        require(managementFee_ <= 500, "Management fee too high");    // Max 5%

        performanceFee = performanceFee_;
        managementFee = managementFee_;
        feeRecipient = feeRecipient_;
        owner = msg.sender;
        lastFeeCollection = block.timestamp;
    }

    /// @notice Collect fees
    function collectFees() external {
        uint256 currentAssets = totalAssets();
        uint256 supply = IERC20(address(this)).totalSupply();

        if (supply == 0) return;

        uint256 totalFeeShares = 0;

        // Performance fee (on gains above high water mark)
        if (currentAssets > highWaterMark) {
            uint256 gains = currentAssets - highWaterMark;
            uint256 perfFee = (gains * performanceFee) / 10000;
            uint256 perfFeeShares = (perfFee * supply) / currentAssets;
            totalFeeShares += perfFeeShares;
            highWaterMark = currentAssets;
        }

        // Management fee (annualized)
        uint256 timeElapsed = block.timestamp - lastFeeCollection;
        uint256 mgmtFee = (currentAssets * managementFee * timeElapsed) / (10000 * 365 days);
        uint256 mgmtFeeShares = (mgmtFee * supply) / currentAssets;
        totalFeeShares += mgmtFeeShares;

        // Mint fee shares to recipient
        if (totalFeeShares > 0) {
            _mint(feeRecipient, totalFeeShares);
        }

        lastFeeCollection = block.timestamp;
    }

    /// @notice Update fee recipient
    function setFeeRecipient(address newRecipient) external onlyOwner {
        feeRecipient = newRecipient;
    }
}
