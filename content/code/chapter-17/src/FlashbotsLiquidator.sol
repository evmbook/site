// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title FlashbotsLiquidator
/// @notice MEV-aware liquidation contract designed for Flashbots bundle submission
/// @dev Demonstrates searcher patterns for liquidation MEV extraction

/// @title IERC20
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title ILendingPool
/// @notice Minimal lending pool interface for liquidations
interface ILendingPool {
    function liquidate(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToRepay
    ) external;

    function getHealthFactor(address user) external view returns (uint256);
    function getUserBorrowed(address user, address asset) external view returns (uint256);
    function getUserSupplied(address user, address asset) external view returns (uint256);
}

/// @title IFlashLoanProvider
/// @notice Flash loan interface for capital-free liquidations
interface IFlashLoanProvider {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
}

/// @title ISwapRouter
/// @notice DEX router for collateral → debt token conversion
interface ISwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/// @title FlashbotsLiquidator
/// @notice Liquidation contract optimized for Flashbots bundle submission
/// @dev Key features:
///   1. Atomic liquidation + swap in single transaction
///   2. Flash loan funded (no upfront capital needed)
///   3. Profit check before execution (reverts if unprofitable)
///   4. Multi-position batching support
///   5. Gas-efficient for bundle priority fee calculations
contract FlashbotsLiquidator {
    /// @notice Owner (searcher)
    address public immutable owner;

    /// @notice Lending pool to liquidate on
    ILendingPool public immutable lendingPool;

    /// @notice Flash loan provider
    IFlashLoanProvider public immutable flashLoanProvider;

    /// @notice DEX router for swaps
    ISwapRouter public immutable swapRouter;

    /// @notice Minimum profit threshold (in debt token)
    uint256 public minProfitThreshold;

    /// @notice Liquidation parameters for flash loan callback
    struct LiquidationParams {
        address borrower;
        address collateralAsset;
        address debtAsset;
        uint256 debtAmount;
        uint256 minCollateralOut;
        address[] swapPath;
    }

    /// @notice Events
    event LiquidationExecuted(
        address indexed borrower,
        address indexed collateralAsset,
        address indexed debtAsset,
        uint256 debtRepaid,
        uint256 collateralReceived,
        uint256 profit
    );
    event ProfitWithdrawn(address indexed token, uint256 amount);

    /// @notice Errors
    error NotOwner();
    error NotFlashLoanProvider();
    error UnprofitableLiquidation();
    error PositionHealthy();
    error SlippageExceeded();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        address _lendingPool,
        address _flashLoanProvider,
        address _swapRouter,
        uint256 _minProfitThreshold
    ) {
        owner = msg.sender;
        lendingPool = ILendingPool(_lendingPool);
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
        swapRouter = ISwapRouter(_swapRouter);
        minProfitThreshold = _minProfitThreshold;
    }

    /// @notice Execute a liquidation using flash loan
    /// @dev This is the entry point for Flashbots bundles
    /// @param borrower Address of the unhealthy position
    /// @param collateralAsset Collateral to seize
    /// @param debtAsset Debt to repay
    /// @param debtAmount Amount of debt to repay
    /// @param minCollateralOut Minimum collateral expected (slippage protection)
    /// @param swapPath Path for swapping collateral back to debt token
    function executeLiquidation(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtAmount,
        uint256 minCollateralOut,
        address[] calldata swapPath
    ) external onlyOwner {
        // Pre-check: Ensure position is actually liquidatable
        uint256 healthFactor = lendingPool.getHealthFactor(borrower);
        if (healthFactor >= 1e18) revert PositionHealthy();

        // Encode liquidation params for flash loan callback
        bytes memory data = abi.encode(LiquidationParams({
            borrower: borrower,
            collateralAsset: collateralAsset,
            debtAsset: debtAsset,
            debtAmount: debtAmount,
            minCollateralOut: minCollateralOut,
            swapPath: swapPath
        }));

        // Initiate flash loan for debt token
        flashLoanProvider.flashLoan(
            address(this),
            debtAsset,
            debtAmount,
            data
        );
    }

    /// @notice Flash loan callback - executes the actual liquidation
    /// @dev Called by flash loan provider after sending tokens
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool) {
        if (msg.sender != address(flashLoanProvider)) revert NotFlashLoanProvider();
        require(initiator == address(this), "Invalid initiator");

        LiquidationParams memory params = abi.decode(data, (LiquidationParams));

        // Step 1: Approve lending pool to take debt tokens
        IERC20(params.debtAsset).approve(address(lendingPool), params.debtAmount);

        // Step 2: Execute liquidation
        uint256 collateralBefore = IERC20(params.collateralAsset).balanceOf(address(this));

        lendingPool.liquidate(
            params.borrower,
            params.collateralAsset,
            params.debtAsset,
            params.debtAmount
        );

        uint256 collateralReceived = IERC20(params.collateralAsset).balanceOf(address(this)) - collateralBefore;

        // Step 3: Slippage check
        if (collateralReceived < params.minCollateralOut) revert SlippageExceeded();

        // Step 4: Swap collateral back to debt token
        IERC20(params.collateralAsset).approve(address(swapRouter), collateralReceived);

        uint256[] memory amounts = swapRouter.swapExactTokensForTokens(
            collateralReceived,
            amount + fee, // Minimum: repay flash loan + fee
            params.swapPath,
            address(this),
            block.timestamp
        );

        uint256 debtTokenReceived = amounts[amounts.length - 1];

        // Step 5: Profit check (critical for Flashbots - unprofitable tx wastes gas)
        uint256 totalOwed = amount + fee;
        if (debtTokenReceived < totalOwed + minProfitThreshold) {
            revert UnprofitableLiquidation();
        }

        uint256 profit = debtTokenReceived - totalOwed;

        // Step 6: Approve flash loan repayment
        IERC20(token).approve(address(flashLoanProvider), totalOwed);

        emit LiquidationExecuted(
            params.borrower,
            params.collateralAsset,
            params.debtAsset,
            params.debtAmount,
            collateralReceived,
            profit
        );

        return true;
    }

    /// @notice Batch execute multiple liquidations in single transaction
    /// @dev Optimal for Flashbots bundles when multiple positions are liquidatable
    function batchLiquidate(
        address[] calldata borrowers,
        address[] calldata collateralAssets,
        address[] calldata debtAssets,
        uint256[] calldata debtAmounts,
        uint256[] calldata minCollateralOuts,
        address[][] calldata swapPaths
    ) external onlyOwner {
        require(
            borrowers.length == collateralAssets.length &&
            borrowers.length == debtAssets.length &&
            borrowers.length == debtAmounts.length &&
            borrowers.length == minCollateralOuts.length &&
            borrowers.length == swapPaths.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < borrowers.length; i++) {
            // Try each liquidation - continue on failure for batch efficiency
            try this.executeLiquidation(
                borrowers[i],
                collateralAssets[i],
                debtAssets[i],
                debtAmounts[i],
                minCollateralOuts[i],
                swapPaths[i]
            ) {} catch {
                // Skip failed liquidations (position may have been liquidated by competitor)
                continue;
            }
        }
    }

    /// @notice Check if a liquidation would be profitable
    /// @dev Call this off-chain before submitting Flashbots bundle
    function simulateLiquidation(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtAmount,
        address[] calldata swapPath
    ) external view returns (bool profitable, uint256 expectedProfit) {
        // Check health factor
        uint256 healthFactor = lendingPool.getHealthFactor(borrower);
        if (healthFactor >= 1e18) {
            return (false, 0);
        }

        // Estimate collateral received (simplified - real impl needs liquidation bonus)
        uint256 userCollateral = lendingPool.getUserSupplied(borrower, collateralAsset);
        uint256 userDebt = lendingPool.getUserBorrowed(borrower, debtAsset);

        // Assume 5% liquidation bonus and 50% close factor
        uint256 maxLiquidatable = (userDebt * 5000) / 10000;
        uint256 actualDebt = debtAmount > maxLiquidatable ? maxLiquidatable : debtAmount;

        // Estimate collateral (this is simplified)
        uint256 estimatedCollateral = (actualDebt * 10500) / 10000; // 5% bonus

        // Get swap output
        uint256[] memory amounts = swapRouter.getAmountsOut(estimatedCollateral, swapPath);
        uint256 expectedOutput = amounts[amounts.length - 1];

        // Calculate profit (assuming ~0.09% flash loan fee)
        uint256 flashLoanFee = (actualDebt * 9) / 10000;
        uint256 totalCost = actualDebt + flashLoanFee;

        if (expectedOutput > totalCost + minProfitThreshold) {
            return (true, expectedOutput - totalCost);
        }

        return (false, 0);
    }

    /// @notice Withdraw accumulated profits
    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
            emit ProfitWithdrawn(token, balance);
        }
    }

    /// @notice Update minimum profit threshold
    function setMinProfitThreshold(uint256 _threshold) external onlyOwner {
        minProfitThreshold = _threshold;
    }

    /// @notice Emergency token recovery
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
}

