// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ChainlinkConsumer.sol";

/// @title MockAggregatorV3
/// @notice Mock Chainlink aggregator for testing
contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 private _decimals;
    string private _description;
    uint256 private _version;

    int256 private _answer;
    uint256 private _updatedAt;
    uint80 private _roundId;
    uint80 private _answeredInRound;

    bool public shouldRevert;

    constructor(uint8 decimals_, string memory description_) {
        _decimals = decimals_;
        _description = description_;
        _version = 1;
        _roundId = 1;
        _answeredInRound = 1;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external view override returns (uint256) {
        return _version;
    }

    function setPrice(int256 price, uint256 timestamp) external {
        _answer = price;
        _updatedAt = timestamp;
        _roundId++;
        _answeredInRound = _roundId;
    }

    function setStaleRound() external {
        // Set answeredInRound less than roundId to simulate incomplete round
        _answeredInRound = _roundId - 1;
    }

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function getRoundData(uint80 roundId_) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        require(!shouldRevert, "Mock revert");
        return (roundId_, _answer, _updatedAt, _updatedAt, _answeredInRound);
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        require(!shouldRevert, "Mock revert");
        return (_roundId, _answer, _updatedAt, _updatedAt, _answeredInRound);
    }
}

contract ChainlinkConsumerTest is Test {
    ChainlinkConsumer public consumer;
    MockAggregatorV3 public mockFeed;

    int256 constant INITIAL_PRICE = 2000e8; // $2000 with 8 decimals
    uint256 constant MAX_STALENESS = 1 hours;
    int256 constant MIN_PRICE = 100e8;  // $100
    int256 constant MAX_PRICE = 10000e8; // $10000

    function setUp() public {
        // Deploy mock feed (8 decimals like ETH/USD)
        mockFeed = new MockAggregatorV3(8, "ETH / USD");

        // Set initial price
        mockFeed.setPrice(INITIAL_PRICE, block.timestamp);

        // Deploy consumer
        consumer = new ChainlinkConsumer(
            address(mockFeed),
            MAX_STALENESS,
            MIN_PRICE,
            MAX_PRICE
        );
    }

    function test_Constructor() public view {
        assertEq(address(consumer.priceFeed()), address(mockFeed));
        assertEq(consumer.feedDecimals(), 8);
        assertEq(consumer.maxStaleness(), MAX_STALENESS);
        assertEq(consumer.minPrice(), MIN_PRICE);
        assertEq(consumer.maxPrice(), MAX_PRICE);
    }

    function test_GetLatestPrice() public view {
        (int256 price, uint256 updatedAt) = consumer.getLatestPrice();
        assertEq(price, INITIAL_PRICE);
        assertEq(updatedAt, block.timestamp);
    }

    function test_GetLatestPriceNormalized() public view {
        uint256 normalized = consumer.getLatestPriceNormalized();
        // 2000e8 with 8 decimals -> 2000e18 with 18 decimals
        assertEq(normalized, 2000e18);
    }

    function test_RevertOnStalePrice() public {
        // Advance time past staleness threshold
        vm.warp(block.timestamp + MAX_STALENESS + 1);

        vm.expectRevert(abi.encodeWithSelector(
            ChainlinkConsumer.StalePrice.selector,
            block.timestamp - MAX_STALENESS - 1,
            MAX_STALENESS
        ));
        consumer.getLatestPrice();
    }

    function test_RevertOnNegativePrice() public {
        mockFeed.setPrice(-100e8, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(
            ChainlinkConsumer.NegativePrice.selector,
            -100e8
        ));
        consumer.getLatestPrice();
    }

    function test_RevertOnZeroPrice() public {
        mockFeed.setPrice(0, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(
            ChainlinkConsumer.NegativePrice.selector,
            0
        ));
        consumer.getLatestPrice();
    }

    function test_RevertOnPriceTooLow() public {
        mockFeed.setPrice(MIN_PRICE - 1, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(
            ChainlinkConsumer.PriceTooLow.selector,
            MIN_PRICE - 1,
            MIN_PRICE
        ));
        consumer.getLatestPrice();
    }

    function test_RevertOnPriceTooHigh() public {
        mockFeed.setPrice(MAX_PRICE + 1, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(
            ChainlinkConsumer.PriceTooHigh.selector,
            MAX_PRICE + 1,
            MAX_PRICE
        ));
        consumer.getLatestPrice();
    }

    function test_RevertOnIncompleteRound() public {
        mockFeed.setStaleRound();

        vm.expectRevert(); // RoundNotComplete
        consumer.getLatestPrice();
    }

    function test_TryGetLatestPrice_Success() public view {
        (bool success, int256 price, uint256 updatedAt) = consumer.tryGetLatestPrice();
        assertTrue(success);
        assertEq(price, INITIAL_PRICE);
        assertGt(updatedAt, 0);
    }

    function test_TryGetLatestPrice_Failure() public {
        // Make price stale
        vm.warp(block.timestamp + MAX_STALENESS + 1);

        (bool success, int256 price, uint256 updatedAt) = consumer.tryGetLatestPrice();
        assertFalse(success);
        assertEq(price, 0);
        assertEq(updatedAt, 0);
    }

    function test_IsHealthy() public view {
        assertTrue(consumer.isHealthy());
    }

    function test_IsHealthy_Stale() public {
        vm.warp(block.timestamp + MAX_STALENESS + 1);
        assertFalse(consumer.isHealthy());
    }

    function test_GetFeedInfo() public view {
        (string memory desc, uint8 decimals, uint256 version) = consumer.getFeedInfo();
        assertEq(desc, "ETH / USD");
        assertEq(decimals, 8);
        assertEq(version, 1);
    }

    function testFuzz_PriceWithinBounds(int256 price) public {
        // Bound price to valid range
        vm.assume(price >= MIN_PRICE && price <= MAX_PRICE);

        mockFeed.setPrice(price, block.timestamp);

        (int256 returnedPrice,) = consumer.getLatestPrice();
        assertEq(returnedPrice, price);
    }

    function test_NormalizeFrom6Decimals() public {
        // Create feed with 6 decimals (like USDC pairs)
        MockAggregatorV3 feed6 = new MockAggregatorV3(6, "USDC / USD");
        feed6.setPrice(1e6, block.timestamp); // $1

        ChainlinkConsumer consumer6 = new ChainlinkConsumer(
            address(feed6),
            MAX_STALENESS,
            0,
            type(int256).max
        );

        uint256 normalized = consumer6.getLatestPriceNormalized();
        assertEq(normalized, 1e18); // Should be 1e18
    }

    function test_NormalizeFrom18Decimals() public {
        // Create feed with 18 decimals
        MockAggregatorV3 feed18 = new MockAggregatorV3(18, "Token / ETH");
        feed18.setPrice(1e18, block.timestamp);

        ChainlinkConsumer consumer18 = new ChainlinkConsumer(
            address(feed18),
            MAX_STALENESS,
            0,
            type(int256).max
        );

        uint256 normalized = consumer18.getLatestPriceNormalized();
        assertEq(normalized, 1e18);
    }
}

