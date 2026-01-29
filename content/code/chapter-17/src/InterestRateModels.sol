// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IInterestRateModel
/// @notice Interface for interest rate models
interface IInterestRateModel {
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256);
    function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactor) external view returns (uint256);
}

/// @title LinearInterestRateModel
/// @notice Simple linear interest rate model
/// @dev Rate increases linearly with utilization: rate = baseRate + utilization * multiplier
contract LinearInterestRateModel is IInterestRateModel {
    /// @notice Base rate per second (when utilization = 0)
    uint256 public immutable baseRatePerSecond;

    /// @notice Multiplier per second (slope of utilization curve)
    uint256 public immutable multiplierPerSecond;

    /// @notice Precision for calculations
    uint256 public constant PRECISION = 1e18;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    /// @param baseRatePerYear Annual base rate (e.g., 2e16 = 2%)
    /// @param multiplierPerYear Annual multiplier (e.g., 10e16 = 10%)
    constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) {
        baseRatePerSecond = baseRatePerYear / SECONDS_PER_YEAR;
        multiplierPerSecond = multiplierPerYear / SECONDS_PER_YEAR;
    }

    /// @notice Get utilization rate
    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
        if (borrows == 0) return 0;
        return (borrows * PRECISION) / (cash + borrows - reserves);
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
        uint256 utilization = utilizationRate(cash, borrows, reserves);
        return baseRatePerSecond + (utilization * multiplierPerSecond) / PRECISION;
    }

    /// @inheritdoc IInterestRateModel
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view override returns (uint256) {
        uint256 oneMinusReserveFactor = PRECISION - reserveFactor;
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 utilization = utilizationRate(cash, borrows, reserves);
        return (borrowRate * utilization * oneMinusReserveFactor) / (PRECISION * PRECISION);
    }

    /// @notice Get annual percentage rate
    function getBorrowAPR(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256) {
        return getBorrowRate(cash, borrows, reserves) * SECONDS_PER_YEAR;
    }
}

/// @title JumpRateModel
/// @notice Interest rate model with a "kink" (jump) at high utilization
/// @dev Used by Compound - rate jumps sharply above kink to incentivize repayment
contract JumpRateModel is IInterestRateModel {
    /// @notice Base rate per second
    uint256 public immutable baseRatePerSecond;

    /// @notice Normal slope (below kink)
    uint256 public immutable multiplierPerSecond;

    /// @notice Steep slope (above kink)
    uint256 public immutable jumpMultiplierPerSecond;

    /// @notice Utilization at which jump occurs (e.g., 0.8e18 = 80%)
    uint256 public immutable kink;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    /// @param baseRatePerYear Annual base rate
    /// @param multiplierPerYear Normal multiplier (slope below kink)
    /// @param jumpMultiplierPerYear Jump multiplier (slope above kink)
    /// @param kink_ Utilization at kink point
    constructor(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) {
        baseRatePerSecond = baseRatePerYear / SECONDS_PER_YEAR;
        multiplierPerSecond = multiplierPerYear / SECONDS_PER_YEAR;
        jumpMultiplierPerSecond = jumpMultiplierPerYear / SECONDS_PER_YEAR;
        kink = kink_;
    }

    /// @notice Get utilization rate
    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
        if (borrows == 0) return 0;
        return (borrows * PRECISION) / (cash + borrows - reserves);
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
        uint256 utilization = utilizationRate(cash, borrows, reserves);

        if (utilization <= kink) {
            // Below kink: linear increase
            return baseRatePerSecond + (utilization * multiplierPerSecond) / PRECISION;
        } else {
            // Above kink: steeper increase
            uint256 normalRate = baseRatePerSecond + (kink * multiplierPerSecond) / PRECISION;
            uint256 excessUtilization = utilization - kink;
            return normalRate + (excessUtilization * jumpMultiplierPerSecond) / PRECISION;
        }
    }

    /// @inheritdoc IInterestRateModel
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view override returns (uint256) {
        uint256 oneMinusReserveFactor = PRECISION - reserveFactor;
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 utilization = utilizationRate(cash, borrows, reserves);
        return (borrowRate * utilization * oneMinusReserveFactor) / (PRECISION * PRECISION);
    }

    /// @notice Get rates at various utilization points for UI display
    function getRateCurve() external view returns (
        uint256[] memory utilizations,
        uint256[] memory borrowRates
    ) {
        utilizations = new uint256[](11);
        borrowRates = new uint256[](11);

        for (uint256 i = 0; i <= 10; i++) {
            uint256 util = (i * PRECISION) / 10;
            utilizations[i] = util;

            if (util <= kink) {
                borrowRates[i] = baseRatePerSecond + (util * multiplierPerSecond) / PRECISION;
            } else {
                uint256 normalRate = baseRatePerSecond + (kink * multiplierPerSecond) / PRECISION;
                uint256 excessUtil = util - kink;
                borrowRates[i] = normalRate + (excessUtil * jumpMultiplierPerSecond) / PRECISION;
            }

            // Convert to APR for readability
            borrowRates[i] = borrowRates[i] * SECONDS_PER_YEAR;
        }
    }
}

