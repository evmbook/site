// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title UniswapV4OracleHook
/// @notice Uniswap V4 hooks-based TWAP oracle implementation
/// @dev V4 moves oracles to hooks - this is an opt-in, modular design

/// @notice V4 Pool Key structure
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

/// @notice V4 Pool ID (hash of PoolKey)
type PoolId is bytes32;

/// @notice Balance delta for swaps
struct BalanceDelta {
    int128 amount0;
    int128 amount1;
}

/// @notice Swap parameters
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

/// @notice Modify liquidity parameters
struct ModifyLiquidityParams {
    int24 tickLower;
    int24 tickUpper;
    int256 liquidityDelta;
    bytes32 salt;
}

/// @notice Minimal interface for V4 Pool Manager
interface IPoolManager {
    function getSlot0(PoolId id) external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint24 protocolFee,
        uint24 lpFee
    );
}

/// @notice Base hook interface for V4
interface IHooks {
    function getHookPermissions() external pure returns (HookPermissions memory);
}

/// @notice Hook permissions bitmap
struct HookPermissions {
    bool beforeInitialize;
    bool afterInitialize;
    bool beforeAddLiquidity;
    bool afterAddLiquidity;
    bool beforeRemoveLiquidity;
    bool afterRemoveLiquidity;
    bool beforeSwap;
    bool afterSwap;
    bool beforeDonate;
    bool afterDonate;
    bool beforeSwapReturnDelta;
    bool afterSwapReturnDelta;
    bool afterAddLiquidityReturnDelta;
    bool afterRemoveLiquidityReturnDelta;
}

/// @notice Base hook implementation with common utilities
abstract contract BaseHook is IHooks {
    IPoolManager public immutable poolManager;

    error NotPoolManager();
    error InvalidPool();
    error HookNotImplemented();

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    modifier poolManagerOnly() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    function getHookPermissions() external pure virtual returns (HookPermissions memory);
}