contract ChainlinkPriceWithFallbackTest is Test {
    ChainlinkPriceWithFallback public consumer;
    MockAggregatorV3 public primaryFeed;
    MockAggregatorV3 public fallbackFeed;

    uint256 constant MAX_STALENESS = 1 hours;

    function setUp() public {
        primaryFeed = new MockAggregatorV3(8, "Primary ETH/USD");
        fallbackFeed = new MockAggregatorV3(8, "Fallback ETH/USD");

        primaryFeed.setPrice(2000e8, block.timestamp);
        fallbackFeed.setPrice(2001e8, block.timestamp);

        consumer = new ChainlinkPriceWithFallback(
            address(primaryFeed),
            address(fallbackFeed),
            MAX_STALENESS
        );
    }

    function test_UsesPrimaryWhenHealthy() public view {
        (uint256 price, ChainlinkPriceWithFallback.PriceSource source) = consumer.getPrice();

        assertEq(price, 2000e18); // Normalized
        assertEq(uint256(source), uint256(ChainlinkPriceWithFallback.PriceSource.Primary));
    }

    function test_UsesFallbackWhenPrimaryStale() public {
        // Make primary stale
        vm.warp(block.timestamp + MAX_STALENESS + 1);

        // Update fallback to be fresh
        fallbackFeed.setPrice(2001e8, block.timestamp);

        (uint256 price, ChainlinkPriceWithFallback.PriceSource source) = consumer.getPrice();

        assertEq(price, 2001e18);
        assertEq(uint256(source), uint256(ChainlinkPriceWithFallback.PriceSource.Fallback));
    }

    function test_UsesFallbackWhenPrimaryReverts() public {
        primaryFeed.setShouldRevert(true);

        (uint256 price, ChainlinkPriceWithFallback.PriceSource source) = consumer.getPrice();

        assertEq(price, 2001e18);
        assertEq(uint256(source), uint256(ChainlinkPriceWithFallback.PriceSource.Fallback));
    }

    function test_RevertWhenBothFail() public {
        primaryFeed.setShouldRevert(true);
        fallbackFeed.setShouldRevert(true);

        vm.expectRevert(ChainlinkPriceWithFallback.AllOraclesFailed.selector);
        consumer.getPrice();
    }

    function test_GetOracleStatus() public {
        (bool primaryHealthy, bool fallbackHealthy) = consumer.getOracleStatus();
        assertTrue(primaryHealthy);
        assertTrue(fallbackHealthy);
    }

    function test_GetOracleStatus_PrimaryUnhealthy() public {
        vm.warp(block.timestamp + MAX_STALENESS + 1);
        fallbackFeed.setPrice(2001e8, block.timestamp);

        (bool primaryHealthy, bool fallbackHealthy) = consumer.getOracleStatus();
        assertFalse(primaryHealthy);
        assertTrue(fallbackHealthy);
    }
}

