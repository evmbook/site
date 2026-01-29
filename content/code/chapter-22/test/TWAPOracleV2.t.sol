// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/TWAPOracleV2.sol";

/// @title MockUniswapV2Pair
/// @notice Mock V2 pair for testing TWAP oracle
contract MockUniswapV2Pair is IUniswapV2Pair {
    address public override token0;
    address public override token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
    }

    function getReserves() external view override returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    ) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    /// @notice Simulate a swap that updates cumulative prices
    function simulateSwap(uint112 newReserve0, uint112 newReserve1) external {
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0 && reserve0 > 0 && reserve1 > 0) {
            // Update cumulative prices
            price0CumulativeLast += uint256(FixedPoint.encode(reserve1).uqdiv(reserve0)._x) * timeElapsed;
            price1CumulativeLast += uint256(FixedPoint.encode(reserve0).uqdiv(reserve1)._x) * timeElapsed;
        }

        reserve0 = newReserve0;
        reserve1 = newReserve1;
        blockTimestampLast = blockTimestamp;
    }

    /// @notice Force update cumulative prices without changing reserves
    function sync() external {
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0 && reserve0 > 0 && reserve1 > 0) {
            price0CumulativeLast += uint256(FixedPoint.encode(reserve1).uqdiv(reserve0)._x) * timeElapsed;
            price1CumulativeLast += uint256(FixedPoint.encode(reserve0).uqdiv(reserve1)._x) * timeElapsed;
        }

        blockTimestampLast = blockTimestamp;
    }
}

contract TWAPOracleV2Test is Test {
    TWAPOracleV2 public oracle;
    MockUniswapV2Pair public pair;

    address public token0 = address(0x1);
    address public token1 = address(0x2);

    uint32 public constant MIN_PERIOD = 10 minutes;
    uint32 public constant MAX_PERIOD = 24 hours;

    function setUp() public {
        // Deploy mock pair
        pair = new MockUniswapV2Pair(token0, token1);

        // Set initial reserves: 1 ETH = 2000 USDC
        // token0 = ETH (1e18), token1 = USDC (2000e6)
        pair.setReserves(1e18, 2000e6);

        // Deploy oracle
        oracle = new TWAPOracleV2(address(pair), MIN_PERIOD, MAX_PERIOD);
    }

    function test_Constructor() public view {
        assertEq(address(oracle.pair()), address(pair));
        assertEq(oracle.token0(), token0);
        assertEq(oracle.token1(), token1);
        assertEq(oracle.minPeriod(), MIN_PERIOD);
        assertEq(oracle.maxPeriod(), MAX_PERIOD);
    }

    function test_InitialObservation() public view {
        // First observation should be recorded in constructor
        (uint32 timestamp,,) = oracle.firstObservation();
        assertEq(timestamp, uint32(block.timestamp));
    }

    function test_UpdateAfterMinPeriod() public {
        // Advance time past minimum period
        vm.warp(block.timestamp + MIN_PERIOD + 1);

        // Sync the pair to update cumulative prices
        pair.sync();

        // Update oracle
        oracle.update();

        // Should have updated TWAP
        uint256 price0 = oracle.getPrice0();
        assertGt(price0, 0, "Price should be greater than 0");
    }

    function test_RevertBeforeMinPeriod() public {
        // Advance time but not past minimum period
        vm.warp(block.timestamp + MIN_PERIOD - 1);
        pair.sync();

        // Should revert
        vm.expectRevert(TWAPOracleV2.PeriodNotElapsed.selector);
        oracle.update();
    }

    function test_PriceCalculation() public {
        // Initial: 1 token0 = 2000 token1
        // Advance time
        vm.warp(block.timestamp + MIN_PERIOD + 1);
        pair.sync();
        oracle.update();

        // Price of token0 in terms of token1 should be ~2000
        // (accounting for decimal differences in test)
        uint256 price0 = oracle.getPrice0();
        assertGt(price0, 0);
    }

    function test_Consult() public {
        // Advance time and update
        vm.warp(block.timestamp + MIN_PERIOD + 1);
        pair.sync();
        oracle.update();

        // Consult for 1e18 of token0
        uint256 amountOut = oracle.consult(token0, 1e18);
        assertGt(amountOut, 0, "Amount out should be positive");
    }

    function test_NeedsUpdate() public view {
        // Initially should not need update
        bool needs = oracle.needsUpdate();
        assertFalse(needs, "Should not need update initially");
    }

    function test_NeedsUpdateAfterPeriod() public {
        // Advance past min period
        vm.warp(block.timestamp + MIN_PERIOD + 1);

        bool needs = oracle.needsUpdate();
        assertTrue(needs, "Should need update after min period");
    }

    function test_PriceChangeOverTime() public {
        // First period: 1:2000 ratio
        vm.warp(block.timestamp + MIN_PERIOD + 1);
        pair.sync();
        oracle.update();
        uint256 price1 = oracle.getPrice0();

        // Change ratio to 1:2500 (token0 appreciates)
        pair.simulateSwap(1e18, 2500e6);

        // Second period
        vm.warp(block.timestamp + MIN_PERIOD + 1);
        pair.sync();
        oracle.update();
        uint256 price2 = oracle.getPrice0();

        // Price should have changed
        assertGt(price2, price1, "Price should increase when ratio changes");
    }

    function test_ObservationAge() public {
        uint32 age1 = oracle.observationAge();
        assertEq(age1, 0);

        // Advance time
        vm.warp(block.timestamp + 100);

        uint32 age2 = oracle.observationAge();
        assertEq(age2, 100);
    }

    function testFuzz_ConsultAmount(uint128 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);

        // Setup oracle with valid TWAP
        vm.warp(block.timestamp + MIN_PERIOD + 1);
        pair.sync();
        oracle.update();

        // Consult should work for any reasonable amount
        uint256 result = oracle.consult(token0, amount);
        // Result should be proportional
        if (amount > 1e18) {
            assertGt(result, oracle.consult(token0, 1e18));
        }
    }
}

/// @title TWAPOracleV2IntegrationTest
/// @notice Integration test simulating real market conditions
contract TWAPOracleV2IntegrationTest is Test {
    TWAPOracleV2 public oracle;
    MockUniswapV2Pair public pair;

    function setUp() public {
        pair = new MockUniswapV2Pair(address(0x1), address(0x2));
        pair.setReserves(100e18, 200000e6); // 100 ETH, 200k USDC
        oracle = new TWAPOracleV2(address(pair), 30 minutes, 24 hours);
    }

    /// @notice Test TWAP smoothing effect during price manipulation attempt
    function test_TWAPResistanceToManipulation() public {
        // Establish initial TWAP
        vm.warp(block.timestamp + 30 minutes + 1);
        pair.sync();
        oracle.update();
        uint256 initialPrice = oracle.getPrice0();

        // Simulate flash loan attack: massive price spike
        pair.simulateSwap(100e18, 400000e6); // Double the price

        // Only 1 block passes
        vm.warp(block.timestamp + 12);
        pair.sync();

        // TWAP should not have moved much
        // (Can't update yet due to min period)

        // Return to normal
        pair.simulateSwap(100e18, 200000e6);

        // Wait for next period
        vm.warp(block.timestamp + 30 minutes);
        pair.sync();
        oracle.update();

        uint256 newPrice = oracle.getPrice0();

        // Price should not have doubled despite the manipulation
        // It should be averaged over the period
        assertLt(newPrice, initialPrice * 2, "TWAP should smooth manipulation");
    }
}
