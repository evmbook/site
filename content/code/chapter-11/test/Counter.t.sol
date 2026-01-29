// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

/// @title CounterTest - Basic Foundry testing patterns
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates unit testing with Foundry
/// @dev Chapter 11: Testing & Verification - Basic Unit Tests
contract CounterTest is Test {
    Counter public counter;
    address public owner;
    address public alice;
    address public bob;

    // Events to test
    event CountIncremented(uint256 indexed newCount, address indexed by);
    event CountDecremented(uint256 indexed newCount, address indexed by);
    event CountSet(uint256 indexed newCount, address indexed by);

    /// @notice Runs before each test
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        counter = new Counter();
    }

    // ============ BASIC TESTS ============

    /// @notice Test initial state
    function test_InitialState() public view {
        assertEq(counter.count(), 0, "Initial count should be 0");
        assertEq(counter.owner(), owner, "Owner should be deployer");
    }

    /// @notice Test increment
    function test_Increment() public {
        counter.increment();
        assertEq(counter.count(), 1, "Count should be 1 after increment");

        counter.increment();
        assertEq(counter.count(), 2, "Count should be 2 after second increment");
    }

    /// @notice Test decrement
    function test_Decrement() public {
        counter.increment();
        counter.increment();
        counter.decrement();
        assertEq(counter.count(), 1, "Count should be 1 after decrement");
    }

    /// @notice Test decrement reverts on underflow
    function test_DecrementRevertsOnUnderflow() public {
        vm.expectRevert(Counter.CounterUnderflow.selector);
        counter.decrement();
    }

    /// @notice Test setCount as owner
    function test_SetCount() public {
        counter.setCount(100);
        assertEq(counter.count(), 100, "Count should be 100");
    }

    /// @notice Test setCount reverts for non-owner
    function test_SetCountRevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(Counter.NotOwner.selector);
        counter.setCount(100);
    }

    // ============ EVENT TESTING ============

    /// @notice Test that events are emitted correctly
    function test_IncrementEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit CountIncremented(1, address(this));
        counter.increment();
    }

    /// @notice Test event with different caller
    function test_EventWithDifferentCaller() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit CountIncremented(1, alice);
        counter.increment();
    }

    // ============ USING vm CHEATCODES ============

    /// @notice Test with different msg.sender
    function test_IncrementAsDifferentUser() public {
        vm.prank(alice);
        counter.increment();

        vm.prank(bob);
        counter.increment();

        assertEq(counter.count(), 2);
    }

    /// @notice Test with persistent caller change
    function test_PersistentPrank() public {
        vm.startPrank(alice);

        counter.increment();
        counter.increment();
        counter.increment();

        vm.stopPrank();

        assertEq(counter.count(), 3);
    }

    /// @notice Test with specific block number
    function test_BlockManipulation() public {
        vm.roll(1000); // Set block number to 1000
        assertEq(block.number, 1000);

        vm.warp(1000000); // Set timestamp
        assertEq(block.timestamp, 1000000);
    }

    /// @notice Test with ETH dealing
    function test_DealETH() public {
        vm.deal(alice, 100 ether);
        assertEq(alice.balance, 100 ether);
    }

    // ============ TESTING MULTIPLE SCENARIOS ============

    /// @notice Test incrementBy
    function test_IncrementBy() public {
        counter.incrementBy(5);
        assertEq(counter.count(), 5);

        counter.incrementBy(10);
        assertEq(counter.count(), 15);
    }

    /// @notice Test large increment
    function test_LargeIncrement() public {
        counter.incrementBy(type(uint128).max);
        assertEq(counter.count(), type(uint128).max);
    }

    // ============ USING CONSOLE LOGGING ============

    /// @notice Demonstrate console logging (visible with -vv flag)
    function test_ConsoleLogging() public {
        console.log("Starting test...");
        console.log("Owner address:", owner);

        counter.increment();
        console.log("Count after increment:", counter.count());

        counter.incrementBy(99);
        console.log("Count after incrementBy(99):", counter.count());

        assertEq(counter.count(), 100);
    }

    // ============ GAS TESTING ============

    /// @notice Measure gas for increment
    function test_GasIncrement() public {
        uint256 gasBefore = gasleft();
        counter.increment();
        uint256 gasUsed = gasBefore - gasleft();
        console.log("Gas used for increment:", gasUsed);

        // Assert gas is reasonable (adjust based on actual usage)
        assertLt(gasUsed, 50000, "Gas usage too high");
    }

    // ============ SNAPSHOT AND REVERT ============

    /// @notice Test using snapshots
    function test_SnapshotRevert() public {
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 2);

        // Take snapshot
        uint256 snapshot = vm.snapshotState();

        // Make changes
        counter.incrementBy(100);
        assertEq(counter.count(), 102);

        // Revert to snapshot
        vm.revertToState(snapshot);

        // Back to state at snapshot
        assertEq(counter.count(), 2);
    }

    // ============ LABEL FOR DEBUGGING ============

    /// @notice Test with labeled addresses
    function test_WithLabels() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        vm.prank(alice);
        counter.increment();

        vm.prank(bob);
        counter.increment();

        // Labels appear in traces with -vvvv
    }
}

/// @title CounterFuzzTest - Fuzz testing examples
contract CounterFuzzTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    /// @notice Fuzz test increment with random amounts
    /// @param amount Random value provided by fuzzer
    function testFuzz_IncrementBy(uint256 amount) public {
        // Bound to reasonable values to avoid overflow
        amount = bound(amount, 0, type(uint128).max);

        counter.incrementBy(amount);
        assertEq(counter.count(), amount);
    }

    /// @notice Fuzz test multiple increments
    function testFuzz_MultipleIncrements(uint8 times) public {
        for (uint256 i = 0; i < times; i++) {
            counter.increment();
        }
        assertEq(counter.count(), times);
    }

    /// @notice Fuzz test increment then decrement
    function testFuzz_IncrementDecrement(uint8 increments, uint8 decrements) public {
        // Ensure we don't underflow
        vm.assume(increments >= decrements);

        for (uint256 i = 0; i < increments; i++) {
            counter.increment();
        }

        for (uint256 i = 0; i < decrements; i++) {
            counter.decrement();
        }

        assertEq(counter.count(), increments - decrements);
    }

    /// @notice Fuzz test setCount
    function testFuzz_SetCount(uint256 value) public {
        counter.setCount(value);
        assertEq(counter.count(), value);
    }
}
