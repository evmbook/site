// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title MultiOracleAggregator
/// @notice Aggregates multiple oracle sources with configurable strategies
/// @dev Implements median, weighted average, and fallback patterns

/// @notice Generic oracle interface
interface IOracle {
    function getPrice() external view returns (uint256 price, uint256 updatedAt);
    function isHealthy() external view returns (bool);
}

/// @title MedianOracle
/// @notice Aggregates multiple oracles using median price
/// @dev Median is resistant to single oracle manipulation
contract MedianOracle {
    /// @notice Oracle configuration
    struct OracleConfig {
        address oracle;
        uint256 maxStaleness;
        bool enabled;
    }

    /// @notice List of configured oracles
    OracleConfig[] public oracles;

    /// @notice Minimum oracles required for valid price
    uint256 public immutable minOracles;

    /// @notice Owner for oracle management
    address public owner;

    /// @notice Events
    event OracleAdded(address indexed oracle, uint256 maxStaleness);
    event OracleRemoved(address indexed oracle);
    event OracleEnabled(address indexed oracle);
    event OracleDisabled(address indexed oracle);
    event PriceUpdated(uint256 medianPrice, uint256 numOracles);

    /// @notice Errors
    error InsufficientOracles(uint256 available, uint256 required);
    error OracleNotFound();
    error NotOwner();
    error InvalidOracle();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @param _minOracles Minimum oracles needed for valid median
    constructor(uint256 _minOracles) {
        minOracles = _minOracles;
        owner = msg.sender;
    }

    /// @notice Add a new oracle
    /// @param oracle Oracle address implementing IOracle
    /// @param maxStaleness Maximum age for valid prices
    function addOracle(address oracle, uint256 maxStaleness) external onlyOwner {
        if (oracle == address(0)) revert InvalidOracle();

        oracles.push(OracleConfig({
            oracle: oracle,
            maxStaleness: maxStaleness,
            enabled: true
        }));

        emit OracleAdded(oracle, maxStaleness);
    }

    /// @notice Remove an oracle
    /// @param index Index in the oracles array
    function removeOracle(uint256 index) external onlyOwner {
        if (index >= oracles.length) revert OracleNotFound();

        address removed = oracles[index].oracle;

        // Swap with last and pop
        oracles[index] = oracles[oracles.length - 1];
        oracles.pop();

        emit OracleRemoved(removed);
    }

    /// @notice Enable/disable an oracle
    /// @param index Index in the oracles array
    /// @param enabled New enabled state
    function setOracleEnabled(uint256 index, bool enabled) external onlyOwner {
        if (index >= oracles.length) revert OracleNotFound();

        oracles[index].enabled = enabled;

        if (enabled) {
            emit OracleEnabled(oracles[index].oracle);
        } else {
            emit OracleDisabled(oracles[index].oracle);
        }
    }

    /// @notice Get median price from all healthy oracles
    /// @return price The median price
    /// @return numOracles Number of oracles used
    function getMedianPrice() external view returns (uint256 price, uint256 numOracles) {
        uint256[] memory prices = _collectPrices();

        if (prices.length < minOracles) {
            revert InsufficientOracles(prices.length, minOracles);
        }

        // Sort prices
        _sort(prices);

        // Calculate median
        uint256 mid = prices.length / 2;
        if (prices.length % 2 == 0) {
            price = (prices[mid - 1] + prices[mid]) / 2;
        } else {
            price = prices[mid];
        }

        return (price, prices.length);
    }

    /// @notice Collect valid prices from all enabled oracles
    function _collectPrices() internal view returns (uint256[] memory) {
        uint256[] memory tempPrices = new uint256[](oracles.length);
        uint256 count = 0;

        for (uint256 i = 0; i < oracles.length; i++) {
            if (!oracles[i].enabled) continue;

            try IOracle(oracles[i].oracle).getPrice() returns (uint256 p, uint256 updatedAt) {
                if (block.timestamp - updatedAt <= oracles[i].maxStaleness && p > 0) {
                    tempPrices[count] = p;
                    count++;
                }
            } catch {
                // Oracle failed, skip
            }
        }

        // Copy to correctly sized array
        uint256[] memory prices = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            prices[i] = tempPrices[i];
        }

        return prices;
    }

    /// @notice Sort array in-place (insertion sort for small arrays)
    function _sort(uint256[] memory arr) internal pure {
        for (uint256 i = 1; i < arr.length; i++) {
            uint256 key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
    }

    /// @notice Get number of healthy oracles
    function getHealthyOracleCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < oracles.length; i++) {
            if (!oracles[i].enabled) continue;

            try IOracle(oracles[i].oracle).isHealthy() returns (bool healthy) {
                if (healthy) count++;
            } catch {}
        }
    }

    /// @notice Get total oracle count
    function oracleCount() external view returns (uint256) {
        return oracles.length;
    }

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

