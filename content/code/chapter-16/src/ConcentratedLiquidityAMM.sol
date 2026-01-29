// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC20Minimal
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title ConcentratedLiquidityAMM
/// @notice Simplified Uniswap V3-style concentrated liquidity AMM
/// @dev Educational implementation - not production ready
contract ConcentratedLiquidityAMM {
    /// @notice The two tokens in the pool
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    /// @notice Tick spacing (determines price granularity)
    int24 public immutable tickSpacing;

    /// @notice Fee in basis points
    uint24 public immutable fee;

    /// @notice Current sqrt price as Q64.96
    uint160 public sqrtPriceX96;

    /// @notice Current tick
    int24 public tick;

    /// @notice Total liquidity in range
    uint128 public liquidity;

    /// @notice Tick bitmap - tracks initialized ticks
    mapping(int16 => uint256) public tickBitmap;

    /// @notice Tick info
    struct TickInfo {
        uint128 liquidityGross;    // Total liquidity referencing this tick
        int128 liquidityNet;       // Net liquidity change when crossing
        bool initialized;
    }
    mapping(int24 => TickInfo) public ticks;

    /// @notice Position info
    struct Position {
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }
    mapping(bytes32 => Position) public positions;

    /// @notice Global fee growth
    uint256 public feeGrowthGlobal0X128;
    uint256 public feeGrowthGlobal1X128;

    /// @notice Events
    event Mint(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Errors
    error InvalidTicks();
    error InsufficientLiquidity();
    error NotEnoughLiquidity();

    /// @notice Constants
    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = 887272;

    /// @notice Reentrancy lock
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing,
        uint160 _sqrtPriceX96
    ) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        fee = _fee;
        tickSpacing = _tickSpacing;
        sqrtPriceX96 = _sqrtPriceX96;
        tick = getTickAtSqrtRatio(_sqrtPriceX96);
    }

    /// @notice Add concentrated liquidity
    /// @param tickLower Lower tick bound
    /// @param tickUpper Upper tick bound
    /// @param amount Liquidity to add
    /// @return amount0 Token0 deposited
    /// @return amount1 Token1 deposited
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0, "Zero liquidity");
        require(tickLower < tickUpper, "Invalid range");
        require(tickLower >= MIN_TICK && tickUpper <= MAX_TICK, "Out of bounds");
        require(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0, "Invalid tick");

        // Calculate token amounts needed
        (amount0, amount1) = getAmountsForLiquidity(
            sqrtPriceX96,
            getSqrtRatioAtTick(tickLower),
            getSqrtRatioAtTick(tickUpper),
            amount
        );

        // Update position
        bytes32 positionKey = keccak256(abi.encodePacked(recipient, tickLower, tickUpper));
        Position storage position = positions[positionKey];
        position.liquidity += amount;

        // Update ticks
        _updateTick(tickLower, int128(uint128(amount)), false);
        _updateTick(tickUpper, -int128(uint128(amount)), true);

        // Update global liquidity if in range
        if (tickLower <= tick && tick < tickUpper) {
            liquidity += amount;
        }

        // Transfer tokens
        if (amount0 > 0) {
            token0.transferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            token1.transferFrom(msg.sender, address(this), amount1);
        }

        emit Mint(recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    /// @notice Remove concentrated liquidity
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external lock returns (uint256 amount0, uint256 amount1) {
        bytes32 positionKey = keccak256(abi.encodePacked(msg.sender, tickLower, tickUpper));
        Position storage position = positions[positionKey];

        require(position.liquidity >= amount, "Insufficient position");

        // Calculate token amounts to return
        (amount0, amount1) = getAmountsForLiquidity(
            sqrtPriceX96,
            getSqrtRatioAtTick(tickLower),
            getSqrtRatioAtTick(tickUpper),
            amount
        );

        // Update position
        position.liquidity -= amount;

        // Update ticks
        _updateTick(tickLower, -int128(uint128(amount)), false);
        _updateTick(tickUpper, int128(uint128(amount)), true);

        // Update global liquidity if in range
        if (tickLower <= tick && tick < tickUpper) {
            liquidity -= amount;
        }

        // Transfer tokens back
        if (amount0 > 0) {
            token0.transfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            token1.transfer(msg.sender, amount1);
        }

        emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
    }

    /// @notice Execute a swap
    /// @param zeroForOne Direction of swap (true = token0 -> token1)
    /// @param amountSpecified Amount to swap (positive = exact input)
    /// @param sqrtPriceLimitX96 Price limit
    /// @return amount0 Token0 delta (negative = output)
    /// @return amount1 Token1 delta (negative = output)
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external lock returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, "Zero amount");

        // Validate price limit direction
        if (zeroForOne) {
            require(sqrtPriceLimitX96 < sqrtPriceX96 && sqrtPriceLimitX96 > 0, "Invalid limit");
        } else {
            require(sqrtPriceLimitX96 > sqrtPriceX96, "Invalid limit");
        }

        bool exactInput = amountSpecified > 0;
        int256 amountRemaining = amountSpecified;
        uint160 sqrtPriceX96Next = sqrtPriceX96;
        int24 tickCurrent = tick;
        uint128 liquidityCurrent = liquidity;

        // Swap loop - simplified single step for educational purposes
        while (amountRemaining != 0 && sqrtPriceX96Next != sqrtPriceLimitX96) {
            // Find next initialized tick
            int24 tickNext = _nextInitializedTick(tickCurrent, zeroForOne);
            uint160 sqrtPriceNextX96 = getSqrtRatioAtTick(tickNext);

            // Clamp to price limit
            if (zeroForOne) {
                if (sqrtPriceNextX96 < sqrtPriceLimitX96) {
                    sqrtPriceNextX96 = sqrtPriceLimitX96;
                }
            } else {
                if (sqrtPriceNextX96 > sqrtPriceLimitX96) {
                    sqrtPriceNextX96 = sqrtPriceLimitX96;
                }
            }

            // Compute step amounts
            (uint256 amountIn, uint256 amountOut) = _computeSwapStep(
                sqrtPriceX96Next,
                sqrtPriceNextX96,
                liquidityCurrent,
                uint256(amountRemaining > 0 ? amountRemaining : -amountRemaining)
            );

            // Update amounts
            if (exactInput) {
                amountRemaining -= int256(amountIn);
            } else {
                amountRemaining += int256(amountOut);
            }

            if (zeroForOne) {
                amount0 += int256(amountIn);
                amount1 -= int256(amountOut);
            } else {
                amount0 -= int256(amountOut);
                amount1 += int256(amountIn);
            }

            // Move to next price
            sqrtPriceX96Next = sqrtPriceNextX96;

            // Cross tick if we reached it
            if (sqrtPriceX96Next == getSqrtRatioAtTick(tickNext)) {
                int128 liquidityDelta = ticks[tickNext].liquidityNet;
                if (zeroForOne) {
                    liquidityDelta = -liquidityDelta;
                }
                liquidityCurrent = liquidityDelta < 0
                    ? liquidityCurrent - uint128(-liquidityDelta)
                    : liquidityCurrent + uint128(liquidityDelta);
                tickCurrent = zeroForOne ? tickNext - 1 : tickNext;
            }

            // Prevent infinite loops in simplified implementation
            break;
        }

        // Update state
        sqrtPriceX96 = sqrtPriceX96Next;
        tick = tickCurrent;
        liquidity = liquidityCurrent;

        // Transfer tokens
        if (amount0 < 0) {
            token0.transfer(recipient, uint256(-amount0));
        }
        if (amount1 < 0) {
            token1.transfer(recipient, uint256(-amount1));
        }
        if (amount0 > 0) {
            token0.transferFrom(msg.sender, address(this), uint256(amount0));
        }
        if (amount1 > 0) {
            token1.transferFrom(msg.sender, address(this), uint256(amount1));
        }

        emit Swap(msg.sender, recipient, amount0, amount1, sqrtPriceX96, tick);
    }

    /// @notice Update tick data
    function _updateTick(int24 tickIdx, int128 liquidityDelta, bool upper) internal {
        TickInfo storage info = ticks[tickIdx];

        if (liquidityDelta > 0) {
            info.liquidityGross += uint128(liquidityDelta);
        } else {
            info.liquidityGross -= uint128(-liquidityDelta);
        }

        info.liquidityNet += upper ? -liquidityDelta : liquidityDelta;
        info.initialized = info.liquidityGross > 0;
    }

    /// @notice Find next initialized tick (simplified)
    function _nextInitializedTick(int24 tickCurrent, bool zeroForOne) internal view returns (int24) {
        // Simplified: just move by tick spacing
        if (zeroForOne) {
            return tickCurrent - tickSpacing;
        }
        return tickCurrent + tickSpacing;
    }

    /// @notice Compute swap step amounts (simplified)
    function _computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity_,
        uint256 amountRemaining
    ) internal pure returns (uint256 amountIn, uint256 amountOut) {
        // Simplified calculation
        // In real V3, this involves precise fixed-point math

        bool zeroForOne = sqrtRatioCurrentX96 > sqrtRatioTargetX96;

        uint256 priceDelta = zeroForOne
            ? sqrtRatioCurrentX96 - sqrtRatioTargetX96
            : sqrtRatioTargetX96 - sqrtRatioCurrentX96;

        // Very simplified: assume linear relationship for educational purposes
        uint256 maxAmount = (uint256(liquidity_) * priceDelta) / (1 << 96);

        if (amountRemaining >= maxAmount) {
            amountIn = maxAmount;
            amountOut = maxAmount; // Simplified: 1:1 ratio
        } else {
            amountIn = amountRemaining;
            amountOut = amountRemaining;
        }
    }

    /// @notice Get sqrt ratio at tick
    function getSqrtRatioAtTick(int24 tickIdx) public pure returns (uint160) {
        uint256 absTick = tickIdx < 0 ? uint256(-int256(tickIdx)) : uint256(int256(tickIdx));
        require(absTick <= uint256(int256(MAX_TICK)), "Tick out of bounds");

        uint256 ratio = 0x100000000000000000000000000000000;

        if (absTick & 0x1 != 0) ratio = (ratio * 0xfffcb933bd6fad37aa2d162d1a594001) >> 128;
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

        if (tickIdx > 0) ratio = type(uint256).max / ratio;

        return uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Get tick at sqrt ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96_) public pure returns (int24 tickIdx) {
        // Simplified implementation using log approximation
        uint256 ratio = uint256(sqrtPriceX96_) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        int256 log_2 = (int256(msb) - 128) << 64;

        // Simplified tick calculation
        tickIdx = int24((log_2 * 255738958999603826347141) >> 128);
    }

    /// @notice Calculate amounts for liquidity
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96_,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity_
    ) public pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }

        if (sqrtRatioX96_ <= sqrtRatioAX96) {
            // Below range: only token0 needed
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity_);
        } else if (sqrtRatioX96_ < sqrtRatioBX96) {
            // In range: both tokens needed
            amount0 = getAmount0ForLiquidity(sqrtRatioX96_, sqrtRatioBX96, liquidity_);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96_, liquidity_);
        } else {
            // Above range: only token1 needed
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity_);
        }
    }

    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity_
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        return (uint256(liquidity_) << 96) * (sqrtRatioBX96 - sqrtRatioAX96) / sqrtRatioBX96 / sqrtRatioAX96;
    }

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity_
    ) internal pure returns (uint256) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        return uint256(liquidity_) * (sqrtRatioBX96 - sqrtRatioAX96) / (1 << 96);
    }
}