contract MultiOracleConsumerTest is Test {
    MultiOracleConsumer public consumer;
    MockAggregatorV3 public ethUsdFeed;
    MockAggregatorV3 public btcUsdFeed;

    function setUp() public {
        // ETH/USD: $2000 (8 decimals)
        ethUsdFeed = new MockAggregatorV3(8, "ETH / USD");
        ethUsdFeed.setPrice(2000e8, block.timestamp);

        // BTC/USD: $40000 (8 decimals)
        btcUsdFeed = new MockAggregatorV3(8, "BTC / USD");
        btcUsdFeed.setPrice(40000e8, block.timestamp);

        // Create ETH/BTC oracle: ETH/USD * USD/BTC = ETH/BTC
        // Need to invert BTC/USD to get USD/BTC
        address[] memory feeds = new address[](2);
        feeds[0] = address(ethUsdFeed);
        feeds[1] = address(btcUsdFeed);

        bool[] memory inverts = new bool[](2);
        inverts[0] = false; // ETH/USD as-is
        inverts[1] = true;  // Invert BTC/USD to USD/BTC

        uint256[] memory stalenesses = new uint256[](2);
        stalenesses[0] = 1 hours;
        stalenesses[1] = 1 hours;

        consumer = new MultiOracleConsumer(feeds, inverts, stalenesses);
    }

    function test_DerivedPrice() public view {
        // ETH/BTC = ETH/USD * USD/BTC = 2000 * (1/40000) = 0.05
        uint256 price = consumer.getDerivedPrice();

        // Should be 0.05e18 = 5e16
        assertEq(price, 5e16);
    }

    function test_AllFeedsHealthy() public view {
        assertTrue(consumer.allFeedsHealthy());
    }

    function test_FeedUnhealthyOnStale() public {
        vm.warp(block.timestamp + 2 hours);
        assertFalse(consumer.allFeedsHealthy());
    }
}