/// @title VariableRateModel
/// @notice Dynamic interest rate model that adjusts based on target utilization
/// @dev Similar to Aave's variable rate model
contract VariableRateModel is IInterestRateModel {
    /// @notice Optimal utilization rate
    uint256 public immutable optimalUtilization;

    /// @notice Base variable rate
    uint256 public immutable baseVariableRatePerSecond;

    /// @notice Variable rate slope below optimal
    uint256 public immutable variableRateSlope1PerSecond;

    /// @notice Variable rate slope above optimal
    uint256 public immutable variableRateSlope2PerSecond;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    constructor(
        uint256 optimalUtilization_,
        uint256 baseVariableRatePerYear,
        uint256 variableRateSlope1PerYear,
        uint256 variableRateSlope2PerYear
    ) {
        optimalUtilization = optimalUtilization_;
        baseVariableRatePerSecond = baseVariableRatePerYear / SECONDS_PER_YEAR;
        variableRateSlope1PerSecond = variableRateSlope1PerYear / SECONDS_PER_YEAR;
        variableRateSlope2PerSecond = variableRateSlope2PerYear / SECONDS_PER_YEAR;
    }

    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
        if (borrows == 0) return 0;
        return (borrows * PRECISION) / (cash + borrows - reserves);
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
        uint256 utilization = utilizationRate(cash, borrows, reserves);

        if (utilization <= optimalUtilization) {
            // Below optimal: gradual increase
            return baseVariableRatePerSecond +
                (utilization * variableRateSlope1PerSecond) / optimalUtilization;
        } else {
            // Above optimal: steep increase
            uint256 baseRate = baseVariableRatePerSecond + variableRateSlope1PerSecond;
            uint256 excessUtilization = utilization - optimalUtilization;
            uint256 excessRate = (excessUtilization * variableRateSlope2PerSecond) /
                (PRECISION - optimalUtilization);
            return baseRate + excessRate;
        }
    }

    /// @inheritdoc IInterestRateModel
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view override returns (uint256) {
        uint256 oneMinusReserveFactor = PRECISION - reserveFactor;
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 utilization = utilizationRate(cash, borrows, reserves);
        return (borrowRate * utilization * oneMinusReserveFactor) / (PRECISION * PRECISION);
    }
}

/// @title StableRateModel
/// @notice Stable interest rate that only changes on rebalance
/// @dev Provides predictable borrowing costs
contract StableRateModel {
    /// @notice Current stable rate per second
    uint256 public stableRatePerSecond;

    /// @notice Premium over variable rate
    uint256 public immutable stableRatePremium;

    /// @notice Reference variable rate model
    IInterestRateModel public immutable variableRateModel;

    /// @notice Owner for rate updates
    address public owner;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    event StableRateUpdated(uint256 oldRate, uint256 newRate);

    error NotOwner();

    constructor(address _variableRateModel, uint256 _stableRatePremiumPerYear) {
        variableRateModel = IInterestRateModel(_variableRateModel);
        stableRatePremium = _stableRatePremiumPerYear / SECONDS_PER_YEAR;
        owner = msg.sender;
    }

    /// @notice Rebalance stable rate based on current variable rate
    function rebalance(uint256 cash, uint256 borrows, uint256 reserves) external {
        uint256 variableRate = variableRateModel.getBorrowRate(cash, borrows, reserves);
        uint256 oldRate = stableRatePerSecond;
        stableRatePerSecond = variableRate + stableRatePremium;
        emit StableRateUpdated(oldRate, stableRatePerSecond);
    }

    /// @notice Get current stable borrow rate
    function getStableRate() external view returns (uint256) {
        return stableRatePerSecond;
    }

    /// @notice Get stable APR
    function getStableAPR() external view returns (uint256) {
        return stableRatePerSecond * SECONDS_PER_YEAR;
    }
}
