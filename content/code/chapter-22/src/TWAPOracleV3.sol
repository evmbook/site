// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title TWAPOracleV3
/// @notice Uniswap V3-style TWAP oracle using built-in observation array
/// @dev V3 uses geometric mean TWAP with configurable cardinality

/// @notice Minimal interface for Uniswap V3 Pool oracle functions
interface IUniswapV3Pool {
    /// @notice Get the current tick and other pool state
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @notice Access an observation by index
    function observations(uint256 index) external view returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
    );

    /// @notice Observe historical tick values
    /// @param secondsAgos Array of seconds ago from current block to observe
    /// @return tickCumulatives Cumulative tick values at each secondsAgo
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Increase the observation array cardinality
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    /// @notice Get pool tokens
    function token0() external view returns (address);
    function token1() external view returns (address);

    /// @notice Get pool fee
    function fee() external view returns (uint24);
}

/// @notice Tick math library for price conversions
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}

/// @title OracleLibrary
/// @notice Provides functions to consult Uniswap V3 oracles
library OracleLibrary {
    /// @notice Calculates time-weighted mean tick using the pool's observations
    /// @param pool Address of the Uniswap V3 pool
    /// @param period Number of seconds in the past to calculate TWAP
    /// @return timeWeightedAverageTick The time-weighted average tick
    function consult(address pool, uint32 period) internal view returns (int24 timeWeightedAverageTick) {
        require(period != 0, "Period must be non-zero");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = period;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / int56(uint56(period)));

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(period)) != 0)) {
            timeWeightedAverageTick--;
        }
    }

    /// @notice Get quote amount from TWAP tick
    /// @param baseAmount Amount of base token
    /// @param baseToken Base token address
    /// @param quoteToken Quote token address
    /// @param tick The tick value to convert
    /// @return quoteAmount Amount in quote token
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision for full-range ticks
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? mulDiv(ratioX192, baseAmount, 1 << 192)
                : mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? mulDiv(ratioX128, baseAmount, 1 << 128)
                : mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Helper for full-precision multiplication and division
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Short circuit for standard cases
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        require(denominator > prod1);

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
            prod0 := div(prod0, twos)
            twos := add(div(sub(0, twos), twos), 1)
        }

        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
    }
}

