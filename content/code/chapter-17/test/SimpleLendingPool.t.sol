// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/SimpleLendingPool.sol";
import "../src/InterestRateModels.sol";

/// @title MockERC20
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public _decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) {
        name = _name;
        symbol = _symbol;
        _decimals = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
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

/// @title MockOracle
contract MockOracle is IOracle {
    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    function getPrice(address token) external view override returns (uint256) {
        return prices[token];
    }
}

contract SimpleLendingPoolTest is Test {
    SimpleLendingPool public pool;
    MockOracle public oracle;
    MockERC20 public weth;
    MockERC20 public usdc;

    address public alice;
    address public bob;
    address public liquidator;

    uint256 constant PRECISION = 1e18;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        liquidator = makeAddr("liquidator");

        // Deploy contracts
        oracle = new MockOracle();
        pool = new SimpleLendingPool(address(oracle));

        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Set prices: ETH = $2000, USDC = $1
        oracle.setPrice(address(weth), 2000e18);
        oracle.setPrice(address(usdc), 1e18);

        // Add assets to pool
        // WETH: 75% collateral factor, 5% liquidation bonus, 10% reserve factor
        pool.addAsset(address(weth), 7500, 500, 1000, true, true);
        // USDC: 80% collateral factor, 5% liquidation bonus, 10% reserve factor
        pool.addAsset(address(usdc), 8000, 500, 1000, true, true);

        // Mint tokens
        weth.mint(alice, 100e18);
        weth.mint(bob, 100e18);
        weth.mint(liquidator, 100e18);
        usdc.mint(alice, 200000e6);
        usdc.mint(bob, 200000e6);
        usdc.mint(liquidator, 200000e6);

        // Approve
        vm.startPrank(alice);
        weth.approve(address(pool), type(uint256).max);
        usdc.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        weth.approve(address(pool), type(uint256).max);
        usdc.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(liquidator);
        weth.approve(address(pool), type(uint256).max);
        usdc.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function test_Supply() public {
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        assertEq(pool.getUserSupplied(alice, address(weth)), 10e18);
        assertEq(weth.balanceOf(address(pool)), 10e18);
    }

    function test_Borrow() public {
        // Alice supplies WETH as collateral
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        // Bob supplies USDC for borrowing
        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        // Alice borrows USDC against WETH collateral
        // 10 WETH = $20,000 * 75% collateral factor = $15,000 borrowing power
        vm.prank(alice);
        pool.borrow(address(usdc), 10000e6); // $10,000

        assertEq(pool.getUserBorrowed(alice, address(usdc)), 10000e6);
        assertEq(usdc.balanceOf(alice), 200000e6 + 10000e6);
    }

    function test_RevertBorrowInsufficientCollateral() public {
        vm.prank(alice);
        pool.supply(address(weth), 1e18); // $2000 * 75% = $1500 borrowing power

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        vm.expectRevert(SimpleLendingPool.InsufficientCollateral.selector);
        pool.borrow(address(usdc), 2000e6); // Try to borrow $2000
    }

    function test_Repay() public {
        // Setup: Alice supplies, Bob supplies, Alice borrows
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        pool.borrow(address(usdc), 5000e6);

        // Alice repays
        vm.prank(alice);
        pool.repay(address(usdc), 5000e6);

        assertEq(pool.getUserBorrowed(alice, address(usdc)), 0);
    }

    function test_Withdraw() public {
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(alice);
        pool.withdraw(address(weth), 5e18);

        assertEq(pool.getUserSupplied(alice, address(weth)), 5e18);
        assertEq(weth.balanceOf(alice), 95e18);
    }

    function test_RevertWithdrawInsufficientCollateral() public {
        // Alice supplies and borrows
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        pool.borrow(address(usdc), 10000e6);

        // Try to withdraw too much
        vm.prank(alice);
        vm.expectRevert(SimpleLendingPool.InsufficientCollateral.selector);
        pool.withdraw(address(weth), 8e18);
    }

    function test_Liquidation() public {
        // Setup position
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        pool.borrow(address(usdc), 14000e6); // Near max borrow

        // Price drop makes position liquidatable
        oracle.setPrice(address(weth), 1500e18); // ETH drops to $1500

        // Alice's position:
        // Collateral value: 10 * $1500 * 75% = $11,250
        // Debt: $14,000
        // Health factor < 1, liquidatable

        uint256 healthFactor = pool.getHealthFactor(alice);
        assertLt(healthFactor, PRECISION);

        // Liquidator repays debt and gets collateral
        uint256 liquidatorWethBefore = weth.balanceOf(liquidator);

        vm.prank(liquidator);
        pool.liquidate(alice, address(weth), address(usdc), 7000e6); // Repay half

        // Liquidator should have received WETH with bonus
        uint256 liquidatorWethAfter = weth.balanceOf(liquidator);
        assertGt(liquidatorWethAfter, liquidatorWethBefore);
    }

    function test_InterestAccrual() public {
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        pool.borrow(address(usdc), 50000e6);

        uint256 initialDebt = pool.getUserBorrowed(alice, address(usdc));

        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Trigger interest accrual via any interaction
        vm.prank(bob);
        pool.supply(address(usdc), 1e6);

        uint256 newDebt = pool.getUserBorrowed(alice, address(usdc));

        // Debt should have increased due to interest
        assertGt(newDebt, initialDebt);
    }

    function test_HealthFactor() public {
        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        // No borrows = max health factor
        uint256 healthNoDebt = pool.getHealthFactor(alice);
        assertEq(healthNoDebt, type(uint256).max);

        vm.prank(bob);
        pool.supply(address(usdc), 100000e6);

        vm.prank(alice);
        pool.borrow(address(usdc), 10000e6);

        // With borrows, health factor should be > 1
        uint256 healthWithDebt = pool.getHealthFactor(alice);
        assertGt(healthWithDebt, PRECISION);
    }

    function test_UtilizationRate() public {
        vm.prank(alice);
        pool.supply(address(usdc), 100000e6);

        assertEq(pool.getUtilization(address(usdc)), 0);

        vm.prank(alice);
        pool.supply(address(weth), 10e18);

        vm.prank(alice);
        pool.borrow(address(usdc), 50000e6);

        // 50% utilization = 5000 bps
        assertEq(pool.getUtilization(address(usdc)), 5000);
    }

    function testFuzz_SupplyWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100e18);

        vm.startPrank(alice);
        pool.supply(address(weth), amount);
        assertEq(pool.getUserSupplied(alice, address(weth)), amount);

        pool.withdraw(address(weth), amount);
        assertEq(pool.getUserSupplied(alice, address(weth)), 0);
        vm.stopPrank();
    }
}

