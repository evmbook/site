// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ERC20Token.sol";

contract ERC20Test is Test {
    ERC20Mintable public token;
    address public owner;
    address public alice;
    address public bob;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        token = new ERC20Mintable("Test Token", "TEST", 18);
        token.mint(alice, 1000e18);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
    }

    function test_InitialBalance() public view {
        assertEq(token.balanceOf(alice), 1000e18);
        assertEq(token.totalSupply(), 1000e18);
    }

    function test_Transfer() public {
        vm.prank(alice);
        token.transfer(bob, 100e18);

        assertEq(token.balanceOf(alice), 900e18);
        assertEq(token.balanceOf(bob), 100e18);
    }

    function test_TransferEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(alice, bob, 100e18);

        vm.prank(alice);
        token.transfer(bob, 100e18);
    }

    function test_RevertTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            ERC20.InsufficientBalance.selector,
            alice,
            1000e18,
            1001e18
        ));
        token.transfer(bob, 1001e18);
    }

    function test_RevertTransferToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(ERC20.TransferToZeroAddress.selector);
        token.transfer(address(0), 100e18);
    }

    function test_Approve() public {
        vm.prank(alice);
        token.approve(bob, 500e18);

        assertEq(token.allowance(alice, bob), 500e18);
    }

    function test_ApproveEmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(alice, bob, 500e18);

        vm.prank(alice);
        token.approve(bob, 500e18);
    }

    function test_TransferFrom() public {
        vm.prank(alice);
        token.approve(bob, 500e18);

        vm.prank(bob);
        token.transferFrom(alice, bob, 200e18);

        assertEq(token.balanceOf(alice), 800e18);
        assertEq(token.balanceOf(bob), 200e18);
        assertEq(token.allowance(alice, bob), 300e18);
    }

    function test_TransferFromInfiniteApproval() public {
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, bob, 200e18);

        // Infinite approval should not decrease
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function test_RevertTransferFromInsufficientAllowance() public {
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(
            ERC20.InsufficientAllowance.selector,
            bob,
            100e18,
            200e18
        ));
        token.transferFrom(alice, bob, 200e18);
    }

    function test_IncreaseAllowance() public {
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(alice);
        token.increaseAllowance(bob, 50e18);

        assertEq(token.allowance(alice, bob), 150e18);
    }

    function test_DecreaseAllowance() public {
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(alice);
        token.decreaseAllowance(bob, 30e18);

        assertEq(token.allowance(alice, bob), 70e18);
    }

    function test_Mint() public {
        token.mint(bob, 500e18);

        assertEq(token.balanceOf(bob), 500e18);
        assertEq(token.totalSupply(), 1500e18);
    }

    function test_RevertMintNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(ERC20Mintable.NotOwner.selector);
        token.mint(alice, 100e18);
    }

    function test_Burn() public {
        vm.prank(alice);
        token.burn(100e18);

        assertEq(token.balanceOf(alice), 900e18);
        assertEq(token.totalSupply(), 900e18);
    }

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount <= 1000e18);

        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice), 1000e18 - amount);
        assertEq(token.balanceOf(bob), amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        vm.prank(alice);
        token.approve(bob, amount);

        assertEq(token.allowance(alice, bob), amount);
    }
}

contract ERC20CappedTest is Test {
    ERC20Capped public token;

    function setUp() public {
        token = new ERC20Capped("Capped Token", "CAP", 18, 1_000_000e18);
    }

    function test_Cap() public view {
        assertEq(token.cap(), 1_000_000e18);
    }

    function test_MintWithinCap() public {
        token.mint(address(this), 500_000e18);
        assertEq(token.balanceOf(address(this)), 500_000e18);
    }

    function test_RevertMintExceedsCap() public {
        token.mint(address(this), 500_000e18);

        vm.expectRevert(abi.encodeWithSelector(
            ERC20Capped.CapExceeded.selector,
            1_000_001e18,
            1_000_000e18
        ));
        token.mint(address(this), 500_001e18);
    }
}

contract WETHTest is Test {
    WETH public weth;
    address public alice;

    function setUp() public {
        weth = new WETH();
        alice = makeAddr("alice");
        vm.deal(alice, 10 ether);
    }

    function test_Deposit() public {
        vm.prank(alice);
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(alice), 1 ether);
        assertEq(address(weth).balance, 1 ether);
    }

    function test_DepositViaReceive() public {
        vm.prank(alice);
        (bool success,) = address(weth).call{value: 1 ether}("");
        assertTrue(success);

        assertEq(weth.balanceOf(alice), 1 ether);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        weth.deposit{value: 5 ether}();

        uint256 balanceBefore = alice.balance;
        weth.withdraw(2 ether);

        assertEq(weth.balanceOf(alice), 3 ether);
        assertEq(alice.balance, balanceBefore + 2 ether);
        vm.stopPrank();
    }

    function test_DepositWithdrawEmitsEvents() public {
        vm.startPrank(alice);

        vm.expectEmit(true, false, false, true);
        emit WETH.Deposit(alice, 1 ether);
        weth.deposit{value: 1 ether}();

        vm.expectEmit(true, false, false, true);
        emit WETH.Withdrawal(alice, 1 ether);
        weth.withdraw(1 ether);

        vm.stopPrank();
    }

    function testFuzz_DepositWithdraw(uint96 amount) public {
        vm.assume(amount > 0 && amount <= 10 ether);

        vm.deal(alice, amount);

        vm.startPrank(alice);
        weth.deposit{value: amount}();
        assertEq(weth.balanceOf(alice), amount);

        weth.withdraw(amount);
        assertEq(weth.balanceOf(alice), 0);
        assertEq(alice.balance, amount);
        vm.stopPrank();
    }
}

contract ERC20PermitTest is Test {
    ERC20Permit public token;
    address public owner;
    uint256 public ownerPrivateKey;
    address public spender;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        spender = makeAddr("spender");

        token = new ERC20Permit("Permit Token", "PERMIT", 18);
    }

    function test_Permit() public {
        uint256 value = 100e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        bytes32 structHash = keccak256(
            abi.encode(
                token.PERMIT_TYPEHASH(),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);

        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), 1);
    }

    function test_RevertPermitExpired() public {
        uint256 deadline = block.timestamp - 1;

        vm.expectRevert(ERC20Permit.PermitExpired.selector);
        token.permit(owner, spender, 100e18, deadline, 0, bytes32(0), bytes32(0));
    }
}
