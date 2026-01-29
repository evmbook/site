// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Flash Loan Arbitrage Example
/// @notice Demonstrates arbitrage between two DEXes using flash loans
/// @dev Educational example - real arbitrage requires more sophisticated logic

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IFlashLoanProvider {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
}

/// @title FlashLoanArbitrage
/// @notice Simple arbitrage contract: borrow USDC, buy ETH cheap, sell ETH expensive
contract FlashLoanArbitrage {
    // ============ Constants ============

    address public immutable owner;
    address public immutable WETH;
    address public immutable USDC;
    IFlashLoanProvider public immutable flashLoanProvider;

    // ============ Errors ============

    error NotOwner();
    error NotFlashLoanProvider();
    error ArbitrageNotProfitable();
    error InsufficientProfit();

    // ============ Events ============

    event ArbitrageExecuted(
        uint256 flashLoanAmount,
        uint256 profit,
        address dexBuy,
        address dexSell
    );

    // ============ Constructor ============

    constructor(
        address _flashLoanProvider,
        address _weth,
        address _usdc
    ) {
        owner = msg.sender;
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
        WETH = _weth;
        USDC = _usdc;
    }

    // ============ Modifiers ============

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ============ External Functions ============

    /// @notice Execute arbitrage between two DEXes
    /// @param dexBuy DEX router where ETH is cheaper (buy here)
    /// @param dexSell DEX router where ETH is more expensive (sell here)
    /// @param usdcAmount Amount of USDC to flash loan
    /// @param minProfit Minimum profit required (reverts if not met)
    function executeArbitrage(
        address dexBuy,
        address dexSell,
        uint256 usdcAmount,
        uint256 minProfit
    ) external onlyOwner {
        // Encode the arbitrage parameters for the callback
        bytes memory data = abi.encode(dexBuy, dexSell, minProfit);

        // Initiate flash loan - this will call onFlashLoan
        flashLoanProvider.flashLoan(
            address(this),
            USDC,
            usdcAmount,
            data
        );
    }

    /// @notice Flash loan callback - executes the arbitrage
    /// @dev Called by flash loan provider after transferring tokens
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool) {
        if (msg.sender != address(flashLoanProvider)) revert NotFlashLoanProvider();

        // Decode arbitrage parameters
        (address dexBuy, address dexSell, uint256 minProfit) =
            abi.decode(data, (address, address, uint256));

        // Execute the arbitrage
        uint256 profit = _executeArbitrage(dexBuy, dexSell, amount, fee);

        if (profit < minProfit) revert InsufficientProfit();

        // Approve repayment (amount + fee)
        IERC20(USDC).approve(msg.sender, amount + fee);

        emit ArbitrageExecuted(amount, profit, dexBuy, dexSell);

        return true;
    }

    /// @notice Withdraw profits to owner
    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }

    /// @notice Check if arbitrage is profitable
    /// @return profitable Whether the arbitrage would be profitable
    /// @return expectedProfit Expected profit in USDC
    function checkArbitrage(
        address dexBuy,
        address dexSell,
        uint256 usdcAmount,
        uint256 flashLoanFee
    ) external view returns (bool profitable, uint256 expectedProfit) {
        // Build swap paths
        address[] memory pathBuy = new address[](2);
        pathBuy[0] = USDC;
        pathBuy[1] = WETH;

        address[] memory pathSell = new address[](2);
        pathSell[0] = WETH;
        pathSell[1] = USDC;

        // Get expected ETH from buying on dexBuy
        uint256[] memory amountsBuy = IUniswapV2Router(dexBuy).getAmountsOut(
            usdcAmount,
            pathBuy
        );
        uint256 ethReceived = amountsBuy[1];

        // Get expected USDC from selling on dexSell
        uint256[] memory amountsSell = IUniswapV2Router(dexSell).getAmountsOut(
            ethReceived,
            pathSell
        );
        uint256 usdcReceived = amountsSell[1];

        // Calculate profit (must cover flash loan repayment)
        uint256 totalRepayment = usdcAmount + flashLoanFee;

        if (usdcReceived > totalRepayment) {
            profitable = true;
            expectedProfit = usdcReceived - totalRepayment;
        } else {
            profitable = false;
            expectedProfit = 0;
        }
    }

    // ============ Internal Functions ============

    /// @dev Core arbitrage logic
    function _executeArbitrage(
        address dexBuy,
        address dexSell,
        uint256 usdcAmount,
        uint256 flashLoanFee
    ) internal returns (uint256 profit) {
        // Step 1: Buy WETH on the cheaper DEX
        address[] memory pathBuy = new address[](2);
        pathBuy[0] = USDC;
        pathBuy[1] = WETH;

        IERC20(USDC).approve(dexBuy, usdcAmount);

        uint256[] memory amountsBuy = IUniswapV2Router(dexBuy).swapExactTokensForTokens(
            usdcAmount,
            0, // Accept any amount (MEV protection should be handled externally)
            pathBuy,
            address(this),
            block.timestamp
        );
        uint256 wethReceived = amountsBuy[1];

        // Step 2: Sell WETH on the more expensive DEX
        address[] memory pathSell = new address[](2);
        pathSell[0] = WETH;
        pathSell[1] = USDC;

        IERC20(WETH).approve(dexSell, wethReceived);

        uint256[] memory amountsSell = IUniswapV2Router(dexSell).swapExactTokensForTokens(
            wethReceived,
            0,
            pathSell,
            address(this),
            block.timestamp
        );
        uint256 usdcReceived = amountsSell[1];

        // Step 3: Calculate profit
        uint256 totalRepayment = usdcAmount + flashLoanFee;

        if (usdcReceived <= totalRepayment) revert ArbitrageNotProfitable();

        profit = usdcReceived - totalRepayment;
    }
}

