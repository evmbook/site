// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/FlashLoanArbitrage.sol";

/// @title MockERC20
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// @title MockFlashLoanProvider
contract MockFlashLoanProvider is IFlashLoanProvider {
    uint256 public constant FEE_BPS = 9; // 0.09% fee

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override {
        uint256 fee = (amount * FEE_BPS) / 10000;

        // Transfer tokens to receiver
        IERC20(token).transfer(receiver, amount);

        // Call receiver callback
        (bool success,) = receiver.call(
            abi.encodeWithSignature(
                "onFlashLoan(address,address,uint256,uint256,bytes)",
                msg.sender,
                token,
                amount,
                fee,
                data
            )
        );
        require(success, "Flash loan callback failed");

        // Verify repayment
        IERC20(token).transferFrom(receiver, address(this), amount + fee);
    }

    function getFee(uint256 amount) external pure returns (uint256) {
        return (amount * FEE_BPS) / 10000;
    }
}

/// @title MockDEX - Simulates a Uniswap V2-style DEX
contract MockDEX is IUniswapV2Router {
    // Price in basis points (10000 = 1:1)
    // For USDC->WETH: higher = more WETH per USDC (WETH is cheaper)
    // For WETH->USDC: higher = more USDC per WETH (WETH is more expensive)
    mapping(address => mapping(address => uint256)) public prices;

    function setPrice(address tokenIn, address tokenOut, uint256 price) external {
        prices[tokenIn][tokenOut] = price;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 /* deadline */
    ) external override returns (uint256[] memory amounts) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        uint256 price = prices[tokenIn][tokenOut];
        require(price > 0, "Price not set");

        uint256 amountOut = (amountIn * price) / 10000;
        require(amountOut >= amountOutMin, "Slippage");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        uint256 price = prices[tokenIn][tokenOut];

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = (amountIn * price) / 10000;
    }
}

