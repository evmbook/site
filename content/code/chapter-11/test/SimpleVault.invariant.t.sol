// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVault} from "../src/SimpleVault.sol";

/// @title SimpleVaultHandler - Handler for invariant testing
/// @notice Controls how the fuzzer interacts with the vault
/// @dev Chapter 11: Testing & Verification - Invariant Handler
contract SimpleVaultHandler is Test {
    SimpleVault public vault;

    // Track "ghost" variables for invariant checking
    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    // Track users who have deposited
    address[] public actors;
    mapping(address => bool) public isActor;

    // Current actor for the call
    address internal currentActor;

    modifier useActor(uint256 actorIndexSeed) {
        if (actors.length == 0) {
            // Create first actor if none exist
            currentActor = makeAddr(string(abi.encodePacked("actor", actorIndexSeed)));
            actors.push(currentActor);
            isActor[currentActor] = true;
        } else {
            currentActor = actors[actorIndexSeed % actors.length];
        }
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    constructor(SimpleVault _vault) {
        vault = _vault;
    }

    /// @notice Handler for deposit
    function deposit(uint256 amount, uint256 actorSeed) external useActor(actorSeed) {
        // Bound amount to reasonable range
        amount = bound(amount, 0.001 ether, 10 ether);

        // Deal ETH to the actor
        vm.deal(currentActor, amount);

        // Perform deposit
        vault.deposit{value: amount}();

        // Track for invariants
        ghost_depositSum += amount;
    }

    /// @notice Handler for withdraw
    function withdraw(uint256 amount, uint256 actorSeed) external useActor(actorSeed) {
        // Get current balance
        uint256 balance = vault.balances(currentActor);
        if (balance == 0) return; // Skip if no balance

        // Bound to available balance
        amount = bound(amount, 1, balance);

        // Perform withdrawal
        vault.withdraw(amount);

        // Track for invariants
        ghost_withdrawSum += amount;
    }

    /// @notice Handler for transfer
    function transfer(uint256 amount, uint256 fromSeed, uint256 toSeed) external {
        if (actors.length < 2) {
            // Create second actor if needed
            address newActor = makeAddr(string(abi.encodePacked("actor", toSeed)));
            if (!isActor[newActor]) {
                actors.push(newActor);
                isActor[newActor] = true;
            }
        }

        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];

        if (from == to) return; // Skip same address
        if (vault.balances(from) == 0) return; // Skip if no balance

        amount = bound(amount, 1, vault.balances(from));

        vm.prank(from);
        vault.transfer(to, amount);
    }

    /// @notice Add new actor
    function addActor(uint256 seed) external {
        address newActor = makeAddr(string(abi.encodePacked("actor", seed)));
        if (!isActor[newActor]) {
            actors.push(newActor);
            isActor[newActor] = true;
        }
    }

    /// @notice Get total balance across all actors
    function getTotalUserBalances() external view returns (uint256 total) {
        for (uint256 i = 0; i < actors.length; i++) {
            total += vault.balances(actors[i]);
        }
    }

    /// @notice Get actor count
    function getActorCount() external view returns (uint256) {
        return actors.length;
    }
}

/// @title SimpleVaultInvariantTest - Invariant testing
/// @notice Demonstrates invariant testing patterns with Foundry
/// @dev Chapter 11: Testing & Verification - Invariant Tests
contract SimpleVaultInvariantTest is Test {
    SimpleVault public vault;
    SimpleVaultHandler public handler;

    function setUp() public {
        vault = new SimpleVault();
        handler = new SimpleVaultHandler(vault);

        // Fund the handler so it can deal ETH
        vm.deal(address(handler), 1000 ether);

        // Tell Foundry which contract to target
        targetContract(address(handler));

        // Only call these functions during invariant runs
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = SimpleVaultHandler.deposit.selector;
        selectors[1] = SimpleVaultHandler.withdraw.selector;
        selectors[2] = SimpleVaultHandler.transfer.selector;
        selectors[3] = SimpleVaultHandler.addActor.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @notice Invariant: totalDeposits should equal contract balance
    function invariant_totalDepositsEqualsBalance() public view {
        assertEq(
            vault.totalDeposits(),
            address(vault).balance,
            "totalDeposits should equal ETH balance"
        );
    }

    /// @notice Invariant: sum of all user balances equals totalDeposits
    function invariant_userBalancesSumToTotal() public view {
        uint256 totalUserBalances = handler.getTotalUserBalances();
        assertEq(
            totalUserBalances, vault.totalDeposits(), "User balances should sum to totalDeposits"
        );
    }

    /// @notice Invariant: deposits minus withdrawals equals current total
    function invariant_depositMinusWithdrawEqualsTotal() public view {
        assertEq(
            handler.ghost_depositSum() - handler.ghost_withdrawSum(),
            vault.totalDeposits(),
            "Deposits - withdrawals should equal total"
        );
    }

    /// @notice Invariant: no individual balance exceeds total
    function invariant_noBalanceExceedsTotal() public view {
        uint256 actorCount = handler.getActorCount();
        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actors(i);
            assertLe(
                vault.balances(actor),
                vault.totalDeposits(),
                "No balance should exceed total"
            );
        }
    }

    /// @notice Call summary for debugging
    function invariant_callSummary() public view {
        console.log("Total actors:", handler.getActorCount());
        console.log("Total deposits:", handler.ghost_depositSum());
        console.log("Total withdrawals:", handler.ghost_withdrawSum());
        console.log("Current total:", vault.totalDeposits());
    }
}
