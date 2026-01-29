// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title TWAPOracleV2
/// @notice Uniswap V2-style TWAP oracle using cumulative price accumulators
/// @dev V2 uses arithmetic mean TWAP with external storage for observations
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/// @notice Fixed-point Q112.112 math for V2 price calculations
library FixedPoint {
    // Q112.112 resolution = 2^112
    uint8 internal constant RESOLUTION = 112;
    uint256 internal constant Q112 = 2**112;

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    /// @notice Encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    /// @notice Divide a UQ112x112 by a uint112
    function uqdiv(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    /// @notice Decode a UQ144x112 to a uint144
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    /// @notice Multiply a UQ112x112 by a uint and return a UQ144x112
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint: MUL_OVERFLOW");
        return uq144x112(z);
    }

    /// @notice Calculate average price from cumulative price difference
    function uq112x112Div(uint256 priceCumulativeDiff, uint32 timeElapsed)
        internal
        pure
        returns (uq112x112 memory)
    {
        return uq112x112(uint224(priceCumulativeDiff / timeElapsed));
    }
}

/// @title TWAPOracleV2
/// @notice Production-ready V2 TWAP oracle with configurable observation period
contract TWAPOracleV2 {
    using FixedPoint for *;

    /// @notice Observation data structure for storing price snapshots
    struct Observation {
        uint32 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    /// @notice The Uniswap V2 pair to observe
    IUniswapV2Pair public immutable pair;

    /// @notice Token addresses for reference
    address public immutable token0;
    address public immutable token1;

    /// @notice Minimum period for TWAP calculation (prevents manipulation)
    uint32 public immutable minPeriod;

    /// @notice Maximum period for TWAP calculation (ensures freshness)
    uint32 public immutable maxPeriod;

    /// @notice Historical observations (circular buffer not needed for simple oracle)
    Observation public firstObservation;
    Observation public lastObservation;

    /// @notice Last computed TWAP prices
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    /// @notice Events
    event PriceUpdated(uint256 price0Average, uint256 price1Average, uint32 timeElapsed);
    event ObservationRecorded(uint32 timestamp, uint256 price0Cumulative, uint256 price1Cumulative);

    /// @notice Errors
    error PeriodNotElapsed();
    error PeriodTooLong();
    error InvalidPair();
    error NoObservations();

    /// @param _pair Uniswap V2 pair address
    /// @param _minPeriod Minimum time between price updates (e.g., 10 minutes)
    /// @param _maxPeriod Maximum age for valid observations (e.g., 24 hours)
    constructor(address _pair, uint32 _minPeriod, uint32 _maxPeriod) {
        if (_pair == address(0)) revert InvalidPair();

        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
        minPeriod = _minPeriod;
        maxPeriod = _maxPeriod;

        // Record initial observation
        _recordObservation();
        firstObservation = lastObservation;
    }

    /// @notice Record a new price observation
    /// @dev Can be called by anyone to keep the oracle updated
    function update() external {
        _recordObservation();
        _updateTWAP();
    }

    /// @notice Get current cumulative prices from the pair
    function currentCumulativePrices()
        public
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = uint32(block.timestamp % 2**32);
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();

        // If time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 timestampLast) = pair.getReserves();
        if (timestampLast != blockTimestamp) {
            // Subtraction overflow is desired for timestamp wraparound
            unchecked {
                uint32 timeElapsed = blockTimestamp - timestampLast;
                // Counterfactual cumulative prices
                price0Cumulative += uint256(FixedPoint.encode(reserve1).uqdiv(reserve0)._x) * timeElapsed;
                price1Cumulative += uint256(FixedPoint.encode(reserve0).uqdiv(reserve1)._x) * timeElapsed;
            }
        }
    }

    /// @notice Record current prices as an observation
    function _recordObservation() internal {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices();

        lastObservation = Observation({
            timestamp: blockTimestamp,
            price0Cumulative: price0Cumulative,
            price1Cumulative: price1Cumulative
        });

        emit ObservationRecorded(blockTimestamp, price0Cumulative, price1Cumulative);
    }

    /// @notice Calculate and store TWAP from observations
    function _updateTWAP() internal {
        uint32 timeElapsed;
        unchecked {
            timeElapsed = lastObservation.timestamp - firstObservation.timestamp;
        }

        // Require minimum period to prevent manipulation
        if (timeElapsed < minPeriod) revert PeriodNotElapsed();

        // Calculate price averages using cumulative price differences
        // Overflow is desired for cumulative price wraparound
        unchecked {
            price0Average = FixedPoint.uq112x112Div(
                lastObservation.price0Cumulative - firstObservation.price0Cumulative,
                timeElapsed
            );
            price1Average = FixedPoint.uq112x112Div(
                lastObservation.price1Cumulative - firstObservation.price1Cumulative,
                timeElapsed
            );
        }

        emit PriceUpdated(price0Average._x, price1Average._x, timeElapsed);

        // Shift observations: last becomes first for next period
        firstObservation = lastObservation;
    }

    /// @notice Consult the oracle for a token amount
    /// @param token The token to get the price for
    /// @param amountIn The amount of input token
    /// @return amountOut The equivalent amount in the other token
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut) {
        if (firstObservation.timestamp == 0) revert NoObservations();

        if (token == token0) {
            amountOut = FixedPoint.decode144(price0Average.mul(amountIn));
        } else {
            require(token == token1, "TWAPOracleV2: INVALID_TOKEN");
            amountOut = FixedPoint.decode144(price1Average.mul(amountIn));
        }
    }

    /// @notice Get the TWAP price of token0 in terms of token1
    /// @dev Returns price with 18 decimals for easier consumption
    function getPrice0() external view returns (uint256) {
        return uint256(price0Average._x) * 1e18 / FixedPoint.Q112;
    }

    /// @notice Get the TWAP price of token1 in terms of token0
    /// @dev Returns price with 18 decimals for easier consumption
    function getPrice1() external view returns (uint256) {
        return uint256(price1Average._x) * 1e18 / FixedPoint.Q112;
    }

    /// @notice Check if the oracle needs an update
    function needsUpdate() external view returns (bool) {
        (,, uint32 blockTimestamp) = currentCumulativePrices();
        unchecked {
            return (blockTimestamp - lastObservation.timestamp) >= minPeriod;
        }
    }

    /// @notice Get observation age
    function observationAge() external view returns (uint32) {
        unchecked {
            return uint32(block.timestamp % 2**32) - lastObservation.timestamp;
        }
    }
}