/// @title MultiHopArbitrage
/// @notice More advanced arbitrage with multi-hop swaps
contract MultiHopArbitrage {
    address public immutable owner;
    IFlashLoanProvider public immutable flashLoanProvider;

    error NotOwner();
    error NotFlashLoanProvider();
    error ArbitrageNotProfitable();

    event ArbitrageExecuted(address tokenBorrowed, uint256 amount, uint256 profit);

    constructor(address _flashLoanProvider) {
        owner = msg.sender;
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Execute multi-hop arbitrage
    /// @param token Token to flash loan
    /// @param amount Amount to borrow
    /// @param swaps Array of swap instructions
    function executeMultiHop(
        address token,
        uint256 amount,
        SwapInstruction[] calldata swaps
    ) external onlyOwner {
        bytes memory data = abi.encode(swaps);
        flashLoanProvider.flashLoan(address(this), token, amount, data);
    }

    struct SwapInstruction {
        address router;
        address tokenIn;
        address tokenOut;
        uint256 amountIn; // 0 means use full balance
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool) {
        if (msg.sender != address(flashLoanProvider)) revert NotFlashLoanProvider();

        // Decode and execute swaps
        SwapInstruction[] memory swaps = abi.decode(data, (SwapInstruction[]));

        for (uint256 i = 0; i < swaps.length; i++) {
            _executeSwap(swaps[i]);
        }

        // Check profitability
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 repayment = amount + fee;

        if (balance < repayment) revert ArbitrageNotProfitable();

        // Approve repayment
        IERC20(token).approve(msg.sender, repayment);

        emit ArbitrageExecuted(token, amount, balance - repayment);

        return true;
    }

    function _executeSwap(SwapInstruction memory swap) internal {
        uint256 amountIn = swap.amountIn;
        if (amountIn == 0) {
            amountIn = IERC20(swap.tokenIn).balanceOf(address(this));
        }

        address[] memory path = new address[](2);
        path[0] = swap.tokenIn;
        path[1] = swap.tokenOut;

        IERC20(swap.tokenIn).approve(swap.router, amountIn);

        IUniswapV2Router(swap.router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
}

/// @title TriangularArbitrage
/// @notice Arbitrage across three tokens: A -> B -> C -> A
/// @dev Example: USDC -> ETH -> BTC -> USDC
contract TriangularArbitrage {
    address public immutable owner;
    IFlashLoanProvider public immutable flashLoanProvider;

    error NotOwner();
    error NotFlashLoanProvider();
    error ArbitrageNotProfitable();

    event TriangularArbitrageExecuted(
        address tokenA,
        address tokenB,
        address tokenC,
        uint256 profit
    );

    constructor(address _flashLoanProvider) {
        owner = msg.sender;
        flashLoanProvider = IFlashLoanProvider(_flashLoanProvider);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    struct TriangularParams {
        address router1;    // A -> B
        address router2;    // B -> C
        address router3;    // C -> A
        address tokenA;
        address tokenB;
        address tokenC;
    }

    /// @notice Execute triangular arbitrage
    /// @param amount Amount of tokenA to flash loan
    /// @param params Triangular arbitrage parameters
    function executeTriangular(
        uint256 amount,
        TriangularParams calldata params
    ) external onlyOwner {
        bytes memory data = abi.encode(params);
        flashLoanProvider.flashLoan(
            address(this),
            params.tokenA,
            amount,
            data
        );
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool) {
        if (msg.sender != address(flashLoanProvider)) revert NotFlashLoanProvider();

        TriangularParams memory params = abi.decode(data, (TriangularParams));

        // Swap A -> B
        uint256 amountB = _swap(
            params.router1,
            params.tokenA,
            params.tokenB,
            amount
        );

        // Swap B -> C
        uint256 amountC = _swap(
            params.router2,
            params.tokenB,
            params.tokenC,
            amountB
        );

        // Swap C -> A
        uint256 finalAmountA = _swap(
            params.router3,
            params.tokenC,
            params.tokenA,
            amountC
        );

        // Check profitability
        uint256 repayment = amount + fee;
        if (finalAmountA < repayment) revert ArbitrageNotProfitable();

        // Approve repayment
        IERC20(token).approve(msg.sender, repayment);

        emit TriangularArbitrageExecuted(
            params.tokenA,
            params.tokenB,
            params.tokenC,
            finalAmountA - repayment
        );

        return true;
    }

    function _swap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IERC20(tokenIn).approve(router, amountIn);

        uint256[] memory amounts = IUniswapV2Router(router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        amountOut = amounts[1];
    }

    /// @notice Check triangular arbitrage profitability
    function checkTriangular(
        uint256 amount,
        TriangularParams calldata params,
        uint256 flashLoanFee
    ) external view returns (bool profitable, uint256 expectedProfit) {
        // A -> B
        uint256 amountB = _getAmountOut(params.router1, params.tokenA, params.tokenB, amount);
        // B -> C
        uint256 amountC = _getAmountOut(params.router2, params.tokenB, params.tokenC, amountB);
        // C -> A
        uint256 finalA = _getAmountOut(params.router3, params.tokenC, params.tokenA, amountC);

        uint256 repayment = amount + flashLoanFee;
        if (finalA > repayment) {
            profitable = true;
            expectedProfit = finalA - repayment;
        }
    }

    function _getAmountOut(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = IUniswapV2Router(router).getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
}
