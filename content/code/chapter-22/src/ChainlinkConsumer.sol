// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ChainlinkConsumer
/// @notice Production-ready Chainlink oracle consumer with validation
/// @dev Demonstrates proper Chainlink integration with staleness checks and circuit breakers

/// @notice Chainlink Aggregator V3 Interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/// @title ChainlinkConsumer
/// @notice Safe Chainlink price feed consumer with comprehensive validation
contract ChainlinkConsumer {
    /// @notice The Chainlink price feed
    AggregatorV3Interface public immutable priceFeed;

    /// @notice Price feed decimals
    uint8 public immutable feedDecimals;

    /// @notice Maximum age for valid prices (staleness threshold)
    uint256 public immutable maxStaleness;

    /// @notice Minimum valid price (circuit breaker)
    int256 public immutable minPrice;

    /// @notice Maximum valid price (circuit breaker)
    int256 public immutable maxPrice;

    /// @notice Target decimals for normalized output
    uint8 public constant TARGET_DECIMALS = 18;

    /// @notice Events
    event PriceQueried(int256 price, uint256 timestamp, uint80 roundId);

    /// @notice Errors
    error StalePrice(uint256 updatedAt, uint256 threshold);
    error InvalidPrice(int256 price);
    error RoundNotComplete(uint80 answeredInRound, uint80 roundId);
    error NegativePrice(int256 price);
    error PriceTooLow(int256 price, int256 minimum);
    error PriceTooHigh(int256 price, int256 maximum);
    error InvalidPriceFeed();

    /// @param _priceFeed Chainlink aggregator address
    /// @param _maxStaleness Maximum age in seconds for valid prices
    /// @param _minPrice Minimum acceptable price (in feed decimals)
    /// @param _maxPrice Maximum acceptable price (in feed decimals)
    constructor(
        address _priceFeed,
        uint256 _maxStaleness,
        int256 _minPrice,
        int256 _maxPrice
    ) {
        if (_priceFeed == address(0)) revert InvalidPriceFeed();

        priceFeed = AggregatorV3Interface(_priceFeed);
        feedDecimals = priceFeed.decimals();
        maxStaleness = _maxStaleness;
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }

    /// @notice Get the latest price with full validation
    /// @return price The validated price in feed decimals
    /// @return updatedAt Timestamp of the price update
    function getLatestPrice() public view returns (int256 price, uint256 updatedAt) {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt_,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Validate round completion
        if (answeredInRound < roundId) {
            revert RoundNotComplete(answeredInRound, roundId);
        }

        // Validate staleness
        if (block.timestamp - updatedAt_ > maxStaleness) {
            revert StalePrice(updatedAt_, maxStaleness);
        }

        // Validate price is positive
        if (answer <= 0) {
            revert NegativePrice(answer);
        }

        // Validate price bounds (circuit breaker)
        if (answer < minPrice) {
            revert PriceTooLow(answer, minPrice);
        }
        if (answer > maxPrice) {
            revert PriceTooHigh(answer, maxPrice);
        }

        return (answer, updatedAt_);
    }

    /// @notice Get the latest price normalized to 18 decimals
    /// @return price The price with 18 decimal precision
    function getLatestPriceNormalized() external view returns (uint256 price) {
        (int256 rawPrice,) = getLatestPrice();

        if (feedDecimals < TARGET_DECIMALS) {
            price = uint256(rawPrice) * 10**(TARGET_DECIMALS - feedDecimals);
        } else if (feedDecimals > TARGET_DECIMALS) {
            price = uint256(rawPrice) / 10**(feedDecimals - TARGET_DECIMALS);
        } else {
            price = uint256(rawPrice);
        }
    }

    /// @notice Safe price query that returns success flag instead of reverting
    /// @return success True if price is valid
    /// @return price The price (0 if invalid)
    /// @return updatedAt Timestamp (0 if invalid)
    function tryGetLatestPrice() external view returns (
        bool success,
        int256 price,
        uint256 updatedAt
    ) {
        try this.getLatestPrice() returns (int256 p, uint256 u) {
            return (true, p, u);
        } catch {
            return (false, 0, 0);
        }
    }

    /// @notice Get historical price from a specific round
    /// @param roundId The round to query
    /// @return price The price for that round
    /// @return updatedAt The timestamp for that round
    function getHistoricalPrice(uint80 roundId) external view returns (
        int256 price,
        uint256 updatedAt
    ) {
        (
            uint80 id,
            int256 answer,
            ,
            uint256 updatedAt_,
            uint80 answeredInRound
        ) = priceFeed.getRoundData(roundId);

        if (answeredInRound < id) {
            revert RoundNotComplete(answeredInRound, id);
        }

        if (answer <= 0) {
            revert NegativePrice(answer);
        }

        return (answer, updatedAt_);
    }

    /// @notice Check if the price feed is healthy
    /// @return healthy True if price is fresh and valid
    function isHealthy() external view returns (bool healthy) {
        try this.getLatestPrice() returns (int256, uint256) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Get feed metadata
    /// @return description Feed description
    /// @return decimals Feed decimals
    /// @return version Feed version
    function getFeedInfo() external view returns (
        string memory description,
        uint8 decimals,
        uint256 version
    ) {
        return (
            priceFeed.description(),
            feedDecimals,
            priceFeed.version()
        );
    }
}

/// @title MultiOracleConsumer
/// @notice Aggregates multiple Chainlink feeds for a derived price
/// @dev Example: ETH/BTC = ETH/USD * USD/BTC
contract MultiOracleConsumer {
    /// @notice Price feed configuration
    struct FeedConfig {
        AggregatorV3Interface feed;
        uint8 decimals;
        bool invert;  // If true, use 1/price
        uint256 maxStaleness;
    }

    /// @notice Configured feeds
    FeedConfig[] public feeds;

    /// @notice Target output decimals
    uint8 public constant OUTPUT_DECIMALS = 18;

    /// @notice Errors
    error NoFeeds();
    error StalePrice();
    error InvalidPrice();

    /// @param _feeds Array of feed addresses
    /// @param _inverts Whether to invert each feed
    /// @param _maxStalenesses Max staleness for each feed
    constructor(
        address[] memory _feeds,
        bool[] memory _inverts,
        uint256[] memory _maxStalenesses
    ) {
        if (_feeds.length == 0) revert NoFeeds();
        require(_feeds.length == _inverts.length && _feeds.length == _maxStalenesses.length, "Length mismatch");

        for (uint256 i = 0; i < _feeds.length; i++) {
            AggregatorV3Interface feed = AggregatorV3Interface(_feeds[i]);
            feeds.push(FeedConfig({
                feed: feed,
                decimals: feed.decimals(),
                invert: _inverts[i],
                maxStaleness: _maxStalenesses[i]
            }));
        }
    }

    /// @notice Get derived price by multiplying/dividing all feeds
    /// @return price The composite price with OUTPUT_DECIMALS precision
    function getDerivedPrice() external view returns (uint256 price) {
        // Start with 1e18 as base (18 decimals precision)
        uint256 result = 10**OUTPUT_DECIMALS;

        for (uint256 i = 0; i < feeds.length; i++) {
            FeedConfig memory config = feeds[i];

            (
                uint80 roundId,
                int256 answer,
                ,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = config.feed.latestRoundData();

            // Validate
            if (answeredInRound < roundId) revert InvalidPrice();
            if (block.timestamp - updatedAt > config.maxStaleness) revert StalePrice();
            if (answer <= 0) revert InvalidPrice();

            // Normalize to 18 decimals
            uint256 normalizedPrice;
            if (config.decimals < OUTPUT_DECIMALS) {
                normalizedPrice = uint256(answer) * 10**(OUTPUT_DECIMALS - config.decimals);
            } else if (config.decimals > OUTPUT_DECIMALS) {
                normalizedPrice = uint256(answer) / 10**(config.decimals - OUTPUT_DECIMALS);
            } else {
                normalizedPrice = uint256(answer);
            }

            // Apply to result
            if (config.invert) {
                // Division: result / price
                result = (result * 10**OUTPUT_DECIMALS) / normalizedPrice;
            } else {
                // Multiplication: result * price
                result = (result * normalizedPrice) / 10**OUTPUT_DECIMALS;
            }
        }

        return result;
    }

    /// @notice Check health of all feeds
    /// @return healthy True if all feeds are fresh and valid
    function allFeedsHealthy() external view returns (bool healthy) {
        for (uint256 i = 0; i < feeds.length; i++) {
            FeedConfig memory config = feeds[i];

            try config.feed.latestRoundData() returns (
                uint80 roundId,
                int256 answer,
                uint256,
                uint256 updatedAt,
                uint80 answeredInRound
            ) {
                if (answeredInRound < roundId) return false;
                if (block.timestamp - updatedAt > config.maxStaleness) return false;
                if (answer <= 0) return false;
            } catch {
                return false;
            }
        }
        return true;
    }
}

/// @title ChainlinkPriceWithFallback
/// @notice Chainlink consumer with fallback to secondary oracle
contract ChainlinkPriceWithFallback {
    /// @notice Primary price feed (Chainlink)
    AggregatorV3Interface public immutable primaryFeed;

    /// @notice Fallback price feed
    AggregatorV3Interface public immutable fallbackFeed;

    /// @notice Configuration
    uint256 public immutable maxStaleness;
    uint8 public immutable primaryDecimals;
    uint8 public immutable fallbackDecimals;

    /// @notice Track which source was used
    enum PriceSource { Primary, Fallback, None }

    /// @notice Events
    event FallbackUsed(string reason);

    /// @notice Errors
    error AllOraclesFailed();

    constructor(
        address _primaryFeed,
        address _fallbackFeed,
        uint256 _maxStaleness
    ) {
        primaryFeed = AggregatorV3Interface(_primaryFeed);
        fallbackFeed = AggregatorV3Interface(_fallbackFeed);
        maxStaleness = _maxStaleness;
        primaryDecimals = primaryFeed.decimals();
        fallbackDecimals = fallbackFeed.decimals();
    }

    /// @notice Get price with automatic fallback
    /// @return price Normalized price (18 decimals)
    /// @return source Which oracle provided the price
    function getPrice() external view returns (uint256 price, PriceSource source) {
        // Try primary
        (bool primaryOk, uint256 primaryPrice) = _tryGetPrice(primaryFeed, primaryDecimals);
        if (primaryOk) {
            return (primaryPrice, PriceSource.Primary);
        }

        // Try fallback
        (bool fallbackOk, uint256 fallbackPrice) = _tryGetPrice(fallbackFeed, fallbackDecimals);
        if (fallbackOk) {
            return (fallbackPrice, PriceSource.Fallback);
        }

        revert AllOraclesFailed();
    }

    /// @notice Try to get price from a feed
    function _tryGetPrice(AggregatorV3Interface feed, uint8 decimals)
        internal
        view
        returns (bool success, uint256 price)
    {
        try feed.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Validate
            if (answeredInRound < roundId) return (false, 0);
            if (block.timestamp - updatedAt > maxStaleness) return (false, 0);
            if (answer <= 0) return (false, 0);

            // Normalize to 18 decimals
            uint256 normalized;
            if (decimals < 18) {
                normalized = uint256(answer) * 10**(18 - decimals);
            } else if (decimals > 18) {
                normalized = uint256(answer) / 10**(decimals - 18);
            } else {
                normalized = uint256(answer);
            }

            return (true, normalized);
        } catch {
            return (false, 0);
        }
    }

    /// @notice Get status of both oracles
    /// @return primaryHealthy True if primary is responding with fresh data
    /// @return fallbackHealthy True if fallback is responding with fresh data
    function getOracleStatus() external view returns (
        bool primaryHealthy,
        bool fallbackHealthy
    ) {
        (primaryHealthy,) = _tryGetPrice(primaryFeed, primaryDecimals);
        (fallbackHealthy,) = _tryGetPrice(fallbackFeed, fallbackDecimals);
    }
}
