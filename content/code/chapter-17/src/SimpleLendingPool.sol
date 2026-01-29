// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

/// @title IOracle
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

/// @title SimpleLendingPool
/// @notice Educational lending pool with collateralized borrowing
/// @dev Simplified Aave/Compound-style lending protocol
contract SimpleLendingPool {
    /// @notice Asset configuration
    struct AssetConfig {
        uint256 collateralFactor;   // In basis points (e.g., 7500 = 75%)
        uint256 liquidationBonus;   // In basis points (e.g., 500 = 5%)
        uint256 reserveFactor;      // In basis points (e.g., 1000 = 10%)
        bool isActive;
        bool canBeCollateral;
        bool canBeBorrowed;
    }

    /// @notice User account data
    struct UserAccount {
        mapping(address => uint256) supplied;      // Supplied amounts per asset
        mapping(address => uint256) borrowed;      // Borrowed amounts per asset
        mapping(address => uint256) borrowIndex;   // Index at time of borrow
    }

    /// @notice Market state
    struct Market {
        uint256 totalSupply;
        uint256 totalBorrows;
        uint256 borrowIndex;        // Accumulated borrow interest
        uint256 lastUpdateTime;
        uint256 reserveBalance;
    }

    /// @notice Price oracle
    IOracle public oracle;

    /// @notice Owner
    address public owner;

    /// @notice Supported assets
    address[] public assets;
    mapping(address => bool) public isAssetListed;
    mapping(address => AssetConfig) public assetConfigs;
    mapping(address => Market) public markets;
    mapping(address => UserAccount) private userAccounts;

    /// @notice Interest rate model parameters (per second)
    uint256 public constant BASE_RATE = 0;                        // 0%
    uint256 public constant MULTIPLIER = 47564687975;             // ~15% at 100% utilization
    uint256 public constant JUMP_MULTIPLIER = 951293759512;       // ~300% above kink
    uint256 public constant KINK = 8000;                          // 80% utilization

    /// @notice Constants
    uint256 public constant BPS = 10000;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    /// @notice Events
    event Supply(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Borrow(address indexed user, address indexed asset, uint256 amount);
    event Repay(address indexed user, address indexed asset, uint256 amount);
    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        address indexed collateralAsset,
        address debtAsset,
        uint256 debtRepaid,
        uint256 collateralSeized
    );

    /// @notice Errors
    error NotOwner();
    error AssetNotListed();
    error AssetNotBorrowable();
    error AssetNotCollateral();
    error InsufficientCollateral();
    error InsufficientLiquidity();
    error HealthyPosition();
    error InvalidAmount();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
        owner = msg.sender;
    }

    /// @notice Add a new asset to the protocol
    function addAsset(
        address asset,
        uint256 collateralFactor,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool canBeCollateral,
        bool canBeBorrowed
    ) external onlyOwner {
        require(!isAssetListed[asset], "Already listed");

        assets.push(asset);
        isAssetListed[asset] = true;

        assetConfigs[asset] = AssetConfig({
            collateralFactor: collateralFactor,
            liquidationBonus: liquidationBonus,
            reserveFactor: reserveFactor,
            isActive: true,
            canBeCollateral: canBeCollateral,
            canBeBorrowed: canBeBorrowed
        });

        markets[asset] = Market({
            totalSupply: 0,
            totalBorrows: 0,
            borrowIndex: PRECISION,
            lastUpdateTime: block.timestamp,
            reserveBalance: 0
        });
    }

    /// @notice Supply assets to earn interest
    function supply(address asset, uint256 amount) external {
        if (!isAssetListed[asset]) revert AssetNotListed();
        if (amount == 0) revert InvalidAmount();

        // Accrue interest first
        _accrueInterest(asset);

        // Transfer tokens
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Update state
        userAccounts[msg.sender].supplied[asset] += amount;
        markets[asset].totalSupply += amount;

        emit Supply(msg.sender, asset, amount);
    }

    /// @notice Withdraw supplied assets
    function withdraw(address asset, uint256 amount) external {
        if (!isAssetListed[asset]) revert AssetNotListed();

        _accrueInterest(asset);

        UserAccount storage account = userAccounts[msg.sender];
        uint256 supplied = account.supplied[asset];

        if (amount > supplied) revert InvalidAmount();

        // Check if withdrawal would make position unhealthy
        account.supplied[asset] -= amount;
        if (!_isHealthy(msg.sender)) {
            account.supplied[asset] += amount; // Revert state
            revert InsufficientCollateral();
        }

        // Check liquidity
        uint256 available = IERC20(asset).balanceOf(address(this));
        if (amount > available) revert InsufficientLiquidity();

        markets[asset].totalSupply -= amount;
        IERC20(asset).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, asset, amount);
    }

    /// @notice Borrow assets against collateral
    function borrow(address asset, uint256 amount) external {
        if (!isAssetListed[asset]) revert AssetNotListed();
        if (!assetConfigs[asset].canBeBorrowed) revert AssetNotBorrowable();
        if (amount == 0) revert InvalidAmount();

        _accrueInterest(asset);

        Market storage market = markets[asset];
        UserAccount storage account = userAccounts[msg.sender];

        // Check liquidity
        uint256 available = IERC20(asset).balanceOf(address(this));
        if (amount > available) revert InsufficientLiquidity();

        // Update borrow state
        account.borrowed[asset] += amount;
        account.borrowIndex[asset] = market.borrowIndex;
        market.totalBorrows += amount;

        // Check health factor
        if (!_isHealthy(msg.sender)) {
            // Revert state changes
            account.borrowed[asset] -= amount;
            market.totalBorrows -= amount;
            revert InsufficientCollateral();
        }

        IERC20(asset).transfer(msg.sender, amount);

        emit Borrow(msg.sender, asset, amount);
    }

    /// @notice Repay borrowed assets
    function repay(address asset, uint256 amount) external {
        if (!isAssetListed[asset]) revert AssetNotListed();

        _accrueInterest(asset);

        UserAccount storage account = userAccounts[msg.sender];
        uint256 currentDebt = _getCurrentDebt(msg.sender, asset);

        if (amount > currentDebt) {
            amount = currentDebt;
        }

        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        account.borrowed[asset] = currentDebt - amount;
        account.borrowIndex[asset] = markets[asset].borrowIndex;
        markets[asset].totalBorrows -= amount;

        emit Repay(msg.sender, asset, amount);
    }

    /// @notice Liquidate an unhealthy position
    function liquidate(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToRepay
    ) external {
        if (!assetConfigs[collateralAsset].canBeCollateral) revert AssetNotCollateral();

        _accrueInterest(collateralAsset);
        _accrueInterest(debtAsset);

        // Check if position is liquidatable
        if (_isHealthy(borrower)) revert HealthyPosition();

        UserAccount storage borrowerAccount = userAccounts[borrower];
        uint256 currentDebt = _getCurrentDebt(borrower, debtAsset);

        // Limit to 50% of debt (close factor)
        uint256 maxRepay = (currentDebt * 5000) / BPS;
        if (debtToRepay > maxRepay) {
            debtToRepay = maxRepay;
        }

        // Calculate collateral to seize (with bonus)
        uint256 debtValue = (debtToRepay * oracle.getPrice(debtAsset)) / PRECISION;
        uint256 collateralPrice = oracle.getPrice(collateralAsset);
        uint256 collateralBonus = assetConfigs[collateralAsset].liquidationBonus;
        uint256 collateralToSeize = (debtValue * (BPS + collateralBonus)) / BPS * PRECISION / collateralPrice;

        // Check borrower has enough collateral
        uint256 borrowerCollateral = borrowerAccount.supplied[collateralAsset];
        if (collateralToSeize > borrowerCollateral) {
            collateralToSeize = borrowerCollateral;
        }

        // Execute liquidation
        IERC20(debtAsset).transferFrom(msg.sender, address(this), debtToRepay);

        borrowerAccount.borrowed[debtAsset] = currentDebt - debtToRepay;
        borrowerAccount.borrowIndex[debtAsset] = markets[debtAsset].borrowIndex;
        markets[debtAsset].totalBorrows -= debtToRepay;

        borrowerAccount.supplied[collateralAsset] -= collateralToSeize;
        markets[collateralAsset].totalSupply -= collateralToSeize;

        IERC20(collateralAsset).transfer(msg.sender, collateralToSeize);

        emit Liquidation(msg.sender, borrower, collateralAsset, debtAsset, debtToRepay, collateralToSeize);
    }

    /// @notice Accrue interest for an asset
    function _accrueInterest(address asset) internal {
        Market storage market = markets[asset];
        uint256 timeElapsed = block.timestamp - market.lastUpdateTime;

        if (timeElapsed == 0) return;

        uint256 borrowRate = getBorrowRate(asset);
        uint256 interestAccumulated = (market.totalBorrows * borrowRate * timeElapsed) / PRECISION;

        // Update borrow index
        if (market.totalBorrows > 0) {
            market.borrowIndex += (interestAccumulated * PRECISION) / market.totalBorrows;
        }

        // Add interest to total borrows and reserves
        uint256 reserveAmount = (interestAccumulated * assetConfigs[asset].reserveFactor) / BPS;
        market.totalBorrows += interestAccumulated;
        market.reserveBalance += reserveAmount;
        market.lastUpdateTime = block.timestamp;
    }

    /// @notice Get current borrow rate per second
    function getBorrowRate(address asset) public view returns (uint256) {
        Market storage market = markets[asset];

        if (market.totalSupply == 0) return BASE_RATE;

        uint256 utilization = (market.totalBorrows * BPS) / market.totalSupply;

        if (utilization <= KINK) {
            return BASE_RATE + (utilization * MULTIPLIER) / BPS;
        } else {
            uint256 normalRate = BASE_RATE + (KINK * MULTIPLIER) / BPS;
            uint256 excessUtilization = utilization - KINK;
            return normalRate + (excessUtilization * JUMP_MULTIPLIER) / BPS;
        }
    }

    /// @notice Get current supply rate per second
    function getSupplyRate(address asset) public view returns (uint256) {
        Market storage market = markets[asset];

        if (market.totalSupply == 0) return 0;

        uint256 utilization = (market.totalBorrows * BPS) / market.totalSupply;
        uint256 borrowRate = getBorrowRate(asset);
        uint256 reserveFactor = assetConfigs[asset].reserveFactor;

        return (borrowRate * utilization * (BPS - reserveFactor)) / (BPS * BPS);
    }

    /// @notice Get user's current debt including accrued interest
    function _getCurrentDebt(address user, address asset) internal view returns (uint256) {
        UserAccount storage account = userAccounts[user];
        uint256 principalBorrowed = account.borrowed[asset];

        if (principalBorrowed == 0) return 0;

        uint256 userIndex = account.borrowIndex[asset];
        uint256 currentIndex = markets[asset].borrowIndex;

        return (principalBorrowed * currentIndex) / userIndex;
    }

    /// @notice Check if a user's position is healthy
    function _isHealthy(address user) internal view returns (bool) {
        (uint256 totalCollateralValue, uint256 totalBorrowValue) = getAccountLiquidity(user);
        return totalCollateralValue >= totalBorrowValue;
    }

    /// @notice Get user's total collateral and borrow values
    function getAccountLiquidity(address user) public view returns (
        uint256 totalCollateralValue,
        uint256 totalBorrowValue
    ) {
        UserAccount storage account = userAccounts[user];

        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            AssetConfig storage config = assetConfigs[asset];
            uint256 price = oracle.getPrice(asset);

            // Collateral value (adjusted by collateral factor)
            uint256 supplied = account.supplied[asset];
            if (supplied > 0 && config.canBeCollateral) {
                uint256 value = (supplied * price) / PRECISION;
                totalCollateralValue += (value * config.collateralFactor) / BPS;
            }

            // Borrow value
            uint256 borrowed = _getCurrentDebt(user, asset);
            if (borrowed > 0) {
                totalBorrowValue += (borrowed * price) / PRECISION;
            }
        }
    }

    /// @notice Get health factor (returns 1e18 for 100% healthy)
    function getHealthFactor(address user) external view returns (uint256) {
        (uint256 collateral, uint256 borrows) = getAccountLiquidity(user);
        if (borrows == 0) return type(uint256).max;
        return (collateral * PRECISION) / borrows;
    }

    /// @notice Get user's supplied amount for an asset
    function getUserSupplied(address user, address asset) external view returns (uint256) {
        return userAccounts[user].supplied[asset];
    }

    /// @notice Get user's borrowed amount for an asset (with interest)
    function getUserBorrowed(address user, address asset) external view returns (uint256) {
        return _getCurrentDebt(user, asset);
    }

    /// @notice Get utilization rate in basis points
    function getUtilization(address asset) external view returns (uint256) {
        Market storage market = markets[asset];
        if (market.totalSupply == 0) return 0;
        return (market.totalBorrows * BPS) / market.totalSupply;
    }

    /// @notice Get APY in basis points (annualized)
    function getBorrowAPY(address asset) external view returns (uint256) {
        uint256 ratePerSecond = getBorrowRate(asset);
        // Simple: rate * seconds per year / precision * 10000 for bps
        return (ratePerSecond * SECONDS_PER_YEAR * BPS) / PRECISION;
    }

    function getSupplyAPY(address asset) external view returns (uint256) {
        uint256 ratePerSecond = getSupplyRate(asset);
        return (ratePerSecond * SECONDS_PER_YEAR * BPS) / PRECISION;
    }
}

