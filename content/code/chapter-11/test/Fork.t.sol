// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

/// @title ForkTest - Fork testing with Foundry
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates testing against forked mainnet state
/// @dev Chapter 11: Testing & Verification - Fork Testing

// Interface for interacting with mainnet contracts
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}

/// @title ForkTest - Testing with forked state
/// @notice Run with: forge test --fork-url $ETH_RPC_URL
contract ForkTest is Test {
    // Mainnet addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EesC4E8D9e4e09f;
    address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Whale addresses (accounts with lots of tokens)
    address constant USDC_WHALE = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;

    IERC20 weth;
    IERC20 usdc;
    IUniswapV2Router router;

    function setUp() public {
        // Create fork - this will use the --fork-url from command line
        // Or you can specify: vm.createSelectFork("mainnet");

        weth = IERC20(WETH);
        usdc = IERC20(USDC);
        router = IUniswapV2Router(UNISWAP_V2_ROUTER);
    }

    /// @notice Test reading mainnet state
    /// @dev Run with: forge test --match-test test_ForkReadState --fork-url $ETH_RPC_URL -vvv
    function test_ForkReadState() public view {
        // Read token metadata
        console.log("WETH symbol:", weth.symbol());
        console.log("USDC decimals:", usdc.decimals());

        // Read balances
        uint256 whaleBalance = usdc.balanceOf(USDC_WHALE);
        console.log("Whale USDC balance:", whaleBalance / 1e6, "USDC");

        assertGt(whaleBalance, 0, "Whale should have USDC");
    }

    /// @notice Test impersonating a whale account
    /// @dev Run with: forge test --match-test test_ForkImpersonateWhale --fork-url $ETH_RPC_URL -vvv
    function test_ForkImpersonateWhale() public {
        address recipient = makeAddr("recipient");

        // Check initial balances
        uint256 whaleBalanceBefore = usdc.balanceOf(USDC_WHALE);
        uint256 recipientBalanceBefore = usdc.balanceOf(recipient);

        console.log("Whale balance before:", whaleBalanceBefore / 1e6);
        console.log("Recipient balance before:", recipientBalanceBefore / 1e6);

        // Impersonate the whale
        vm.prank(USDC_WHALE);
        usdc.transfer(recipient, 1000 * 1e6); // 1000 USDC

        // Verify transfer
        assertEq(usdc.balanceOf(recipient), 1000 * 1e6, "Recipient should have 1000 USDC");
        assertEq(
            usdc.balanceOf(USDC_WHALE),
            whaleBalanceBefore - 1000 * 1e6,
            "Whale balance should decrease"
        );
    }

    /// @notice Test Uniswap swap on fork
    /// @dev Run with: forge test --match-test test_ForkUniswapSwap --fork-url $ETH_RPC_URL -vvv
    function test_ForkUniswapSwap() public {
        // Give ourselves some ETH
        address trader = makeAddr("trader");
        vm.deal(trader, 10 ether);

        // Wrap ETH to WETH
        vm.startPrank(trader);
        IWETH(WETH).deposit{value: 5 ether}();

        // Approve router
        IERC20(WETH).approve(address(router), type(uint256).max);

        // Get expected output
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        uint256[] memory amountsOut = router.getAmountsOut(1 ether, path);
        console.log("Expected USDC for 1 ETH:", amountsOut[1] / 1e6);

        // Perform swap
        uint256 usdcBefore = usdc.balanceOf(trader);
        router.swapExactTokensForTokens(
            1 ether, // amountIn
            amountsOut[1] * 95 / 100, // amountOutMin (5% slippage)
            path,
            trader,
            block.timestamp + 1 hours
        );
        uint256 usdcAfter = usdc.balanceOf(trader);

        vm.stopPrank();

        console.log("USDC received:", (usdcAfter - usdcBefore) / 1e6);
        assertGt(usdcAfter, usdcBefore, "Should receive USDC");
    }

    /// @notice Test at specific block
    /// @dev Run with: forge test --match-test test_ForkAtBlock --fork-url $ETH_RPC_URL --fork-block-number 18000000 -vvv
    function test_ForkAtBlock() public view {
        // State will be from block 18000000 if specified
        console.log("Testing at block:", block.number);
        console.log("Block timestamp:", block.timestamp);

        // Your assertions about historical state
    }

    /// @notice Test with multiple forks
    function test_MultipleForks() public {
        // Note: This requires setting up RPC URLs in foundry.toml

        // Create first fork
        // uint256 mainnetFork = vm.createFork("mainnet");
        // uint256 arbitrumFork = vm.createFork("arbitrum");

        // Switch between forks
        // vm.selectFork(mainnetFork);
        // ... test on mainnet

        // vm.selectFork(arbitrumFork);
        // ... test on arbitrum
    }
}

/// @title ForkPersistentTest - Persistent state across forks
contract ForkPersistentTest is Test {
    // Contract that will be deployed and persist across forks
    MockToken public persistentToken;

    function setUp() public {
        // Deploy our mock contract (will be available on all forks)
        persistentToken = new MockToken();
    }

    /// @notice Show that our deployed contract persists across fork switches
    function test_PersistentContract() public {
        // Mint some tokens
        persistentToken.mint(address(this), 1000e18);
        assertEq(persistentToken.balanceOf(address(this)), 1000e18);

        // Even after fork operations, our contract state remains
        // vm.selectFork(...) wouldn't affect persistentToken
    }
}

/// @title MockToken - Simple token for testing
contract MockToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}