/// @title FlashbotsRelay
/// @notice Interface representing Flashbots bundle submission
/// @dev This is a mock for educational purposes - real submission is off-chain
interface IFlashbotsRelay {
    /// @notice Bundle structure for Flashbots submission
    struct Bundle {
        bytes[] transactions;     // Signed transactions
        uint256 blockNumber;      // Target block
        uint256 minTimestamp;     // Min block timestamp
        uint256 maxTimestamp;     // Max block timestamp
        address[] revertingTxHashes; // Txs allowed to revert
    }

    /// @notice Submit a bundle to Flashbots relay
    function sendBundle(Bundle calldata bundle) external returns (bytes32 bundleHash);

    /// @notice Simulate bundle execution
    function simulate(Bundle calldata bundle) external view returns (bool success, uint256 gasUsed);
}

/// @title MEVShareLiquidator
/// @notice Liquidator that shares MEV with users via MEV-Share
/// @dev Demonstrates MEV redistribution pattern
contract MEVShareLiquidator {
    /// @notice Owner
    address public owner;

    /// @notice MEV share percentage to return to liquidated user (basis points)
    uint256 public userMEVShare = 2000; // 20%

    /// @notice Accumulated MEV to distribute
    mapping(address => uint256) public pendingMEVShare;

    event MEVShared(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /// @notice Execute liquidation with MEV sharing
    /// @dev A portion of MEV profit is returned to the liquidated user
    function liquidateWithMEVShare(
        address lendingPool,
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtAmount
    ) external {
        // Record profit before
        uint256 profitBefore = IERC20(debtAsset).balanceOf(address(this));

        // Execute liquidation (simplified)
        ILendingPool(lendingPool).liquidate(borrower, collateralAsset, debtAsset, debtAmount);

        // Calculate profit
        uint256 profitAfter = IERC20(debtAsset).balanceOf(address(this));
        uint256 profit = profitAfter - profitBefore;

        // Share MEV with user
        if (profit > 0) {
            uint256 userShare = (profit * userMEVShare) / 10000;
            pendingMEVShare[borrower] += userShare;
            emit MEVShared(borrower, userShare);
        }
    }

    /// @notice Users can claim their MEV share
    function claimMEVShare(address token) external {
        uint256 amount = pendingMEVShare[msg.sender];
        if (amount > 0) {
            pendingMEVShare[msg.sender] = 0;
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    /// @notice Update MEV share percentage
    function setUserMEVShare(uint256 _share) external {
        require(msg.sender == owner, "Not owner");
        require(_share <= 5000, "Max 50%");
        userMEVShare = _share;
    }
}

/// @title LiquidationMonitor
/// @notice Off-chain helper contract for monitoring liquidatable positions
/// @dev View functions for searcher bots to identify opportunities
contract LiquidationMonitor {
    /// @notice Liquidatable position info
    struct LiquidatablePosition {
        address borrower;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalCollateral;
        uint256 maxLiquidatable;
    }

    /// @notice Batch check multiple positions
    function checkPositions(
        address lendingPool,
        address[] calldata users
    ) external view returns (LiquidatablePosition[] memory positions) {
        positions = new LiquidatablePosition[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            uint256 healthFactor = ILendingPool(lendingPool).getHealthFactor(users[i]);

            positions[i] = LiquidatablePosition({
                borrower: users[i],
                healthFactor: healthFactor,
                totalDebt: 0, // Would need additional calls
                totalCollateral: 0,
                maxLiquidatable: 0
            });
        }
    }

    /// @notice Find liquidatable positions from a list
    function findLiquidatable(
        address lendingPool,
        address[] calldata users,
        uint256 threshold
    ) external view returns (address[] memory liquidatable) {
        // Count liquidatable first
        uint256 count = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (ILendingPool(lendingPool).getHealthFactor(users[i]) < threshold) {
                count++;
            }
        }

        // Build result array
        liquidatable = new address[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (ILendingPool(lendingPool).getHealthFactor(users[i]) < threshold) {
                liquidatable[idx++] = users[i];
            }
        }
    }
}
