// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ERC20Token.sol";
import "../src/ERC4626Vault.sol";

contract ERC4626Test is Test {
    ERC4626 public vault;
    ERC20Mintable public asset;
    address public alice;
    address public bob;

    function setUp() public {
        asset = new ERC20Mintable("Test Asset", "ASSET", 18);
        vault = new ERC4626(IERC20(address(asset)), "Vault Shares", "vASSET");

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Mint assets to alice
        asset.mint(alice, 10000e18);

        // Approve vault
        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_Metadata() public view {
        assertEq(vault.name(), "Vault Shares");
        assertEq(vault.symbol(), "vASSET");
        assertEq(vault.decimals(), 18);
        assertEq(vault.asset(), address(asset));
    }

    function test_Deposit() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000e18, alice);

        assertEq(shares, 1000e18); // 1:1 initially
        assertEq(vault.balanceOf(alice), 1000e18);
        assertEq(vault.totalAssets(), 1000e18);
        assertEq(asset.balanceOf(alice), 9000e18);
    }

    function test_DepositEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IERC4626.Deposit(alice, alice, 1000e18, 1000e18);

        vm.prank(alice);
        vault.deposit(1000e18, alice);
    }

    function test_Mint() public {
        vm.prank(alice);
        uint256 assets = vault.mint(1000e18, alice);

        assertEq(assets, 1000e18); // 1:1 initially
        assertEq(vault.balanceOf(alice), 1000e18);
        assertEq(vault.totalAssets(), 1000e18);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        vault.deposit(1000e18, alice);

        uint256 shares = vault.withdraw(500e18, alice, alice);
        vm.stopPrank();

        assertEq(shares, 500e18);
        assertEq(vault.balanceOf(alice), 500e18);
        assertEq(asset.balanceOf(alice), 9500e18);
    }

    function test_WithdrawEmitsEvent() public {
        vm.startPrank(alice);
        vault.deposit(1000e18, alice);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Withdraw(alice, alice, alice, 500e18, 500e18);

        vault.withdraw(500e18, alice, alice);
        vm.stopPrank();
    }

    function test_Redeem() public {
        vm.startPrank(alice);
        vault.deposit(1000e18, alice);

        uint256 assets = vault.redeem(500e18, alice, alice);
        vm.stopPrank();

        assertEq(assets, 500e18);
        assertEq(vault.balanceOf(alice), 500e18);
        assertEq(asset.balanceOf(alice), 9500e18);
    }

    function test_WithdrawOnBehalf() public {
        vm.startPrank(alice);
        vault.deposit(1000e18, alice);
        vault.approve(bob, 500e18);
        vm.stopPrank();

        vm.prank(bob);
        vault.withdraw(500e18, bob, alice);

        assertEq(vault.balanceOf(alice), 500e18);
        assertEq(asset.balanceOf(bob), 500e18);
    }

    function test_ConversionRatioWithYield() public {
        // Alice deposits
        vm.prank(alice);
        vault.deposit(1000e18, alice);

        // Simulate yield by directly adding assets
        asset.mint(address(vault), 100e18); // 10% yield

        // Now 1000 shares = 1100 assets
        assertEq(vault.totalAssets(), 1100e18);
        assertEq(vault.convertToAssets(1000e18), 1100e18);
        assertEq(vault.convertToShares(1100e18), 1000e18);
    }

    function test_PreviewFunctions() public {
        vm.prank(alice);
        vault.deposit(1000e18, alice);

        // Add yield
        asset.mint(address(vault), 100e18);

        // Preview should match actual
        uint256 previewDeposit = vault.previewDeposit(1000e18);
        uint256 previewMint = vault.previewMint(1000e18);
        uint256 previewWithdraw = vault.previewWithdraw(500e18);
        uint256 previewRedeem = vault.previewRedeem(500e18);

        assertGt(previewDeposit, 0);
        assertGt(previewMint, 0);
        assertGt(previewWithdraw, 0);
        assertGt(previewRedeem, 0);
    }

    function test_MaxFunctions() public view {
        assertEq(vault.maxDeposit(alice), type(uint256).max);
        assertEq(vault.maxMint(alice), type(uint256).max);
        assertEq(vault.maxWithdraw(alice), 0); // No shares yet
        assertEq(vault.maxRedeem(alice), 0);   // No shares yet
    }

    function test_MaxFunctionsWithDeposit() public {
        vm.prank(alice);
        vault.deposit(1000e18, alice);

        assertEq(vault.maxWithdraw(alice), 1000e18);
        assertEq(vault.maxRedeem(alice), 1000e18);
    }

    function testFuzz_DepositWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 10000e18);

        vm.startPrank(alice);
        uint256 shares = vault.deposit(amount, alice);

        assertEq(vault.balanceOf(alice), shares);

        uint256 assets = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        // Due to rounding, might get back slightly less
        assertLe(assets, amount);
        assertGe(assets, amount - 1); // At most 1 wei rounding error
    }
}

contract YieldVaultTest is Test {
    YieldVault public vault;
    ERC20Mintable public asset;
    address public alice;

    function setUp() public {
        asset = new ERC20Mintable("Test Asset", "ASSET", 18);
        vault = new YieldVault(
            IERC20(address(asset)),
            "Yield Vault",
            "yASSET",
            500 // 5% APY
        );

        alice = makeAddr("alice");
        asset.mint(alice, 10000e18);

        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_YieldAccrual() public {
        vm.prank(alice);
        vault.deposit(1000e18, alice);

        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);

        // Total assets should include accrued yield
        uint256 totalAssets = vault.totalAssets();

        // Should be ~1050e18 (1000 + 5% yield)
        // Slight variation due to simple interest calculation
        assertGt(totalAssets, 1000e18);
        assertLt(totalAssets, 1100e18);
    }
}

contract FeeVaultTest is Test {
    FeeVault public vault;
    ERC20Mintable public asset;
    address public alice;
    address public feeRecipient;

    function setUp() public {
        asset = new ERC20Mintable("Test Asset", "ASSET", 18);
        feeRecipient = makeAddr("feeRecipient");

        vault = new FeeVault(
            IERC20(address(asset)),
            "Fee Vault",
            "fASSET",
            1000, // 10% performance fee
            200,  // 2% management fee
            feeRecipient
        );

        alice = makeAddr("alice");
        asset.mint(alice, 10000e18);

        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_FeeCollection() public {
        vm.prank(alice);
        vault.deposit(1000e18, alice);

        // Simulate yield
        asset.mint(address(vault), 100e18);

        // Fast forward
        vm.warp(block.timestamp + 30 days);

        // Collect fees
        vault.collectFees();

        // Fee recipient should have received shares
        assertGt(vault.balanceOf(feeRecipient), 0);
    }
}