/// @title OracleHook
/// @notice V4 oracle hook providing TWAP functionality
/// @dev Stores observations in the hook contract rather than the pool
contract OracleHook is BaseHook {
    /// @notice Oracle observation structure
    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        bool initialized;
    }

    /// @notice Oracle state per pool
    struct OracleState {
        uint16 index;
        uint16 cardinality;
        uint16 cardinalityNext;
    }

    /// @notice Maximum observation array size
    uint16 public constant MAX_CARDINALITY = 65535;

    /// @notice Default cardinality for new pools
    uint16 public constant DEFAULT_CARDINALITY = 1;

    /// @notice Observations per pool: poolId => index => Observation
    mapping(PoolId => mapping(uint256 => Observation)) public observations;

    /// @notice Oracle state per pool
    mapping(PoolId => OracleState) public oracleStates;

    /// @notice Last recorded tick per pool (for cumulative calculation)
    mapping(PoolId => int24) public lastTicks;

    /// @notice Events
    event ObservationRecorded(PoolId indexed poolId, uint32 timestamp, int56 tickCumulative);
    event CardinalityIncreased(PoolId indexed poolId, uint16 oldCardinality, uint16 newCardinality);

    /// @notice Errors
    error CardinalityTooLow();
    error InvalidSecondsAgo();
    error OldestObservationTooRecent();

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// @notice Hook permissions - only afterInitialize and afterSwap
    function getHookPermissions() external pure override returns (HookPermissions memory) {
        return HookPermissions({
            beforeInitialize: false,
            afterInitialize: true,  // Initialize oracle state
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,        // Record observations
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Called after pool initialization
    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24 tick,
        bytes calldata
    ) external poolManagerOnly returns (bytes4) {
        PoolId poolId = _toPoolId(key);

        // Initialize oracle state
        oracleStates[poolId] = OracleState({
            index: 0,
            cardinality: DEFAULT_CARDINALITY,
            cardinalityNext: DEFAULT_CARDINALITY
        });

        // Record first observation
        observations[poolId][0] = Observation({
            blockTimestamp: uint32(block.timestamp),
            tickCumulative: 0,
            initialized: true
        });

        lastTicks[poolId] = tick;

        return this.afterInitialize.selector;
    }

    /// @notice Called after every swap - records observation
    function afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external poolManagerOnly returns (bytes4, int128) {
        PoolId poolId = _toPoolId(key);

        // Get current tick from pool manager
        (, int24 tick,,) = poolManager.getSlot0(poolId);

        // Write observation
        _write(poolId, tick);

        return (this.afterSwap.selector, 0);
    }

    /// @notice Write a new observation
    function _write(PoolId poolId, int24 tick) internal {
        OracleState storage state = oracleStates[poolId];
        Observation storage last = observations[poolId][state.index];

        uint32 blockTimestamp = uint32(block.timestamp);

        // Only write if timestamp changed (once per block max)
        if (last.blockTimestamp == blockTimestamp) {
            lastTicks[poolId] = tick;
            return;
        }

        // Calculate cumulative tick
        uint32 delta = blockTimestamp - last.blockTimestamp;
        int56 tickCumulative = last.tickCumulative + int56(lastTicks[poolId]) * int56(uint56(delta));

        // Determine index for new observation
        uint16 indexUpdated = (state.index + 1) % state.cardinalityNext;

        // Write observation
        observations[poolId][indexUpdated] = Observation({
            blockTimestamp: blockTimestamp,
            tickCumulative: tickCumulative,
            initialized: true
        });

        // Update state
        if (state.cardinalityNext > state.cardinality && indexUpdated >= state.cardinality) {
            state.cardinality = state.cardinalityNext;
        }
        state.index = indexUpdated;
        lastTicks[poolId] = tick;

        emit ObservationRecorded(poolId, blockTimestamp, tickCumulative);
    }

    /// @notice Increase observation cardinality for a pool
    /// @param key The pool key
    /// @param cardinalityNext Desired cardinality
    function increaseCardinality(PoolKey calldata key, uint16 cardinalityNext) external {
        PoolId poolId = _toPoolId(key);
        OracleState storage state = oracleStates[poolId];

        uint16 current = state.cardinalityNext;
        if (cardinalityNext <= current) revert CardinalityTooLow();
        if (cardinalityNext > MAX_CARDINALITY) cardinalityNext = MAX_CARDINALITY;

        state.cardinalityNext = cardinalityNext;

        emit CardinalityIncreased(poolId, current, cardinalityNext);
    }

    /// @notice Observe past cumulative tick values
    /// @param key The pool key
    /// @param secondsAgos Array of seconds ago to observe
    /// @return tickCumulatives The cumulative tick values at each time
    function observe(PoolKey calldata key, uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives)
    {
        PoolId poolId = _toPoolId(key);
        OracleState storage state = oracleStates[poolId];

        tickCumulatives = new int56[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; i++) {
            tickCumulatives[i] = _observeSingle(poolId, state, secondsAgos[i]);
        }
    }

    /// @notice Get TWAP tick for a pool
    /// @param key The pool key
    /// @param period Seconds to average over
    /// @return tick The time-weighted average tick
    function getTWAPTick(PoolKey calldata key, uint32 period) external view returns (int24 tick) {
        PoolId poolId = _toPoolId(key);
        OracleState storage state = oracleStates[poolId];

        int56 tickCumulativeEnd = _observeSingle(poolId, state, 0);
        int56 tickCumulativeStart = _observeSingle(poolId, state, period);

        int56 tickCumulativesDelta = tickCumulativeEnd - tickCumulativeStart;
        tick = int24(tickCumulativesDelta / int56(uint56(period)));

        // Round towards negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(period)) != 0)) {
            tick--;
        }
    }

    /// @notice Observe a single point in time
    function _observeSingle(
        PoolId poolId,
        OracleState storage state,
        uint32 secondsAgo
    ) internal view returns (int56 tickCumulative) {
        if (secondsAgo == 0) {
            Observation storage last = observations[poolId][state.index];
            uint32 delta = uint32(block.timestamp) - last.blockTimestamp;
            return last.tickCumulative + int56(lastTicks[poolId]) * int56(uint56(delta));
        }

        uint32 target = uint32(block.timestamp) - secondsAgo;

        // Binary search for the observation
        (Observation storage beforeOrAt, Observation storage atOrAfter) =
            _getSurroundingObservations(poolId, state, target);

        if (target == beforeOrAt.blockTimestamp) {
            return beforeOrAt.tickCumulative;
        } else if (target == atOrAfter.blockTimestamp) {
            return atOrAfter.tickCumulative;
        } else {
            // Interpolate
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;

            int56 tickCumulativeDelta = atOrAfter.tickCumulative - beforeOrAt.tickCumulative;

            return beforeOrAt.tickCumulative +
                (tickCumulativeDelta * int56(uint56(targetDelta))) / int56(uint56(observationTimeDelta));
        }
    }

    /// @notice Find observations surrounding a target timestamp
    function _getSurroundingObservations(
        PoolId poolId,
        OracleState storage state,
        uint32 target
    ) internal view returns (Observation storage beforeOrAt, Observation storage atOrAfter) {
        // Start with the most recent observation
        beforeOrAt = observations[poolId][state.index];

        // If target is at or after the most recent observation
        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                return (beforeOrAt, beforeOrAt);
            }
            // atOrAfter is "now" - handled in _observeSingle
            return (beforeOrAt, beforeOrAt);
        }

        // Find oldest observation
        uint16 oldestIndex = (state.index + 1) % state.cardinality;
        Observation storage oldest = observations[poolId][oldestIndex];
        if (!oldest.initialized) {
            oldest = observations[poolId][0];
            oldestIndex = 0;
        }

        if (target < oldest.blockTimestamp) revert OldestObservationTooRecent();

        // Binary search
        uint16 l = oldestIndex;
        uint16 r = state.index >= oldestIndex ? state.index : state.index + state.cardinality;
        uint16 i;

        while (true) {
            i = (l + r) / 2;

            beforeOrAt = observations[poolId][i % state.cardinality];

            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = observations[poolId][(i + 1) % state.cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;

            if (targetAtOrAfter && target <= atOrAfter.blockTimestamp) {
                return (beforeOrAt, atOrAfter);
            }

            if (!targetAtOrAfter) {
                r = i - 1;
            } else {
                l = i + 1;
            }
        }
    }

    /// @notice Hash pool key to pool ID
    function _toPoolId(PoolKey calldata key) internal pure returns (PoolId) {
        return PoolId.wrap(keccak256(abi.encode(key)));
    }

    /// @notice Get oracle state for a pool
    function getOracleState(PoolKey calldata key) external view returns (
        uint16 index,
        uint16 cardinality,
        uint16 cardinalityNext
    ) {
        OracleState storage state = oracleStates[_toPoolId(key)];
        return (state.index, state.cardinality, state.cardinalityNext);
    }
}