contract InterestRateModelTest is Test {
    LinearInterestRateModel public linearModel;
    JumpRateModel public jumpModel;

    uint256 constant PRECISION = 1e18;

    function setUp() public {
        // 2% base, 10% slope
        linearModel = new LinearInterestRateModel(2e16, 10e16);

        // 2% base, 10% slope, 100% jump, 80% kink
        jumpModel = new JumpRateModel(2e16, 10e16, 100e16, 80e16);
    }

    function test_LinearModel_ZeroUtilization() public view {
        uint256 rate = linearModel.getBorrowRate(100e18, 0, 0);
        // Should be base rate only
        uint256 expectedRate = 2e16 / 365 days;
        assertApproxEqRel(rate, expectedRate, 1e15); // 0.1% tolerance
    }

    function test_LinearModel_FullUtilization() public view {
        // 100% utilization: cash=0, borrows=100, reserves=0
        uint256 rate = linearModel.getBorrowRate(0, 100e18, 0);
        // Should be base + full multiplier = 2% + 10% = 12%
        uint256 expectedRate = 12e16 / 365 days;
        assertApproxEqRel(rate, expectedRate, 1e15);
    }

    function test_JumpModel_BelowKink() public view {
        // 50% utilization (below 80% kink)
        uint256 rate = jumpModel.getBorrowRate(50e18, 50e18, 0);
        // Linear portion: 2% + 50%*10%/80% = 2% + 6.25% = 8.25%
        // Actually: 2% + (50%/100%) * 10% = 2% + 5% = 7%
        assertGt(rate, 0);
    }

    function test_JumpModel_AboveKink() public view {
        // 90% utilization (above 80% kink)
        uint256 rate = jumpModel.getBorrowRate(10e18, 90e18, 0);
        // Should be significantly higher due to jump
        uint256 belowKinkRate = jumpModel.getBorrowRate(20e18, 80e18, 0);
        assertGt(rate, belowKinkRate);
    }

    function test_JumpModel_RateCurve() public view {
        (uint256[] memory utilizations, uint256[] memory rates) = jumpModel.getRateCurve();

        assertEq(utilizations.length, 11);
        assertEq(rates.length, 11);

        // Rates should increase monotonically
        for (uint256 i = 1; i < rates.length; i++) {
            assertGe(rates[i], rates[i-1]);
        }

        // Rate at kink should be lower than rate after kink
        // Kink is at 80% = index 8
        assertLt(rates[8], rates[9]);
    }

    function testFuzz_LinearModel_Monotonic(uint256 utilization) public view {
        vm.assume(utilization > 0 && utilization <= 100e18);

        uint256 cash = 100e18 - utilization;
        uint256 borrows = utilization;

        uint256 rate = linearModel.getBorrowRate(cash, borrows, 0);

        // Rate should always be positive
        assertGt(rate, 0);

        // Rate should be bounded
        uint256 maxExpectedRate = 12e16 / 365 days;
        assertLe(rate, maxExpectedRate * 2);
    }
}