/// @title FlashLoanProvider
/// @notice Simple flash loan implementation
contract FlashLoanProvider {
    /// @notice Fee in basis points
    uint256 public constant FLASH_LOAN_FEE = 9; // 0.09%
    uint256 public constant BPS = 10000;

    /// @notice Flash loan callback interface
    bytes4 private constant CALLBACK_SELECTOR = bytes4(keccak256("onFlashLoan(address,address,uint256,uint256,bytes)"));

    /// @notice Events
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, uint256 fee);

    /// @notice Errors
    error CallbackFailed();
    error InsufficientRepayment();

    /// @notice Execute a flash loan
    /// @param receiver Contract that will receive the loan
    /// @param token Token to borrow
    /// @param amount Amount to borrow
    /// @param data Arbitrary data to pass to callback
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        uint256 fee = (amount * FLASH_LOAN_FEE) / BPS;

        // Transfer tokens
        IERC20(token).transfer(receiver, amount);

        // Call receiver
        (bool success, bytes memory result) = receiver.call(
            abi.encodeWithSelector(CALLBACK_SELECTOR, msg.sender, token, amount, fee, data)
        );

        if (!success) {
            // Try to extract revert reason
            if (result.length > 0) {
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            revert CallbackFailed();
        }

        // Check repayment
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        if (balanceAfter < balanceBefore + fee) {
            revert InsufficientRepayment();
        }

        emit FlashLoan(receiver, token, amount, fee);
    }
}

/// @title IFlashLoanReceiver
/// @notice Interface for flash loan receivers
interface IFlashLoanReceiver {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool);
}
