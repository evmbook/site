// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/FlashbotsLiquidator.sol";
import "../src/SimpleLendingPool.sol";

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
}

/// @title MockSwapRouter
contract MockSwapRouter is ISwapRouter {
    // Swap rate: 1 collateral = 1.05 debt (5% profit margin for liquidator)
    uint256 public swapRate = 105;

    function setSwapRate(uint256 _rate) external {
        swapRate = _rate;
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

        // Calculate output (simplified)
        uint256 amountOut = (amountIn * swapRate) / 100;
        require(amountOut >= amountOutMin, "Slippage");

        // Execute swap
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata /* path */)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = (amountIn * swapRate) / 100;
    }
}

/// @title MockLendingPool
contract MockLendingPool is ILendingPool {
    mapping(address => uint256) public healthFactors;
    mapping(address => mapping(address => uint256)) public supplied;
    mapping(address => mapping(address => uint256)) public borrowed;

    uint256 public liquidationBonus = 500; // 5%

    function setHealthFactor(address user, uint256 factor) external {
        healthFactors[user] = factor;
    }

    function setPosition(
        address user,
        address collateralAsset,
        uint256 collateralAmount,
        address debtAsset,
        uint256 debtAmount
    ) external {
        supplied[user][collateralAsset] = collateralAmount;
        borrowed[user][debtAsset] = debtAmount;
    }

    function getHealthFactor(address user) external view override returns (uint256) {
        return healthFactors[user];
    }

    function getUserSupplied(address user, address asset) external view override returns (uint256) {
        return supplied[user][asset];
    }

    function getUserBorrowed(address user, address asset) external view override returns (uint256) {
        return borrowed[user][asset];
    }

    function liquidate(
        address borrower,
        address collateralAsset,
        address debtAsset,
        uint256 debtToRepay
    ) external override {
        require(healthFactors[borrower] < 1e18, "Not liquidatable");

        // Take debt payment
        IERC20(debtAsset).transferFrom(msg.sender, address(this), debtToRepay);

        // Calculate collateral to give (with bonus)
        uint256 collateralAmount = (debtToRepay * (10000 + liquidationBonus)) / 10000;

        // Transfer collateral
        IERC20(collateralAsset).transfer(msg.sender, collateralAmount);

        // Update state
        borrowed[borrower][debtAsset] -= debtToRepay;
        supplied[borrower][collateralAsset] -= collateralAmount;

        // Update health factor (simplified: assume healthy after partial liquidation)
        if (borrowed[borrower][debtAsset] == 0) {
            healthFactors[borrower] = type(uint256).max;
        }
    }
}