/// @title WeightedOracle
/// @notice Aggregates oracles with configurable weights
/// @dev Allows trusted oracles to have more influence
contract WeightedOracle {
    /// @notice Oracle with weight
    struct WeightedOracleConfig {
        address oracle;
        uint256 weight;     // Weight in basis points (10000 = 100%)
        uint256 maxStaleness;
        bool enabled;
    }

    /// @notice Configured oracles
    WeightedOracleConfig[] public oracles;

    /// @notice Total weight of enabled oracles
    uint256 public totalWeight;

    /// @notice Minimum weight required for valid price
    uint256 public immutable minWeight;

    /// @notice Owner
    address public owner;

    /// @notice Errors
    error InsufficientWeight(uint256 available, uint256 required);
    error NotOwner();
    error InvalidConfig();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @param _minWeight Minimum weight needed (in basis points)
    constructor(uint256 _minWeight) {
        minWeight = _minWeight;
        owner = msg.sender;
    }

    /// @notice Add an oracle with weight
    /// @param oracle Oracle address
    /// @param weight Weight in basis points (10000 = 100%)
    /// @param maxStaleness Max age for valid prices
    function addOracle(address oracle, uint256 weight, uint256 maxStaleness) external onlyOwner {
        if (oracle == address(0) || weight == 0) revert InvalidConfig();

        oracles.push(WeightedOracleConfig({
            oracle: oracle,
            weight: weight,
            maxStaleness: maxStaleness,
            enabled: true
        }));

        totalWeight += weight;
    }

    /// @notice Get weighted average price
    /// @return price The weighted average price
    /// @return weightUsed Total weight of oracles that contributed
    function getWeightedPrice() external view returns (uint256 price, uint256 weightUsed) {
        uint256 weightedSum = 0;
        weightUsed = 0;

        for (uint256 i = 0; i < oracles.length; i++) {
            WeightedOracleConfig memory config = oracles[i];
            if (!config.enabled) continue;

            try IOracle(config.oracle).getPrice() returns (uint256 p, uint256 updatedAt) {
                if (block.timestamp - updatedAt <= config.maxStaleness && p > 0) {
                    weightedSum += p * config.weight;
                    weightUsed += config.weight;
                }
            } catch {}
        }

        if (weightUsed < minWeight) {
            revert InsufficientWeight(weightUsed, minWeight);
        }

        price = weightedSum / weightUsed;
    }

    /// @notice Update oracle weight
    /// @param index Oracle index
    /// @param newWeight New weight in basis points
    function updateWeight(uint256 index, uint256 newWeight) external onlyOwner {
        WeightedOracleConfig storage config = oracles[index];

        if (config.enabled) {
            totalWeight = totalWeight - config.weight + newWeight;
        }

        config.weight = newWeight;
    }

    /// @notice Enable/disable oracle
    function setEnabled(uint256 index, bool enabled) external onlyOwner {
        WeightedOracleConfig storage config = oracles[index];

        if (config.enabled != enabled) {
            if (enabled) {
                totalWeight += config.weight;
            } else {
                totalWeight -= config.weight;
            }
            config.enabled = enabled;
        }
    }

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

/// @title PriorityOracle
/// @notice Uses oracles in priority order with automatic fallback
/// @dev First healthy oracle's price is used
contract PriorityOracle {
    /// @notice Oracle in priority list
    struct PriorityOracleConfig {
        address oracle;
        uint256 maxStaleness;
        uint256 priority;  // Lower = higher priority
    }

    /// @notice Oracles sorted by priority
    PriorityOracleConfig[] public oracles;

    /// @notice Owner
    address public owner;

    /// @notice Events
    event PriceFromOracle(address indexed oracle, uint256 price, uint256 priority);
    event AllOraclesFailed();

    /// @notice Errors
    error NoHealthyOracle();
    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Add oracle with priority
    /// @param oracle Oracle address
    /// @param maxStaleness Max staleness
    /// @param priority Priority (lower = checked first)
    function addOracle(address oracle, uint256 maxStaleness, uint256 priority) external onlyOwner {
        oracles.push(PriorityOracleConfig({
            oracle: oracle,
            maxStaleness: maxStaleness,
            priority: priority
        }));

        // Keep sorted by priority
        _sortByPriority();
    }

    /// @notice Sort oracles by priority
    function _sortByPriority() internal {
        for (uint256 i = 1; i < oracles.length; i++) {
            PriorityOracleConfig memory key = oracles[i];
            uint256 j = i;
            while (j > 0 && oracles[j - 1].priority > key.priority) {
                oracles[j] = oracles[j - 1];
                j--;
            }
            oracles[j] = key;
        }
    }

    /// @notice Get price from highest priority healthy oracle
    /// @return price The price
    /// @return oracleUsed Which oracle provided the price
    function getPrice() external view returns (uint256 price, address oracleUsed) {
        for (uint256 i = 0; i < oracles.length; i++) {
            PriorityOracleConfig memory config = oracles[i];

            try IOracle(config.oracle).getPrice() returns (uint256 p, uint256 updatedAt) {
                if (block.timestamp - updatedAt <= config.maxStaleness && p > 0) {
                    return (p, config.oracle);
                }
            } catch {}
        }

        revert NoHealthyOracle();
    }

    /// @notice Get all oracle statuses
    /// @return statuses Array of (oracle, isHealthy, price)
    function getAllStatuses() external view returns (
        address[] memory oracleAddrs,
        bool[] memory healthyStatus,
        uint256[] memory prices
    ) {
        oracleAddrs = new address[](oracles.length);
        healthyStatus = new bool[](oracles.length);
        prices = new uint256[](oracles.length);

        for (uint256 i = 0; i < oracles.length; i++) {
            oracleAddrs[i] = oracles[i].oracle;

            try IOracle(oracles[i].oracle).getPrice() returns (uint256 p, uint256 updatedAt) {
                bool isHealthy = (block.timestamp - updatedAt <= oracles[i].maxStaleness) && p > 0;
                healthyStatus[i] = isHealthy;
                prices[i] = isHealthy ? p : 0;
            } catch {
                healthyStatus[i] = false;
                prices[i] = 0;
            }
        }
    }

    /// @notice Get oracle count
    function oracleCount() external view returns (uint256) {
        return oracles.length;
    }

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

/// @title DeviationCircuitBreaker
/// @notice Rejects prices that deviate too much from a reference
/// @dev Useful for detecting oracle manipulation
contract DeviationCircuitBreaker {
    /// @notice Primary oracle for prices
    IOracle public immutable primaryOracle;

    /// @notice Reference oracle (e.g., TWAP) for deviation check
    IOracle public immutable referenceOracle;

    /// @notice Maximum allowed deviation in basis points (e.g., 500 = 5%)
    uint256 public immutable maxDeviationBps;

    /// @notice Events
    event PriceAccepted(uint256 price, uint256 referencePrice, uint256 deviationBps);
    event PriceRejected(uint256 price, uint256 referencePrice, uint256 deviationBps);

    /// @notice Errors
    error ExcessiveDeviation(uint256 price, uint256 reference, uint256 deviationBps);
    error OracleFailed();

    /// @param _primary Primary oracle (spot price)
    /// @param _reference Reference oracle (e.g., TWAP)
    /// @param _maxDeviationBps Max deviation in basis points
    constructor(
        address _primary,
        address _reference,
        uint256 _maxDeviationBps
    ) {
        primaryOracle = IOracle(_primary);
        referenceOracle = IOracle(_reference);
        maxDeviationBps = _maxDeviationBps;
    }

    /// @notice Get price with deviation check
    /// @return price The validated price
    function getPrice() external view returns (uint256 price) {
        // Get primary price
        (uint256 primaryPrice,) = primaryOracle.getPrice();
        if (primaryPrice == 0) revert OracleFailed();

        // Get reference price
        (uint256 referencePrice,) = referenceOracle.getPrice();
        if (referencePrice == 0) revert OracleFailed();

        // Calculate deviation
        uint256 deviation;
        if (primaryPrice > referencePrice) {
            deviation = ((primaryPrice - referencePrice) * 10000) / referencePrice;
        } else {
            deviation = ((referencePrice - primaryPrice) * 10000) / referencePrice;
        }

        // Check deviation
        if (deviation > maxDeviationBps) {
            revert ExcessiveDeviation(primaryPrice, referencePrice, deviation);
        }

        return primaryPrice;
    }

    /// @notice Check current deviation without reverting
    /// @return price Primary price
    /// @return referencePrice Reference price
    /// @return deviationBps Current deviation in basis points
    /// @return withinBounds Whether deviation is acceptable
    function checkDeviation() external view returns (
        uint256 price,
        uint256 referencePrice,
        uint256 deviationBps,
        bool withinBounds
    ) {
        try primaryOracle.getPrice() returns (uint256 p, uint256) {
            price = p;
        } catch {
            return (0, 0, 0, false);
        }

        try referenceOracle.getPrice() returns (uint256 r, uint256) {
            referencePrice = r;
        } catch {
            return (price, 0, 0, false);
        }

        if (price > referencePrice) {
            deviationBps = ((price - referencePrice) * 10000) / referencePrice;
        } else {
            deviationBps = ((referencePrice - price) * 10000) / referencePrice;
        }

        withinBounds = deviationBps <= maxDeviationBps;
    }
}
