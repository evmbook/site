// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title FlashLoanSecurity - Flash loan attack vectors and protections
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates oracle manipulation and price feed attacks
/// @dev Chapter 10: Smart Contract Security - Flash Loan Attacks

// ============ INTERFACES ============

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// ============ VULNERABLE: SPOT PRICE ORACLE ============

/// @notice VULNERABLE: Uses spot price that can be manipulated
/// @dev Flash loan can manipulate Uniswap reserves within a single tx
contract VulnerableLending {
    IERC20 public collateralToken;
    IERC20 public borrowToken;
    IUniswapV2Pair public priceOracle; // Uniswap pair used as oracle

    mapping(address => uint256) public collateralDeposits;
    mapping(address => uint256) public borrowedAmounts;

    uint256 public constant COLLATERAL_FACTOR = 80; // 80% LTV

    constructor(address _collateral, address _borrow, address _pair) {
        collateralToken = IERC20(_collateral);
        borrowToken = IERC20(_borrow);
        priceOracle = IUniswapV2Pair(_pair);
    }

    /// @notice VULNERABLE: Get price from spot reserves
    /// @dev Attacker can manipulate this with a flash loan
    function getPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = priceOracle.getReserves();

        // Simple price calculation (collateral/borrow)
        // This is the SPOT price - easily manipulated!
        if (priceOracle.token0() == address(collateralToken)) {
            return (uint256(reserve1) * 1e18) / uint256(reserve0);
        } else {
            return (uint256(reserve0) * 1e18) / uint256(reserve1);
        }
    }

    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralDeposits[msg.sender] += amount;
    }

    /// @notice VULNERABLE: Borrow using manipulated price
    function borrow(uint256 amount) external {
        uint256 collateralValue = (collateralDeposits[msg.sender] * getPrice()) / 1e18;
        uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;

        require(borrowedAmounts[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        borrowedAmounts[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);
    }
}

/// @notice Attack contract that exploits spot price oracle
contract OracleManipulationAttack {
    // Steps:
    // 1. Flash loan large amount of borrowToken
    // 2. Sell borrowToken for collateralToken on Uniswap (manipulates reserves)
    // 3. Now getPrice() returns inflated collateral price
    // 4. Deposit small collateral, borrow max borrowToken
    // 5. Repay flash loan, profit from difference
    // All in one transaction!
}

// ============ SECURE: TWAP ORACLE ============

/// @notice Secure lending using TWAP price
/// @dev Time-weighted prices resist single-tx manipulation
contract SecureLendingTWAP {
    IERC20 public collateralToken;
    IERC20 public borrowToken;

    // TWAP oracle state
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    uint256 public priceAverage;

    uint256 public constant TWAP_PERIOD = 30 minutes;
    uint256 public constant COLLATERAL_FACTOR = 80;

    mapping(address => uint256) public collateralDeposits;
    mapping(address => uint256) public borrowedAmounts;

    error StalePrice();
    error PriceUpdateTooSoon();

    /// @notice Update TWAP price - must wait TWAP_PERIOD between updates
    function updatePrice(IUniswapV2Pair pair) external {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = pair.getReserves();

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed < TWAP_PERIOD) revert PriceUpdateTooSoon();

        // Calculate cumulative price
        // This accumulates over time, making manipulation expensive
        uint256 price0Cumulative = pair.token0() == address(collateralToken)
            ? (uint256(reserve1) * 2 ** 112) / reserve0
            : (uint256(reserve0) * 2 ** 112) / reserve1;

        // Calculate time-weighted average
        priceAverage = (price0Cumulative - price0CumulativeLast) / timeElapsed;

        price0CumulativeLast = price0Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    /// @notice Get TWAP price (resistant to manipulation)
    function getPrice() public view returns (uint256) {
        // Check price isn't stale
        if (block.timestamp - blockTimestampLast > 2 * TWAP_PERIOD) {
            revert StalePrice();
        }
        return priceAverage;
    }

    function borrow(uint256 amount) external {
        uint256 collateralValue = (collateralDeposits[msg.sender] * getPrice()) / 2 ** 112;
        uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;

        require(borrowedAmounts[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        borrowedAmounts[msg.sender] += amount;
        // ... transfer logic
    }
}

// ============ SECURE: CHAINLINK ORACLE ============

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

/// @notice Secure lending using Chainlink oracle
/// @dev Chainlink aggregates multiple sources, resistant to manipulation
contract SecureLendingChainlink {
    AggregatorV3Interface public immutable priceFeed;
    IERC20 public collateralToken;
    IERC20 public borrowToken;

    uint256 public constant STALENESS_THRESHOLD = 1 hours;
    uint256 public constant COLLATERAL_FACTOR = 80;

    mapping(address => uint256) public collateralDeposits;
    mapping(address => uint256) public borrowedAmounts;

    error StalePrice();
    error InvalidPrice();
    error RoundNotComplete();

    constructor(address _priceFeed, address _collateral, address _borrow) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        collateralToken = IERC20(_collateral);
        borrowToken = IERC20(_borrow);
    }

    /// @notice Get price from Chainlink with validation
    function getPrice() public view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
        = priceFeed.latestRoundData();

        // Validate the price feed response
        if (answer <= 0) revert InvalidPrice();
        if (updatedAt == 0) revert InvalidPrice();
        if (answeredInRound < roundId) revert RoundNotComplete();
        if (block.timestamp - updatedAt > STALENESS_THRESHOLD) revert StalePrice();

        // Normalize to 18 decimals
        uint8 decimals = priceFeed.decimals();
        if (decimals < 18) {
            return uint256(answer) * 10 ** (18 - decimals);
        } else {
            return uint256(answer) / 10 ** (decimals - 18);
        }
    }

    function deposit(uint256 amount) external {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateralDeposits[msg.sender] += amount;
    }

    function borrow(uint256 amount) external {
        uint256 collateralValue = (collateralDeposits[msg.sender] * getPrice()) / 1e18;
        uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;

        require(borrowedAmounts[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

        borrowedAmounts[msg.sender] += amount;
        borrowToken.transfer(msg.sender, amount);
    }
}

// ============ FLASH LOAN PROVIDER EXAMPLE ============

/// @notice Simple flash loan provider
contract FlashLoanProvider {
    IERC20 public token;
    uint256 public constant FEE_BPS = 9; // 0.09% fee

    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);

    error RepaymentFailed();

    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Execute a flash loan
    function flashLoan(uint256 amount, address borrower, bytes calldata data) external {
        uint256 balanceBefore = token.balanceOf(address(this));

        // Transfer tokens to borrower
        token.transfer(borrower, amount);

        // Borrower executes their logic
        IFlashLoanReceiver(borrower).executeOperation(amount, data);

        // Calculate fee
        uint256 fee = (amount * FEE_BPS) / 10000;

        // Verify repayment
        uint256 balanceAfter = token.balanceOf(address(this));
        if (balanceAfter < balanceBefore + fee) {
            revert RepaymentFailed();
        }

        emit FlashLoan(borrower, amount, fee);
    }
}

interface IFlashLoanReceiver {
    function executeOperation(uint256 amount, bytes calldata data) external;
}

// ============ DEFENSIVE PATTERNS ============

/// @notice Contract with flash loan protections
contract FlashLoanResistant {
    mapping(address => uint256) public lastActionBlock;

    error SameBlockAction();

    /// @notice Prevent same-block interactions (breaks atomic attacks)
    modifier noSameBlockAction() {
        if (lastActionBlock[msg.sender] == block.number) {
            revert SameBlockAction();
        }
        lastActionBlock[msg.sender] = block.number;
        _;
    }

    // Actions that could be exploited are protected
    function sensitiveAction() external noSameBlockAction {
        // This cannot be called in same block as previous action
        // Breaks atomic flash loan attacks
    }
}

/// @notice Using multiple price sources
contract MultiOracleProtection {
    AggregatorV3Interface public chainlinkFeed;
    IUniswapV2Pair public uniswapPair;

    uint256 public constant MAX_DEVIATION = 500; // 5% max deviation

    error PriceDeviation();

    /// @notice Get price only if sources agree within tolerance
    function getValidatedPrice() public view returns (uint256) {
        uint256 chainlinkPrice = getChainlinkPrice();
        uint256 uniswapPrice = getUniswapTWAP();

        // Calculate deviation
        uint256 deviation;
        if (chainlinkPrice > uniswapPrice) {
            deviation = ((chainlinkPrice - uniswapPrice) * 10000) / chainlinkPrice;
        } else {
            deviation = ((uniswapPrice - chainlinkPrice) * 10000) / uniswapPrice;
        }

        // Revert if prices deviate too much (possible manipulation)
        if (deviation > MAX_DEVIATION) {
            revert PriceDeviation();
        }

        // Return average of both sources
        return (chainlinkPrice + uniswapPrice) / 2;
    }

    function getChainlinkPrice() internal view returns (uint256) {
        (, int256 answer,,,) = chainlinkFeed.latestRoundData();
        return uint256(answer);
    }

    function getUniswapTWAP() internal view returns (uint256) {
        // Implementation would use stored TWAP values
        return 0;
    }
}