contract FlashLoanArbitrageTest is Test {
    FlashLoanArbitrage public arbitrage;
    MockFlashLoanProvider public flashLoan;
    MockDEX public dexCheap;  // ETH is cheaper here
    MockDEX public dexExpensive;  // ETH is more expensive here
    MockERC20 public weth;
    MockERC20 public usdc;

    address public trader;

    function setUp() public {
        trader = makeAddr("trader");

        // Deploy tokens
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy flash loan provider
        flashLoan = new MockFlashLoanProvider();

        // Deploy DEXes with different prices
        dexCheap = new MockDEX();
        dexExpensive = new MockDEX();

        // Setup prices:
        // DEX Cheap: 1 USDC = 0.0005 WETH (ETH at $2000)
        // DEX Expensive: 1 WETH = 2100 USDC (ETH at $2100)
        // This creates a 5% arbitrage opportunity

        // Cheap DEX: USDC->WETH gives more WETH (cheaper ETH)
        dexCheap.setPrice(address(usdc), address(weth), 5);  // 0.0005 WETH per USDC (1 USDC = 0.0005 ETH)
        dexCheap.setPrice(address(weth), address(usdc), 20000_00); // Not used in arb

        // Expensive DEX: WETH->USDC gives more USDC (ETH worth more)
        dexExpensive.setPrice(address(weth), address(usdc), 21000_00); // 2100 USDC per WETH
        dexExpensive.setPrice(address(usdc), address(weth), 4);  // Not used in arb

        // Deploy arbitrage contract
        vm.prank(trader);
        arbitrage = new FlashLoanArbitrage(
            address(flashLoan),
            address(weth),
            address(usdc)
        );

        // Fund the flash loan provider with USDC
        usdc.mint(address(flashLoan), 10_000_000e6);

        // Fund the DEXes
        weth.mint(address(dexCheap), 10_000e18);
        usdc.mint(address(dexExpensive), 100_000_000e6);
    }

    function test_ExecuteArbitrage() public {
        uint256 flashLoanAmount = 100_000e6; // 100k USDC

        // Execute arbitrage
        vm.prank(trader);
        arbitrage.executeArbitrage(
            address(dexCheap),
            address(dexExpensive),
            flashLoanAmount,
            0 // Min profit
        );

        // Check profit
        uint256 profit = usdc.balanceOf(address(arbitrage));
        assertGt(profit, 0, "Should have profit");

        // Withdraw profits
        vm.prank(trader);
        arbitrage.withdrawProfits(address(usdc));

        assertEq(usdc.balanceOf(trader), profit, "Trader should receive profit");
    }

    function test_CheckArbitrage() public view {
        uint256 flashLoanAmount = 100_000e6;
        uint256 fee = flashLoan.getFee(flashLoanAmount);

        (bool profitable, uint256 expectedProfit) = arbitrage.checkArbitrage(
            address(dexCheap),
            address(dexExpensive),
            flashLoanAmount,
            fee
        );

        assertTrue(profitable, "Should be profitable");
        assertGt(expectedProfit, 0, "Should have expected profit");
    }

    function test_RevertOnUnprofitableArbitrage() public {
        // Make arbitrage unprofitable by setting equal prices
        dexCheap.setPrice(address(usdc), address(weth), 5);
        dexExpensive.setPrice(address(weth), address(usdc), 19000_00); // Lower than buy price after fees

        vm.prank(trader);
        vm.expectRevert(FlashLoanArbitrage.ArbitrageNotProfitable.selector);
        arbitrage.executeArbitrage(
            address(dexCheap),
            address(dexExpensive),
            100_000e6,
            0
        );
    }

    function test_RevertOnInsufficientProfit() public {
        uint256 flashLoanAmount = 100_000e6;

        // Require more profit than possible
        vm.prank(trader);
        vm.expectRevert(FlashLoanArbitrage.InsufficientProfit.selector);
        arbitrage.executeArbitrage(
            address(dexCheap),
            address(dexExpensive),
            flashLoanAmount,
            1_000_000e6 // Require 1M USDC profit (impossible)
        );
    }

    function test_OnlyOwnerCanExecute() public {
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(FlashLoanArbitrage.NotOwner.selector);
        arbitrage.executeArbitrage(
            address(dexCheap),
            address(dexExpensive),
            100_000e6,
            0
        );
    }

    function test_OnlyOwnerCanWithdraw() public {
        // First execute profitable arbitrage
        vm.prank(trader);
        arbitrage.executeArbitrage(
            address(dexCheap),
            address(dexExpensive),
            100_000e6,
            0
        );

        // Try to withdraw as attacker
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert(FlashLoanArbitrage.NotOwner.selector);
        arbitrage.withdrawProfits(address(usdc));
    }
}

