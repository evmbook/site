// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

/// @title DeployToken - Basic deployment script
/// @author Mastering EVM (2025 Edition)
/// @notice Demonstrates Foundry deployment scripts
/// @dev Chapter 12: Deployment & Upgrades - Deployment Scripts
///
/// Run with:
///   forge script script/Deploy.s.sol:DeployToken --rpc-url $RPC_URL --broadcast
///
/// For simulation (dry run):
///   forge script script/Deploy.s.sol:DeployToken --rpc-url $RPC_URL
///
/// With verification:
///   forge script script/Deploy.s.sol:DeployToken --rpc-url $RPC_URL --broadcast --verify
contract DeployToken is Script {
    function setUp() public {}

    function run() public {
        // Get deployment parameters from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory tokenName = vm.envOr("TOKEN_NAME", string("MyToken"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("MTK"));
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", uint256(1_000_000 ether));

        console.log("Deploying Token...");
        console.log("  Name:", tokenName);
        console.log("  Symbol:", tokenSymbol);
        console.log("  Initial Supply:", initialSupply / 1e18);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token(tokenName, tokenSymbol, initialSupply);

        vm.stopBroadcast();

        console.log("Token deployed at:", address(token));
        console.log("Owner:", token.owner());
    }
}

/// @title DeployTokenDeterministic - CREATE2 deployment for deterministic addresses
/// @notice Deploy to same address on any EVM chain
contract DeployTokenDeterministic is Script {
    // CREATE2 deployer (same on most chains)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bytes32 salt = vm.envOr("SALT", bytes32(uint256(1)));

        string memory tokenName = "MyToken";
        string memory tokenSymbol = "MTK";
        uint256 initialSupply = 1_000_000 ether;

        // Compute expected address before deployment
        bytes memory creationCode =
            abi.encodePacked(type(Token).creationCode, abi.encode(tokenName, tokenSymbol, initialSupply));

        address expectedAddress = computeCreate2Address(salt, keccak256(creationCode));
        console.log("Expected address:", expectedAddress);

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token{salt: salt}(tokenName, tokenSymbol, initialSupply);

        vm.stopBroadcast();

        require(address(token) == expectedAddress, "Address mismatch!");
        console.log("Token deployed at:", address(token));
    }

    function computeCreate2Address(bytes32 salt, bytes32 creationCodeHash)
        internal
        view
        returns (address)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(bytes1(0xff), address(this), salt, creationCodeHash)
                    )
                )
            )
        );
    }
}

/// @title DeployMultipleContracts - Deploy multiple contracts in one script
contract DeployMultipleContracts is Script {
    struct Deployment {
        string name;
        address addr;
    }

    Deployment[] public deployments;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy multiple tokens
        Token tokenA = new Token("Token A", "TKNA", 1_000_000 ether);
        deployments.push(Deployment("Token A", address(tokenA)));

        Token tokenB = new Token("Token B", "TKNB", 2_000_000 ether);
        deployments.push(Deployment("Token B", address(tokenB)));

        Token tokenC = new Token("Token C", "TKNC", 500_000 ether);
        deployments.push(Deployment("Token C", address(tokenC)));

        vm.stopBroadcast();

        // Log all deployments
        console.log("\n=== Deployments ===");
        for (uint256 i = 0; i < deployments.length; i++) {
            console.log(deployments[i].name, ":", deployments[i].addr);
        }
    }
}

/// @title DeployWithVerification - Deployment with automatic verification
/// @notice Shows how to set up verification during deployment
///
/// Run with:
///   forge script script/Deploy.s.sol:DeployWithVerification \
///     --rpc-url $RPC_URL \
///     --broadcast \
///     --verify \
///     --etherscan-api-key $ETHERSCAN_API_KEY
contract DeployWithVerification is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory name = "Verified Token";
        string memory symbol = "VTKN";
        uint256 supply = 1_000_000 ether;

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token(name, symbol, supply);

        vm.stopBroadcast();

        console.log("Token deployed at:", address(token));
        console.log("Verify with:");
        console.log(
            string.concat(
                "  forge verify-contract ",
                vm.toString(address(token)),
                " src/Token.sol:Token --constructor-args $(cast abi-encode \"constructor(string,string,uint256)\" \"",
                name,
                "\" \"",
                symbol,
                "\" ",
                vm.toString(supply),
                ")"
            )
        );
    }
}
