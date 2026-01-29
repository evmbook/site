// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC20
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title SimplePredictionMarket
/// @notice Binary prediction market with automatic market maker
/// @dev Educational implementation demonstrating prediction market mechanics
contract SimplePredictionMarket {
    /// @notice Market data
    struct Market {
        string question;
        uint256 endTime;
        uint256 resolutionTime;
        bool resolved;
        bool outcome;          // true = YES won, false = NO won
        uint256 yesShares;     // Total YES shares
        uint256 noShares;      // Total NO shares
        uint256 liquidity;     // Initial liquidity (for LMSR)
        address resolver;
    }

    /// @notice Collateral token (e.g., USDC)
    IERC20 public immutable collateral;

    /// @notice Markets
    mapping(uint256 => Market) public markets;
    uint256 public nextMarketId;

    /// @notice User share balances: marketId => user => isYes => balance
    mapping(uint256 => mapping(address => mapping(bool => uint256))) public shares;

    /// @notice Platform fee (basis points)
    uint256 public constant FEE_BPS = 100; // 1%
    address public feeRecipient;

    /// @notice LMSR parameter (higher = more liquidity, lower slippage)
    uint256 public constant LMSR_B = 100e18;

    /// @notice Events
    event MarketCreated(uint256 indexed marketId, string question, uint256 endTime, address resolver);
    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isYes, uint256 shares, uint256 cost);
    event SharesSold(uint256 indexed marketId, address indexed seller, bool isYes, uint256 shares, uint256 payout);
    event MarketResolved(uint256 indexed marketId, bool outcome);
    event Redeemed(uint256 indexed marketId, address indexed user, uint256 payout);

    /// @notice Errors
    error MarketEnded();
    error MarketNotEnded();
    error MarketNotResolved();
    error MarketAlreadyResolved();
    error NotResolver();
    error InsufficientShares();
    error InvalidAmount();
    error TooEarlyToResolve();

    constructor(address _collateral, address _feeRecipient) {
        collateral = IERC20(_collateral);
        feeRecipient = _feeRecipient;
    }

    /// @notice Create a new prediction market
    function createMarket(
        string calldata question,
        uint256 duration,
        uint256 resolutionBuffer,
        uint256 initialLiquidity
    ) external returns (uint256 marketId) {
        require(initialLiquidity > 0, "Need initial liquidity");

        collateral.transferFrom(msg.sender, address(this), initialLiquidity);

        marketId = nextMarketId++;

        markets[marketId] = Market({
            question: question,
            endTime: block.timestamp + duration,
            resolutionTime: block.timestamp + duration + resolutionBuffer,
            resolved: false,
            outcome: false,
            yesShares: initialLiquidity,
            noShares: initialLiquidity,
            liquidity: initialLiquidity,
            resolver: msg.sender
        });

        emit MarketCreated(marketId, question, block.timestamp + duration, msg.sender);
    }

    /// @notice Buy outcome shares using LMSR pricing
    function buyShares(uint256 marketId, bool isYes, uint256 amount) external {
        Market storage market = markets[marketId];

        if (block.timestamp >= market.endTime) revert MarketEnded();
        if (amount == 0) revert InvalidAmount();

        uint256 cost = getCost(marketId, isYes, amount);
        uint256 fee = (cost * FEE_BPS) / 10000;
        uint256 totalCost = cost + fee;

        collateral.transferFrom(msg.sender, address(this), totalCost);
        if (fee > 0) {
            collateral.transfer(feeRecipient, fee);
        }

        if (isYes) {
            market.yesShares += amount;
        } else {
            market.noShares += amount;
        }

        shares[marketId][msg.sender][isYes] += amount;

        emit SharesPurchased(marketId, msg.sender, isYes, amount, totalCost);
    }

    /// @notice Sell outcome shares
    function sellShares(uint256 marketId, bool isYes, uint256 amount) external {
        Market storage market = markets[marketId];

        if (block.timestamp >= market.endTime) revert MarketEnded();
        if (shares[marketId][msg.sender][isYes] < amount) revert InsufficientShares();

        uint256 payout = getSellPayout(marketId, isYes, amount);
        uint256 fee = (payout * FEE_BPS) / 10000;
        uint256 netPayout = payout - fee;

        shares[marketId][msg.sender][isYes] -= amount;

        if (isYes) {
            market.yesShares -= amount;
        } else {
            market.noShares -= amount;
        }

        if (fee > 0) {
            collateral.transfer(feeRecipient, fee);
        }
        collateral.transfer(msg.sender, netPayout);

        emit SharesSold(marketId, msg.sender, isYes, amount, netPayout);
    }

    /// @notice Resolve the market outcome
    function resolve(uint256 marketId, bool outcome) external {
        Market storage market = markets[marketId];

        if (msg.sender != market.resolver) revert NotResolver();
        if (market.resolved) revert MarketAlreadyResolved();
        if (block.timestamp < market.endTime) revert MarketNotEnded();

        market.resolved = true;
        market.outcome = outcome;

        emit MarketResolved(marketId, outcome);
    }

    /// @notice Redeem winning shares for collateral
    function redeem(uint256 marketId) external {
        Market storage market = markets[marketId];

        if (!market.resolved) revert MarketNotResolved();

        uint256 winningShares = shares[marketId][msg.sender][market.outcome];
        if (winningShares == 0) return;

        shares[marketId][msg.sender][market.outcome] = 0;

        // Each winning share is worth 1 unit of collateral
        collateral.transfer(msg.sender, winningShares);

        emit Redeemed(marketId, msg.sender, winningShares);
    }

    /// @notice Get cost to buy shares using LMSR
    /// @dev Cost = b * ln((e^(q_yes/b) + e^(q_no/b))) - current_cost
    function getCost(uint256 marketId, bool isYes, uint256 amount) public view returns (uint256) {
        Market storage market = markets[marketId];

        uint256 currentCost = _lmsrCost(market.yesShares, market.noShares);

        uint256 newYes = isYes ? market.yesShares + amount : market.yesShares;
        uint256 newNo = isYes ? market.noShares : market.noShares + amount;

        uint256 newCost = _lmsrCost(newYes, newNo);

        return newCost > currentCost ? newCost - currentCost : 0;
    }

    /// @notice Get payout for selling shares
    function getSellPayout(uint256 marketId, bool isYes, uint256 amount) public view returns (uint256) {
        Market storage market = markets[marketId];

        uint256 currentCost = _lmsrCost(market.yesShares, market.noShares);

        uint256 newYes = isYes ? market.yesShares - amount : market.yesShares;
        uint256 newNo = isYes ? market.noShares : market.noShares - amount;

        uint256 newCost = _lmsrCost(newYes, newNo);

        return currentCost > newCost ? currentCost - newCost : 0;
    }

    /// @notice Get current price (probability) of YES outcome
    /// @return price Price in basis points (e.g., 5000 = 50%)
    function getYesPrice(uint256 marketId) public view returns (uint256 price) {
        Market storage market = markets[marketId];

        // Price = e^(q_yes/b) / (e^(q_yes/b) + e^(q_no/b))
        // Simplified: approximate with share ratios for educational purposes
        uint256 total = market.yesShares + market.noShares;
        if (total == 0) return 5000;

        return (market.noShares * 10000) / total;
    }

    /// @notice Get current price of NO outcome
    function getNoPrice(uint256 marketId) public view returns (uint256) {
        return 10000 - getYesPrice(marketId);
    }

    /// @notice LMSR cost function (simplified approximation)
    function _lmsrCost(uint256 yesShares, uint256 noShares) internal pure returns (uint256) {
        // Full LMSR: b * ln(e^(q1/b) + e^(q2/b))
        // Simplified approximation for educational purposes:
        // Use max(q1, q2) + b * ln(1 + e^(-|q1-q2|/b))
        // Further simplified: max(q1, q2) + adjustment factor

        uint256 maxShares = yesShares > noShares ? yesShares : noShares;
        uint256 minShares = yesShares > noShares ? noShares : yesShares;

        // Adjustment decreases as difference increases
        uint256 diff = maxShares - minShares;
        uint256 adjustment = (LMSR_B * minShares) / (LMSR_B + diff);

        return maxShares + adjustment;
    }

    /// @notice Get user's share balances
    function getUserShares(uint256 marketId, address user) external view returns (
        uint256 yesBalance,
        uint256 noBalance
    ) {
        yesBalance = shares[marketId][user][true];
        noBalance = shares[marketId][user][false];
    }

    /// @notice Get market info
    function getMarketInfo(uint256 marketId) external view returns (
        string memory question,
        uint256 endTime,
        bool resolved,
        bool outcome,
        uint256 yesShares,
        uint256 noShares,
        uint256 yesPrice,
        uint256 noPrice
    ) {
        Market storage m = markets[marketId];
        return (
            m.question,
            m.endTime,
            m.resolved,
            m.outcome,
            m.yesShares,
            m.noShares,
            getYesPrice(marketId),
            getNoPrice(marketId)
        );
    }
}

