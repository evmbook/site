// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ConstantProductAMM.sol";

/// @title MockERC20
/// @notice Simple ERC-20 for testing
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

contract ConstantProductAMMTest is Test {
    ConstantProductAMM public amm;
    MockERC20 public token0;
    MockERC20 public token1;
    AMMRouter public router;

    address public alice;
    address public bob;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        token0 = new MockERC20("Token A", "TKA", 18);
        token1 = new MockERC20("Token B", "TKB", 18);

        amm = new ConstantProductAMM(address(token0), address(token1));
        router = new AMMRouter();

        // Mint tokens
        token0.mint(alice, 100000e18);
        token1.mint(alice, 100000e18);
        token0.mint(bob, 10000e18);
        token1.mint(bob, 10000e18);

        // Approve
        vm.startPrank(alice);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(address(amm.token0()), address(token0));
        assertEq(address(amm.token1()), address(token1));
        assertEq(amm.reserve0(), 0);
        assertEq(amm.reserve1(), 0);
        assertEq(amm.totalSupply(), 0);
    }

    function test_AddInitialLiquidity() public {
        // Add initial liquidity: 10000 token0, 20000 token1
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 20000e18);
        uint256 liquidity = amm.addLiquidity(alice);
        vm.stopPrank();

        // sqrt(10000 * 20000) - 1000 = ~14142 - 1000 = ~13142
        assertGt(liquidity, 13000e18);
        assertLt(liquidity, 15000e18);

        assertEq(amm.reserve0(), 10000e18);
        assertEq(amm.reserve1(), 20000e18);
        assertEq(amm.balanceOf(alice), liquidity);

        // Minimum liquidity burned
        assertEq(amm.balanceOf(address(0)), 1000);
    }

    function test_AddProportionalLiquidity() public {
        // Initial liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 20000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Bob adds proportional liquidity
        vm.startPrank(bob);
        token0.transfer(address(amm), 1000e18);
        token1.transfer(address(amm), 2000e18);
        uint256 bobLiquidity = amm.addLiquidity(bob);
        vm.stopPrank();

        // Bob should get ~10% of Alice's liquidity
        assertGt(bobLiquidity, 1300e18);
        assertLt(bobLiquidity, 1500e18);
    }

    function test_RemoveLiquidity() public {
        // Add liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 20000e18);
        uint256 liquidity = amm.addLiquidity(alice);

        // Transfer LP tokens to AMM for removal
        amm.transfer(address(amm), liquidity);
        (uint256 amount0, uint256 amount1) = amm.removeLiquidity(alice);
        vm.stopPrank();

        // Should get back ~original amounts minus minimum liquidity
        assertGt(amount0, 9990e18);
        assertGt(amount1, 19980e18);
    }

    function test_SwapToken0ForToken1() public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Bob swaps 100 token0 for token1
        uint256 amountIn = 100e18;
        uint256 expectedOut = amm.getAmountOut(amountIn, 10000e18, 10000e18);

        vm.startPrank(bob);
        token0.transfer(address(amm), amountIn);
        amm.swap(0, expectedOut, bob);
        vm.stopPrank();

        assertEq(token1.balanceOf(bob), 10000e18 + expectedOut);
    }

    function test_SwapToken1ForToken0() public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Bob swaps 100 token1 for token0
        uint256 amountIn = 100e18;
        uint256 expectedOut = amm.getAmountOut(amountIn, 10000e18, 10000e18);

        vm.startPrank(bob);
        token1.transfer(address(amm), amountIn);
        amm.swap(expectedOut, 0, bob);
        vm.stopPrank();

        assertEq(token0.balanceOf(bob), 10000e18 + expectedOut);
    }

    function test_GetAmountOut() public view {
        // 100 in with 10000/10000 reserves, 0.3% fee
        // amountOut = (100 * 9970 * 10000) / (10000 * 10000 + 100 * 9970)
        // = 9970000 / 100997 = ~98.7
        uint256 amountOut = amm.getAmountOut(100e18, 10000e18, 10000e18);
        assertGt(amountOut, 98e18);
        assertLt(amountOut, 100e18);
    }

    function test_GetAmountIn() public view {
        // Need 100 out from 10000/10000 reserves
        uint256 amountIn = amm.getAmountIn(100e18, 10000e18, 10000e18);
        assertGt(amountIn, 100e18); // Must pay more than you receive
        assertLt(amountIn, 102e18); // But not too much more
    }

    function test_PriceImpact() public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Small trade: low impact
        uint256 smallImpact = amm.getPriceImpact(100e18, 10000e18, 10000e18);
        assertLt(smallImpact, 100); // < 1%

        // Large trade: high impact
        uint256 largeImpact = amm.getPriceImpact(5000e18, 10000e18, 10000e18);
        assertGt(largeImpact, 1000); // > 10%
    }

    function test_SpotPrice() public {
        // Setup 1:2 ratio
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 20000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        uint256 spotPrice = amm.getSpotPrice();
        assertEq(spotPrice, 2e18); // 1 token0 = 2 token1
    }

    function test_SwapRevertInsufficientOutput() public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Try to swap with zero output
        vm.startPrank(bob);
        token0.transfer(address(amm), 100e18);
        vm.expectRevert(ConstantProductAMM.InsufficientOutputAmount.selector);
        amm.swap(0, 0, bob);
        vm.stopPrank();
    }

    function test_RouterSwap() public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        // Bob swaps via router
        uint256 balanceBefore = token1.balanceOf(bob);
        uint256 expectedOut = amm.getAmountOut(100e18, 10000e18, 10000e18);

        vm.prank(bob);
        uint256 amountOut = router.swapExactTokensForTokens(
            amm,
            address(token0),
            100e18,
            expectedOut - 1e18, // 1% slippage
            bob
        );

        assertEq(amountOut, expectedOut);
        assertEq(token1.balanceOf(bob), balanceBefore + amountOut);
    }

    function testFuzz_AddLiquidity(uint256 amount0, uint256 amount1) public {
        vm.assume(amount0 > 1001 && amount0 < 50000e18);
        vm.assume(amount1 > 1001 && amount1 < 50000e18);

        vm.startPrank(alice);
        token0.transfer(address(amm), amount0);
        token1.transfer(address(amm), amount1);
        uint256 liquidity = amm.addLiquidity(alice);
        vm.stopPrank();

        assertGt(liquidity, 0);
        assertEq(amm.reserve0(), amount0);
        assertEq(amm.reserve1(), amount1);
    }

    function testFuzz_SwapMaintainsK(uint256 amountIn) public {
        // Setup liquidity
        vm.startPrank(alice);
        token0.transfer(address(amm), 10000e18);
        token1.transfer(address(amm), 10000e18);
        amm.addLiquidity(alice);
        vm.stopPrank();

        vm.assume(amountIn > 1e15 && amountIn < 5000e18);

        uint256 k_before = amm.reserve0() * amm.reserve1();

        uint256 amountOut = amm.getAmountOut(amountIn, amm.reserve0(), amm.reserve1());

        vm.startPrank(bob);
        token0.transfer(address(amm), amountIn);
        amm.swap(0, amountOut, bob);
        vm.stopPrank();

        uint256 k_after = amm.reserve0() * amm.reserve1();

        // K should increase (due to fees)
        assertGe(k_after, k_before);
    }
}