/// @title TWAPOracleV3
/// @notice Production-ready Uniswap V3 TWAP oracle consumer
contract TWAPOracleV3 {
    /// @notice The Uniswap V3 pool to query
    IUniswapV3Pool public immutable pool;

    /// @notice Token addresses
    address public immutable token0;
    address public immutable token1;

    /// @notice Default TWAP period
    uint32 public twapPeriod;

    /// @notice Minimum TWAP period (prevents manipulation)
    uint32 public constant MIN_TWAP_PERIOD = 5 minutes;

    /// @notice Maximum TWAP period (ensures freshness)
    uint32 public constant MAX_TWAP_PERIOD = 1 hours;

    /// @notice Events
    event TWAPPeriodUpdated(uint32 oldPeriod, uint32 newPeriod);

    /// @notice Errors
    error InvalidPool();
    error InvalidPeriod();
    error InsufficientCardinality();
    error StaleObservation();

    /// @param _pool Uniswap V3 pool address
    /// @param _twapPeriod Default period for TWAP calculations
    constructor(address _pool, uint32 _twapPeriod) {
        if (_pool == address(0)) revert InvalidPool();
        if (_twapPeriod < MIN_TWAP_PERIOD || _twapPeriod > MAX_TWAP_PERIOD) revert InvalidPeriod();

        pool = IUniswapV3Pool(_pool);
        token0 = pool.token0();
        token1 = pool.token1();
        twapPeriod = _twapPeriod;
    }

    /// @notice Get the current TWAP tick
    /// @return tick The time-weighted average tick over the default period
    function getTWAPTick() external view returns (int24 tick) {
        return OracleLibrary.consult(address(pool), twapPeriod);
    }

    /// @notice Get TWAP tick for a custom period
    /// @param period Seconds to look back
    /// @return tick The time-weighted average tick
    function getTWAPTick(uint32 period) external view returns (int24 tick) {
        if (period < MIN_TWAP_PERIOD) revert InvalidPeriod();
        return OracleLibrary.consult(address(pool), period);
    }

    /// @notice Get quote amount using TWAP
    /// @param baseAmount Amount of base token
    /// @param baseToken Which token is the base (must be token0 or token1)
    /// @return quoteAmount Equivalent amount in the other token
    function getQuote(uint128 baseAmount, address baseToken) external view returns (uint256 quoteAmount) {
        int24 tick = OracleLibrary.consult(address(pool), twapPeriod);

        address quoteToken = baseToken == token0 ? token1 : token0;
        return OracleLibrary.getQuoteAtTick(tick, baseAmount, baseToken, quoteToken);
    }

    /// @notice Get the price of token0 in terms of token1
    /// @dev Returns price with 18 decimal precision
    /// @return price Token0/Token1 price
    function getPrice0() external view returns (uint256 price) {
        int24 tick = OracleLibrary.consult(address(pool), twapPeriod);
        // Get price for 1e18 of token0
        return OracleLibrary.getQuoteAtTick(tick, 1e18, token0, token1);
    }

    /// @notice Get the price of token1 in terms of token0
    /// @dev Returns price with 18 decimal precision
    /// @return price Token1/Token0 price
    function getPrice1() external view returns (uint256 price) {
        int24 tick = OracleLibrary.consult(address(pool), twapPeriod);
        return OracleLibrary.getQuoteAtTick(tick, 1e18, token1, token0);
    }

    /// @notice Get current observation cardinality
    /// @return cardinality Current number of stored observations
    /// @return cardinalityNext Target cardinality after next write
    function getObservationCardinality() external view returns (uint16 cardinality, uint16 cardinalityNext) {
        (,, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNextSlot,,) = pool.slot0();
        return (observationCardinality, observationCardinalityNextSlot);
    }

    /// @notice Check if the pool has sufficient history for the TWAP period
    /// @return sufficient True if enough observations exist
    function hasSufficientHistory() external view returns (bool sufficient) {
        (,, uint16 observationIndex, uint16 observationCardinality,,,) = pool.slot0();

        if (observationCardinality == 0) return false;

        // Get oldest observation
        uint16 oldestIndex = (observationIndex + 1) % observationCardinality;
        (uint32 oldestTimestamp,,, bool initialized) = pool.observations(oldestIndex);

        if (!initialized) {
            // Array not full yet, check index 0
            (oldestTimestamp,,,) = pool.observations(0);
        }

        // Check if we have enough history
        return (block.timestamp - oldestTimestamp) >= twapPeriod;
    }

    /// @notice Get the oldest observation timestamp
    /// @return timestamp The timestamp of the oldest observation
    function getOldestObservationTimestamp() external view returns (uint32 timestamp) {
        (,, uint16 observationIndex, uint16 observationCardinality,,,) = pool.slot0();

        if (observationCardinality == 0) return 0;

        uint16 oldestIndex = (observationIndex + 1) % observationCardinality;
        (uint32 oldestTimestamp,,, bool initialized) = pool.observations(oldestIndex);

        if (!initialized) {
            (oldestTimestamp,,,) = pool.observations(0);
        }

        return oldestTimestamp;
    }

    /// @notice Prepare the pool for longer TWAP periods by increasing cardinality
    /// @dev This costs gas but enables longer historical queries
    /// @param targetCardinality Desired observation array size
    function prepareCardinality(uint16 targetCardinality) external {
        pool.increaseObservationCardinalityNext(targetCardinality);
    }

    /// @notice Calculate required cardinality for a given TWAP period
    /// @dev Assumes one observation per block (~12 seconds on mainnet)
    /// @param period Desired TWAP period in seconds
    /// @return cardinality Minimum cardinality needed
    function calculateRequiredCardinality(uint32 period) external pure returns (uint16 cardinality) {
        // Add 20% buffer for safety
        uint256 blocks = (uint256(period) * 120) / 100 / 12;
        require(blocks <= type(uint16).max, "Period too long");
        return uint16(blocks);
    }
}

/// @title TWAPOracleV3Factory
/// @notice Factory for deploying TWAP oracle wrappers for V3 pools
contract TWAPOracleV3Factory {
    /// @notice Mapping of pool => oracle
    mapping(address => address) public getOracle;

    /// @notice All deployed oracles
    address[] public allOracles;

    /// @notice Default TWAP period for new oracles
    uint32 public defaultTwapPeriod = 30 minutes;

    event OracleCreated(address indexed pool, address oracle);

    /// @notice Deploy a new oracle for a V3 pool
    /// @param pool The Uniswap V3 pool address
    /// @param twapPeriod TWAP period for the oracle (0 = use default)
    /// @return oracle The deployed oracle address
    function createOracle(address pool, uint32 twapPeriod) external returns (address oracle) {
        require(getOracle[pool] == address(0), "Oracle exists");

        uint32 period = twapPeriod == 0 ? defaultTwapPeriod : twapPeriod;
        oracle = address(new TWAPOracleV3(pool, period));

        getOracle[pool] = oracle;
        allOracles.push(oracle);

        emit OracleCreated(pool, oracle);
    }

    /// @notice Get total number of oracles
    function allOraclesLength() external view returns (uint256) {
        return allOracles.length;
    }
}