contract TriangularArbitrageTest is Test {
    TriangularArbitrage public arbitrage;
    MockFlashLoanProvider public flashLoan;
    MockDEX public dex1;
    MockDEX public dex2;
    MockDEX public dex3;
    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public wbtc;

    address public trader;

    function setUp() public {
        trader = makeAddr("trader");

        // Deploy tokens
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8);

        // Deploy flash loan provider
        flashLoan = new MockFlashLoanProvider();

        // Deploy DEXes
        dex1 = new MockDEX();
        dex2 = new MockDEX();
        dex3 = new MockDEX();

        // Setup triangular opportunity: USDC -> ETH -> BTC -> USDC
        // DEX1: USDC->ETH at good rate
        dex1.setPrice(address(usdc), address(weth), 5);  // 0.0005 ETH per USDC

        // DEX2: ETH->BTC at good rate
        dex2.setPrice(address(weth), address(wbtc), 625); // 0.0625 BTC per ETH

        // DEX3: BTC->USDC at good rate (creates profit)
        dex3.setPrice(address(wbtc), address(usdc), 340000_00); // 34000 USDC per BTC

        // Deploy arbitrage contract
        vm.prank(trader);
        arbitrage = new TriangularArbitrage(address(flashLoan));

        // Fund flash loan and DEXes
        usdc.mint(address(flashLoan), 10_000_000e6);
        weth.mint(address(dex1), 10_000e18);
        wbtc.mint(address(dex2), 1_000e8);
        usdc.mint(address(dex3), 100_000_000e6);
    }

    function test_ExecuteTriangular() public {
        TriangularArbitrage.TriangularParams memory params = TriangularArbitrage.TriangularParams({
            router1: address(dex1),
            router2: address(dex2),
            router3: address(dex3),
            tokenA: address(usdc),
            tokenB: address(weth),
            tokenC: address(wbtc)
        });

        vm.prank(trader);
        arbitrage.executeTriangular(100_000e6, params);

        uint256 profit = usdc.balanceOf(address(arbitrage));
        assertGt(profit, 0, "Should have profit from triangular arbitrage");
    }

    function test_CheckTriangular() public view {
        TriangularArbitrage.TriangularParams memory params = TriangularArbitrage.TriangularParams({
            router1: address(dex1),
            router2: address(dex2),
            router3: address(dex3),
            tokenA: address(usdc),
            tokenB: address(weth),
            tokenC: address(wbtc)
        });

        uint256 fee = (100_000e6 * 9) / 10000;
        (bool profitable, uint256 expectedProfit) = arbitrage.checkTriangular(
            100_000e6,
            params,
            fee
        );

        assertTrue(profitable, "Should be profitable");
        assertGt(expectedProfit, 0, "Should have expected profit");
    }

    function test_RevertOnUnprofitableTriangular() public {
        // Set prices to make arbitrage unprofitable
        dex3.setPrice(address(wbtc), address(usdc), 300000_00); // Lower BTC price

        TriangularArbitrage.TriangularParams memory params = TriangularArbitrage.TriangularParams({
            router1: address(dex1),
            router2: address(dex2),
            router3: address(dex3),
            tokenA: address(usdc),
            tokenB: address(weth),
            tokenC: address(wbtc)
        });

        vm.prank(trader);
        vm.expectRevert(TriangularArbitrage.ArbitrageNotProfitable.selector);
        arbitrage.executeTriangular(100_000e6, params);
    }
}

contract MultiHopArbitrageTest is Test {
    MultiHopArbitrage public arbitrage;
    MockFlashLoanProvider public flashLoan;
    MockDEX public dex1;
    MockDEX public dex2;
    MockERC20 public usdc;
    MockERC20 public weth;

    address public trader;

    function setUp() public {
        trader = makeAddr("trader");

        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);

        flashLoan = new MockFlashLoanProvider();
        dex1 = new MockDEX();
        dex2 = new MockDEX();

        // Arbitrage opportunity
        dex1.setPrice(address(usdc), address(weth), 5);
        dex2.setPrice(address(weth), address(usdc), 21000_00);

        vm.prank(trader);
        arbitrage = new MultiHopArbitrage(address(flashLoan));

        usdc.mint(address(flashLoan), 10_000_000e6);
        weth.mint(address(dex1), 10_000e18);
        usdc.mint(address(dex2), 100_000_000e6);
    }

    function test_ExecuteMultiHop() public {
        MultiHopArbitrage.SwapInstruction[] memory swaps = new MultiHopArbitrage.SwapInstruction[](2);

        // Swap 1: USDC -> WETH on dex1
        swaps[0] = MultiHopArbitrage.SwapInstruction({
            router: address(dex1),
            tokenIn: address(usdc),
            tokenOut: address(weth),
            amountIn: 100_000e6
        });

        // Swap 2: WETH -> USDC on dex2 (use full balance)
        swaps[1] = MultiHopArbitrage.SwapInstruction({
            router: address(dex2),
            tokenIn: address(weth),
            tokenOut: address(usdc),
            amountIn: 0  // Use full WETH balance
        });

        vm.prank(trader);
        arbitrage.executeMultiHop(address(usdc), 100_000e6, swaps);

        uint256 profit = usdc.balanceOf(address(arbitrage));
        assertGt(profit, 0, "Should have profit");
    }
}