contract FlashbotsLiquidatorTest is Test {
    FlashbotsLiquidator public liquidator;
    MockLendingPool public lendingPool;
    MockFlashLoanProvider public flashLoan;
    MockSwapRouter public swapRouter;
    MockERC20 public collateralToken;
    MockERC20 public debtToken;

    address public searcher;
    address public borrower;

    function setUp() public {
        searcher = makeAddr("searcher");
        borrower = makeAddr("borrower");

        // Deploy mock contracts
        collateralToken = new MockERC20("Collateral", "COL", 18);
        debtToken = new MockERC20("Debt", "DEBT", 18);
        lendingPool = new MockLendingPool();
        flashLoan = new MockFlashLoanProvider();
        swapRouter = new MockSwapRouter();

        // Deploy liquidator as searcher
        vm.prank(searcher);
        liquidator = new FlashbotsLiquidator(
            address(lendingPool),
            address(flashLoan),
            address(swapRouter),
            1e15 // 0.001 token min profit
        );

        // Setup initial balances
        // Flash loan provider needs debt tokens to lend
        debtToken.mint(address(flashLoan), 1000000e18);

        // Lending pool needs collateral to give during liquidation
        collateralToken.mint(address(lendingPool), 1000000e18);

        // Swap router needs debt tokens to give during swap
        debtToken.mint(address(swapRouter), 1000000e18);

        // Setup borrower position
        lendingPool.setPosition(
            borrower,
            address(collateralToken),
            1000e18, // 1000 collateral
            address(debtToken),
            800e18   // 800 debt
        );
        lendingPool.setHealthFactor(borrower, 0.9e18); // Unhealthy
    }

    function test_ExecuteLiquidation() public {
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        // Execute liquidation
        vm.prank(searcher);
        liquidator.executeLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18, // Liquidate half the debt
            400e18, // Min collateral
            swapPath
        );

        // Verify profit was made
        uint256 profit = debtToken.balanceOf(address(liquidator));
        assertGt(profit, 0, "Should have profit");
    }

    function test_RevertOnHealthyPosition() public {
        // Set position as healthy
        lendingPool.setHealthFactor(borrower, 1.5e18);

        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        vm.prank(searcher);
        vm.expectRevert(FlashbotsLiquidator.PositionHealthy.selector);
        liquidator.executeLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            400e18,
            swapPath
        );
    }

    function test_RevertOnUnprofitableLiquidation() public {
        // Set swap rate to make liquidation unprofitable
        swapRouter.setSwapRate(90); // 10% loss on swap

        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        vm.prank(searcher);
        vm.expectRevert(FlashbotsLiquidator.UnprofitableLiquidation.selector);
        liquidator.executeLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            400e18,
            swapPath
        );
    }

    function test_SimulateLiquidation() public {
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        (bool profitable, uint256 expectedProfit) = liquidator.simulateLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            swapPath
        );

        assertTrue(profitable, "Should be profitable");
        assertGt(expectedProfit, 0, "Should have expected profit");
    }

    function test_SimulateLiquidation_HealthyPosition() public {
        lendingPool.setHealthFactor(borrower, 1.5e18);

        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        (bool profitable,) = liquidator.simulateLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            swapPath
        );

        assertFalse(profitable, "Should not be profitable for healthy position");
    }

    function test_WithdrawProfits() public {
        // First execute a liquidation to generate profit
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        vm.prank(searcher);
        liquidator.executeLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            400e18,
            swapPath
        );

        uint256 liquidatorBalance = debtToken.balanceOf(address(liquidator));
        assertGt(liquidatorBalance, 0, "Should have profit to withdraw");

        // Withdraw profits
        vm.prank(searcher);
        liquidator.withdrawProfits(address(debtToken));

        assertEq(debtToken.balanceOf(address(liquidator)), 0, "Liquidator should be empty");
        assertEq(debtToken.balanceOf(searcher), liquidatorBalance, "Searcher should have profit");
    }

    function test_OnlyOwnerCanExecute() public {
        address[] memory swapPath = new address[](2);
        swapPath[0] = address(collateralToken);
        swapPath[1] = address(debtToken);

        vm.prank(borrower); // Wrong caller
        vm.expectRevert(FlashbotsLiquidator.NotOwner.selector);
        liquidator.executeLiquidation(
            borrower,
            address(collateralToken),
            address(debtToken),
            400e18,
            400e18,
            swapPath
        );
    }

    function test_BatchLiquidate() public {
        // Setup second borrower
        address borrower2 = makeAddr("borrower2");
        lendingPool.setPosition(
            borrower2,
            address(collateralToken),
            500e18,
            address(debtToken),
            400e18
        );
        lendingPool.setHealthFactor(borrower2, 0.85e18);

        // Prepare batch arrays
        address[] memory borrowers = new address[](2);
        borrowers[0] = borrower;
        borrowers[1] = borrower2;

        address[] memory collaterals = new address[](2);
        collaterals[0] = address(collateralToken);
        collaterals[1] = address(collateralToken);

        address[] memory debts = new address[](2);
        debts[0] = address(debtToken);
        debts[1] = address(debtToken);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 200e18;
        amounts[1] = 200e18;

        uint256[] memory minOuts = new uint256[](2);
        minOuts[0] = 200e18;
        minOuts[1] = 200e18;

        address[][] memory paths = new address[][](2);
        paths[0] = new address[](2);
        paths[0][0] = address(collateralToken);
        paths[0][1] = address(debtToken);
        paths[1] = new address[](2);
        paths[1][0] = address(collateralToken);
        paths[1][1] = address(debtToken);

        vm.prank(searcher);
        liquidator.batchLiquidate(
            borrowers,
            collaterals,
            debts,
            amounts,
            minOuts,
            paths
        );

        // Should have profit from both liquidations
        uint256 profit = debtToken.balanceOf(address(liquidator));
        assertGt(profit, 0, "Should have profit from batch");
    }
}

contract LiquidationMonitorTest is Test {
    LiquidationMonitor public monitor;
    MockLendingPool public lendingPool;

    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        monitor = new LiquidationMonitor();
        lendingPool = new MockLendingPool();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Setup positions with different health factors
        lendingPool.setHealthFactor(user1, 0.8e18);  // Liquidatable
        lendingPool.setHealthFactor(user2, 1.5e18);  // Healthy
        lendingPool.setHealthFactor(user3, 0.95e18); // Liquidatable
    }

    function test_FindLiquidatable() public view {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        address[] memory liquidatable = monitor.findLiquidatable(
            address(lendingPool),
            users,
            1e18 // threshold
        );

        assertEq(liquidatable.length, 2, "Should find 2 liquidatable positions");
    }

    function test_CheckPositions() public view {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        LiquidationMonitor.LiquidatablePosition[] memory positions =
            monitor.checkPositions(address(lendingPool), users);

        assertEq(positions.length, 3, "Should return all positions");
        assertEq(positions[0].healthFactor, 0.8e18);
        assertEq(positions[1].healthFactor, 1.5e18);
        assertEq(positions[2].healthFactor, 0.95e18);
    }
}

contract MEVShareLiquidatorTest is Test {
    MEVShareLiquidator public liquidator;

    function setUp() public {
        liquidator = new MEVShareLiquidator();
    }

    function test_UserMEVShare() public view {
        assertEq(liquidator.userMEVShare(), 2000, "Default should be 20%");
    }

    function test_SetUserMEVShare() public {
        liquidator.setUserMEVShare(3000);
        assertEq(liquidator.userMEVShare(), 3000, "Should update to 30%");
    }

    function test_RevertExcessiveMEVShare() public {
        vm.expectRevert("Max 50%");
        liquidator.setUserMEVShare(6000);
    }
}