/// @title TruncatedOracleHook
/// @notice V4 oracle hook with truncated history to prevent old price attacks
/// @dev Limits how far back observations can be queried
contract TruncatedOracleHook is OracleHook {
    /// @notice Maximum age of observations that can be queried
    uint32 public immutable maxAge;

    /// @notice Error for queries exceeding max age
    error ObservationTooOld();

    /// @param _poolManager The V4 pool manager
    /// @param _maxAge Maximum age in seconds for observation queries
    constructor(IPoolManager _poolManager, uint32 _maxAge) OracleHook(_poolManager) {
        maxAge = _maxAge;
    }

    /// @notice Observe with age limit enforcement
    function observe(PoolKey calldata key, uint32[] calldata secondsAgos)
        external
        view
        override
        returns (int56[] memory tickCumulatives)
    {
        // Validate all queries are within max age
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            if (secondsAgos[i] > maxAge) revert ObservationTooOld();
        }

        PoolId poolId = _toPoolId(key);
        OracleState storage state = oracleStates[poolId];

        tickCumulatives = new int56[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; i++) {
            tickCumulatives[i] = _observeSingle(poolId, state, secondsAgos[i]);
        }
    }

    /// @notice Get TWAP with age limit
    function getTWAPTick(PoolKey calldata key, uint32 period) external view override returns (int24 tick) {
        if (period > maxAge) revert ObservationTooOld();

        PoolId poolId = _toPoolId(key);
        OracleState storage state = oracleStates[poolId];

        int56 tickCumulativeEnd = _observeSingle(poolId, state, 0);
        int56 tickCumulativeStart = _observeSingle(poolId, state, period);

        int56 tickCumulativesDelta = tickCumulativeEnd - tickCumulativeStart;
        tick = int24(tickCumulativesDelta / int56(uint56(period)));

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(period)) != 0)) {
            tick--;
        }
    }
}

/// @title GeometricMeanOracleHook
/// @notice Oracle hook that also provides geometric mean price directly
contract GeometricMeanOracleHook is OracleHook {
    using TickMathLib for int24;

    constructor(IPoolManager _poolManager) OracleHook(_poolManager) {}

    /// @notice Get geometric mean price for token0 in terms of token1
    /// @param key The pool key
    /// @param period Seconds to average over
    /// @return price Price with 18 decimal precision
    function getGeometricMeanPrice0(PoolKey calldata key, uint32 period)
        external
        view
        returns (uint256 price)
    {
        int24 twapTick = this.getTWAPTick(key, period);
        uint160 sqrtPriceX96 = TickMathLib.getSqrtRatioAtTick(twapTick);

        // price = (sqrtPrice)^2 = sqrtPriceX96^2 / 2^192
        // Multiply by 1e18 for decimals
        price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> 192;
    }
}

/// @notice Tick math helper library
library TickMathLib {
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= 887272, "T");

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

        return uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}
