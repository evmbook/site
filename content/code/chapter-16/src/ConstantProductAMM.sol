// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC20Minimal
/// @notice Minimal ERC-20 interface for AMM
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title ConstantProductAMM
/// @notice Minimal Uniswap V2-style constant product AMM
/// @dev Implements x * y = k invariant with 0.3% fee
contract ConstantProductAMM {
    /// @notice The two tokens in the pair
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    /// @notice Reserve balances
    uint256 public reserve0;
    uint256 public reserve1;

    /// @notice Total LP token supply
    uint256 public totalSupply;

    /// @notice LP token balances
    mapping(address => uint256) public balanceOf;

    /// @notice Fee in basis points (30 = 0.3%)
    uint256 public constant FEE_BPS = 30;
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice Minimum liquidity locked forever (prevents division by zero)
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /// @notice Events
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    /// @notice Errors
    error InsufficientLiquidity();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error InvalidK();
    error TransferFailed();

    /// @notice Reentrancy lock
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /// @notice Add liquidity to the pool
    /// @param to Address to receive LP tokens
    /// @return liquidity Amount of LP tokens minted
    function addLiquidity(address to) external lock returns (uint256 liquidity) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            // First deposit: liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // Permanently lock minimum liquidity
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // Subsequent deposits: proportional to existing reserves
            liquidity = _min(
                (amount0 * _totalSupply) / reserve0,
                (amount1 * _totalSupply) / reserve1
            );
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);
        _update(balance0, balance1);

        emit Mint(msg.sender, amount0, amount1, liquidity);
    }

    /// @notice Remove liquidity from the pool
    /// @param to Address to receive underlying tokens
    /// @return amount0 Amount of token0 returned
    /// @return amount1 Amount of token1 returned
    function removeLiquidity(address to) external lock returns (uint256 amount0, uint256 amount1) {
        uint256 liquidity = balanceOf[address(this)];
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 _totalSupply = totalSupply;

        // Calculate proportional amounts
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        if (!token0.transfer(to, amount0)) revert TransferFailed();
        if (!token1.transfer(to, amount1)) revert TransferFailed();

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));

        emit Burn(msg.sender, amount0, amount1, liquidity, to);
    }

    /// @notice Swap tokens
    /// @param amount0Out Amount of token0 to receive
    /// @param amount1Out Amount of token1 to receive
    /// @param to Address to receive output tokens
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external lock {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();
        if (amount0Out >= reserve0 || amount1Out >= reserve1) revert InsufficientLiquidity();

        // Optimistically transfer output
        if (amount0Out > 0 && !token0.transfer(to, amount0Out)) revert TransferFailed();
        if (amount1Out > 0 && !token1.transfer(to, amount1Out)) revert TransferFailed();

        // Get new balances
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        // Calculate input amounts
        uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;

        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        // Verify k invariant (with fee)
        // balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 10000^2
        // where balanceAdjusted = balance * 10000 - amountIn * 30 (0.3% fee)
        {
            uint256 balance0Adjusted = balance0 * BPS_DENOMINATOR - amount0In * FEE_BPS;
            uint256 balance1Adjusted = balance1 * BPS_DENOMINATOR - amount1In * FEE_BPS;

            if (balance0Adjusted * balance1Adjusted < reserve0 * reserve1 * BPS_DENOMINATOR * BPS_DENOMINATOR) {
                revert InvalidK();
            }
        }

        _update(balance0, balance1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @notice Force reserves to match balances
    function sync() external lock {
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /// @notice Force balances to match reserves (recover tokens)
    function skim(address to) external lock {
        if (!token0.transfer(to, token0.balanceOf(address(this)) - reserve0)) revert TransferFailed();
        if (!token1.transfer(to, token1.balanceOf(address(this)) - reserve1)) revert TransferFailed();
    }

    /// @notice Get output amount for a given input
    /// @param amountIn Input amount (with decimals)
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Output amount (with decimals)
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // amountOut = (amountIn * 9970 * reserveOut) / (reserveIn * 10000 + amountIn * 9970)
        uint256 amountInWithFee = amountIn * (BPS_DENOMINATOR - FEE_BPS);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * BPS_DENOMINATOR + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @notice Get input amount for a desired output
    /// @param amountOut Desired output amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountIn Required input amount
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        require(amountOut > 0, "Insufficient output");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        require(amountOut < reserveOut, "Insufficient liquidity");

        // amountIn = (reserveIn * amountOut * 10000) / ((reserveOut - amountOut) * 9970) + 1
        uint256 numerator = reserveIn * amountOut * BPS_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * (BPS_DENOMINATOR - FEE_BPS);
        amountIn = (numerator / denominator) + 1;
    }

    /// @notice Calculate price impact of a trade
    /// @param amountIn Input amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return priceImpactBps Price impact in basis points
    function getPriceImpact(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 priceImpactBps) {
        // Spot price (excluding fee) = reserveOut / reserveIn
        // Execution price = amountOut / amountIn
        // Price impact = (spot - execution) / spot

        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        // spotPrice = reserveOut * 1e18 / reserveIn
        uint256 spotPrice = (reserveOut * 1e18) / reserveIn;

        // executionPrice = amountOut * 1e18 / amountIn
        uint256 executionPrice = (amountOut * 1e18) / amountIn;

        // Account for fee in spot price comparison
        uint256 spotPriceAfterFee = (spotPrice * (BPS_DENOMINATOR - FEE_BPS)) / BPS_DENOMINATOR;

        if (executionPrice >= spotPriceAfterFee) {
            return 0;
        }

        priceImpactBps = ((spotPriceAfterFee - executionPrice) * BPS_DENOMINATOR) / spotPriceAfterFee;
    }

    /// @notice Get current spot price of token0 in terms of token1
    /// @return price Price with 18 decimal precision
    function getSpotPrice() external view returns (uint256 price) {
        if (reserve0 == 0) return 0;
        return (reserve1 * 1e18) / reserve0;
    }

    /// @notice Update reserves
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }

    /// @notice Mint LP tokens
    function _mint(address to, uint256 amount) private {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    /// @notice Burn LP tokens
    function _burn(address from, uint256 amount) private {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }

    /// @notice Babylonian square root
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice Minimum of two values
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice LP token transfer
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// @title AMMRouter
/// @notice Router for interacting with AMM pairs
contract AMMRouter {
    /// @notice Swap exact input for output
    /// @param pair The AMM pair
    /// @param tokenIn Input token
    /// @param amountIn Exact input amount
    /// @param amountOutMin Minimum output (slippage protection)
    /// @param to Recipient
    /// @return amountOut Actual output amount
    function swapExactTokensForTokens(
        ConstantProductAMM pair,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256 amountOut) {
        // Transfer input tokens to pair
        IERC20(tokenIn).transferFrom(msg.sender, address(pair), amountIn);

        // Determine output amounts
        bool isToken0 = address(pair.token0()) == tokenIn;
        uint256 reserve0 = pair.reserve0();
        uint256 reserve1 = pair.reserve1();

        if (isToken0) {
            amountOut = pair.getAmountOut(amountIn, reserve0, reserve1);
            require(amountOut >= amountOutMin, "Slippage");
            pair.swap(0, amountOut, to);
        } else {
            amountOut = pair.getAmountOut(amountIn, reserve1, reserve0);
            require(amountOut >= amountOutMin, "Slippage");
            pair.swap(amountOut, 0, to);
        }
    }

    /// @notice Add liquidity to pair
    /// @param pair The AMM pair
    /// @param amount0Desired Desired amount of token0
    /// @param amount1Desired Desired amount of token1
    /// @param amount0Min Minimum token0 (slippage protection)
    /// @param amount1Min Minimum token1 (slippage protection)
    /// @param to Recipient of LP tokens
    /// @return liquidity LP tokens minted
    function addLiquidity(
        ConstantProductAMM pair,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 liquidity) {
        (uint256 amount0, uint256 amount1) = _calculateOptimalAmounts(
            pair,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min
        );

        IERC20(address(pair.token0())).transferFrom(msg.sender, address(pair), amount0);
        IERC20(address(pair.token1())).transferFrom(msg.sender, address(pair), amount1);

        liquidity = pair.addLiquidity(to);
    }

    /// @notice Calculate optimal amounts for liquidity provision
    function _calculateOptimalAmounts(
        ConstantProductAMM pair,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint256 reserve0 = pair.reserve0();
        uint256 reserve1 = pair.reserve1();

        if (reserve0 == 0 && reserve1 == 0) {
            // First liquidity provision
            return (amount0Desired, amount1Desired);
        }

        // Calculate optimal amount1 for given amount0
        uint256 amount1Optimal = (amount0Desired * reserve1) / reserve0;
        if (amount1Optimal <= amount1Desired) {
            require(amount1Optimal >= amount1Min, "Insufficient amount1");
            return (amount0Desired, amount1Optimal);
        }

        // Calculate optimal amount0 for given amount1
        uint256 amount0Optimal = (amount1Desired * reserve0) / reserve1;
        require(amount0Optimal <= amount0Desired, "Excessive amount0");
        require(amount0Optimal >= amount0Min, "Insufficient amount0");
        return (amount0Optimal, amount1Desired);
    }

    /// @notice Remove liquidity from pair
    function removeLiquidity(
        ConstantProductAMM pair,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external returns (uint256 amount0, uint256 amount1) {
        // Transfer LP tokens to pair
        pair.transfer(address(pair), liquidity);

        // Get amounts back
        (amount0, amount1) = pair.removeLiquidity(to);

        require(amount0 >= amount0Min, "Insufficient amount0");
        require(amount1 >= amount1Min, "Insufficient amount1");
    }
}
