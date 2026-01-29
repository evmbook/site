// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

/// @title ChainConfig - Multi-chain deployment configuration
/// @author Mastering EVM (2025 Edition)
/// @notice Centralized configuration for multi-chain deployments
/// @dev Chapter 12: Deployment & Upgrades - Multi-Chain Configuration
contract ChainConfig is Script {
    struct NetworkConfig {
        string name;
        uint256 chainId;
        address weth;
        address usdc;
        address uniswapRouter;
        string explorerUrl;
        uint256 confirmations;
    }

    mapping(uint256 => NetworkConfig) public configs;

    constructor() {
        // Ethereum Mainnet
        configs[1] = NetworkConfig({
            name: "Ethereum Mainnet",
            chainId: 1,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            uniswapRouter: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            explorerUrl: "https://etherscan.io",
            confirmations: 2
        });

        // Ethereum Sepolia Testnet
        configs[11155111] = NetworkConfig({
            name: "Sepolia",
            chainId: 11155111,
            weth: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
            usdc: address(0), // Deploy mock
            uniswapRouter: address(0),
            explorerUrl: "https://sepolia.etherscan.io",
            confirmations: 1
        });

        // Arbitrum One
        configs[42161] = NetworkConfig({
            name: "Arbitrum One",
            chainId: 42161,
            weth: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            uniswapRouter: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            explorerUrl: "https://arbiscan.io",
            confirmations: 1
        });

        // Optimism
        configs[10] = NetworkConfig({
            name: "Optimism",
            chainId: 10,
            weth: 0x4200000000000000000000000000000000000006,
            usdc: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85,
            uniswapRouter: 0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2,
            explorerUrl: "https://optimistic.etherscan.io",
            confirmations: 1
        });

        // Base
        configs[8453] = NetworkConfig({
            name: "Base",
            chainId: 8453,
            weth: 0x4200000000000000000000000000000000000006,
            usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            uniswapRouter: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            explorerUrl: "https://basescan.org",
            confirmations: 1
        });

        // Ethereum Classic
        configs[61] = NetworkConfig({
            name: "Ethereum Classic",
            chainId: 61,
            weth: 0x1953cab0E5bFa6D4a9BaD6E05fD46C1CC6527a5a, // WETC
            usdc: address(0), // Not available
            uniswapRouter: address(0), // Different DEX
            explorerUrl: "https://etc.blockscout.com",
            confirmations: 10 // Higher due to PoW
        });

        // Mordor Testnet (ETC)
        configs[63] = NetworkConfig({
            name: "Mordor Testnet",
            chainId: 63,
            weth: address(0),
            usdc: address(0),
            uniswapRouter: address(0),
            explorerUrl: "https://etc-mordor.blockscout.com",
            confirmations: 1
        });
    }

    function getConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory config = configs[block.chainid];
        require(config.chainId != 0, "Unsupported chain");
        return config;
    }

    function getConfig(uint256 chainId) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = configs[chainId];
        require(config.chainId != 0, "Unsupported chain");
        return config;
    }
}

/// @title DeployWithConfig - Example using chain config
contract DeployWithConfig is ChainConfig {
    function run() public {
        NetworkConfig memory config = getConfig();

        console.log("Deploying to:", config.name);
        console.log("Chain ID:", config.chainId);
        console.log("WETH:", config.weth);
        console.log("Confirmations required:", config.confirmations);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Your deployment logic using config.weth, config.usdc, etc.
        // Example:
        // MyProtocol protocol = new MyProtocol(config.weth, config.usdc);

        vm.stopBroadcast();

        console.log("View on explorer:", string.concat(config.explorerUrl, "/address/..."));
    }
}

/// @title DeploymentRegistry - Track deployments across chains
contract DeploymentRegistry is Script {
    struct Deployment {
        uint256 chainId;
        address contractAddress;
        uint256 blockNumber;
        bytes32 txHash;
    }

    // Store deployments in a JSON file
    string constant DEPLOYMENTS_PATH = "deployments/";

    function recordDeployment(string memory contractName, address deployedAddress) internal {
        string memory chainDir = string.concat(DEPLOYMENTS_PATH, vm.toString(block.chainid), "/");
        string memory filePath = string.concat(chainDir, contractName, ".json");

        string memory json = string.concat(
            '{"address":"',
            vm.toString(deployedAddress),
            '","chainId":',
            vm.toString(block.chainid),
            ',"blockNumber":',
            vm.toString(block.number),
            "}"
        );

        vm.writeFile(filePath, json);
        console.log("Deployment recorded to:", filePath);
    }

    function getDeployment(uint256 chainId, string memory contractName)
        internal
        view
        returns (address)
    {
        string memory filePath =
            string.concat(DEPLOYMENTS_PATH, vm.toString(chainId), "/", contractName, ".json");

        string memory json = vm.readFile(filePath);
        // Parse JSON to get address
        // In practice, use a JSON parsing library
        return address(0); // Placeholder
    }
}