/// @title ConditionalTokens
/// @notice Simplified conditional tokens for prediction markets
/// @dev Based on Gnosis Conditional Tokens concept
contract ConditionalTokens {
    /// @notice Condition data
    struct Condition {
        address oracle;
        bytes32 questionId;
        uint256 outcomeSlots;
        uint256[] payoutNumerators;
        uint256 payoutDenominator;
        bool resolved;
    }

    /// @notice Collateral token
    IERC20 public immutable collateral;

    /// @notice Conditions
    mapping(bytes32 => Condition) public conditions;

    /// @notice Position balances: conditionId => outcomeIndex => user => balance
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256))) public balances;

    event ConditionPreparation(bytes32 indexed conditionId, address indexed oracle, bytes32 questionId, uint256 outcomeSlots);
    event ConditionResolution(bytes32 indexed conditionId, uint256[] payoutNumerators);
    event PositionSplit(address indexed stakeholder, bytes32 indexed conditionId, uint256 amount);
    event PositionsMerge(address indexed stakeholder, bytes32 indexed conditionId, uint256 amount);
    event PayoutRedemption(address indexed redeemer, bytes32 indexed conditionId, uint256[] amounts);

    error ConditionNotResolved();
    error ConditionAlreadyResolved();
    error NotOracle();
    error InvalidOutcomes();

    constructor(address _collateral) {
        collateral = IERC20(_collateral);
    }

    /// @notice Prepare a new condition
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlots) external {
        require(outcomeSlots >= 2 && outcomeSlots <= 256, "Invalid outcome count");

        bytes32 conditionId = getConditionId(oracle, questionId, outcomeSlots);
        require(conditions[conditionId].outcomeSlots == 0, "Condition exists");

        conditions[conditionId] = Condition({
            oracle: oracle,
            questionId: questionId,
            outcomeSlots: outcomeSlots,
            payoutNumerators: new uint256[](outcomeSlots),
            payoutDenominator: 0,
            resolved: false
        });

        emit ConditionPreparation(conditionId, oracle, questionId, outcomeSlots);
    }

    /// @notice Report outcome payouts
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external {
        bytes32 conditionId = getConditionId(msg.sender, questionId, payouts.length);
        Condition storage condition = conditions[conditionId];

        if (condition.outcomeSlots == 0) revert InvalidOutcomes();
        if (condition.resolved) revert ConditionAlreadyResolved();

        uint256 den = 0;
        for (uint256 i = 0; i < payouts.length; i++) {
            den += payouts[i];
            condition.payoutNumerators[i] = payouts[i];
        }
        require(den > 0, "Invalid payouts");

        condition.payoutDenominator = den;
        condition.resolved = true;

        emit ConditionResolution(conditionId, payouts);
    }

    /// @notice Split collateral into outcome tokens
    function splitPosition(bytes32 conditionId, uint256 amount) external {
        Condition storage condition = conditions[conditionId];
        require(condition.outcomeSlots > 0, "Invalid condition");

        collateral.transferFrom(msg.sender, address(this), amount);

        for (uint256 i = 0; i < condition.outcomeSlots; i++) {
            balances[conditionId][i][msg.sender] += amount;
        }

        emit PositionSplit(msg.sender, conditionId, amount);
    }

    /// @notice Merge outcome tokens back to collateral
    function mergePositions(bytes32 conditionId, uint256 amount) external {
        Condition storage condition = conditions[conditionId];

        for (uint256 i = 0; i < condition.outcomeSlots; i++) {
            require(balances[conditionId][i][msg.sender] >= amount, "Insufficient balance");
            balances[conditionId][i][msg.sender] -= amount;
        }

        collateral.transfer(msg.sender, amount);

        emit PositionsMerge(msg.sender, conditionId, amount);
    }

    /// @notice Redeem positions after resolution
    function redeemPositions(bytes32 conditionId) external {
        Condition storage condition = conditions[conditionId];
        if (!condition.resolved) revert ConditionNotResolved();

        uint256 totalPayout = 0;
        uint256[] memory amounts = new uint256[](condition.outcomeSlots);

        for (uint256 i = 0; i < condition.outcomeSlots; i++) {
            uint256 balance = balances[conditionId][i][msg.sender];
            if (balance > 0) {
                amounts[i] = balance;
                uint256 payout = (balance * condition.payoutNumerators[i]) / condition.payoutDenominator;
                totalPayout += payout;
                balances[conditionId][i][msg.sender] = 0;
            }
        }

        if (totalPayout > 0) {
            collateral.transfer(msg.sender, totalPayout);
        }

        emit PayoutRedemption(msg.sender, conditionId, amounts);
    }

    /// @notice Get condition ID
    function getConditionId(address oracle, bytes32 questionId, uint256 outcomeSlots) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(oracle, questionId, outcomeSlots));
    }

    /// @notice Get user balance for an outcome
    function balanceOf(bytes32 conditionId, uint256 outcomeIndex, address account) external view returns (uint256) {
        return balances[conditionId][outcomeIndex][account];
    }
}
