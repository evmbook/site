// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy, UpgradeableTokenV1, UpgradeableTokenV2} from "../src/UpgradeableToken.sol";

/// @title DeployUpgradeableToken - Deploy upgradeable token
/// @author Mastering EVM (2025 Edition)
/// @notice Deploys implementation + proxy
/// @dev Chapter 12: Deployment & Upgrades - Upgradeable Deployment
///
/// Run:
///   forge script script/DeployUpgradeable.s.sol:DeployUpgradeableToken --rpc-url $RPC_URL --broadcast
contract DeployUpgradeableToken is Script {
    function run() public returns (address proxy, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory name = vm.envOr("TOKEN_NAME", string("Upgradeable Token"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("UTKN"));
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", uint256(1_000_000 ether));

        console.log("Deploying Upgradeable Token...");
        console.log("  Name:", name);
        console.log("  Symbol:", symbol);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy implementation
        UpgradeableTokenV1 impl = new UpgradeableTokenV1();
        implementation = address(impl);
        console.log("Implementation V1 deployed at:", implementation);

        // 2. Encode initialization call
        bytes memory initData =
            abi.encodeWithSelector(UpgradeableTokenV1.initialize.selector, name, symbol, initialSupply);

        // 3. Deploy proxy pointing to implementation
        ERC1967Proxy proxyContract = new ERC1967Proxy(implementation, initData);
        proxy = address(proxyContract);
        console.log("Proxy deployed at:", proxy);

        vm.stopBroadcast();

        // Verify deployment
        UpgradeableTokenV1 token = UpgradeableTokenV1(proxy);
        console.log("\n=== Verification ===");
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Version:", token.version());
        console.log("Owner:", token.owner());
        console.log("Total supply:", token.totalSupply() / 1e18);

        return (proxy, implementation);
    }
}

/// @title UpgradeToken - Upgrade existing proxy to V2
/// @notice Upgrade an already-deployed proxy
///
/// Run:
///   PROXY_ADDRESS=0x... forge script script/DeployUpgradeable.s.sol:UpgradeToken --rpc-url $RPC_URL --broadcast
contract UpgradeToken is Script {
    function run() public returns (address newImplementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log("Upgrading proxy at:", proxyAddress);

        // Get current version
        UpgradeableTokenV1 currentToken = UpgradeableTokenV1(proxyAddress);
        console.log("Current version:", currentToken.version());

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation
        UpgradeableTokenV2 implV2 = new UpgradeableTokenV2();
        newImplementation = address(implV2);
        console.log("Implementation V2 deployed at:", newImplementation);

        // 2. Upgrade proxy to new implementation
        currentToken.upgradeTo(newImplementation);
        console.log("Proxy upgraded!");

        vm.stopBroadcast();

        // Verify upgrade
        UpgradeableTokenV2 upgradedToken = UpgradeableTokenV2(proxyAddress);
        console.log("\n=== Post-Upgrade Verification ===");
        console.log("New version:", upgradedToken.version());
        console.log("Name (preserved):", upgradedToken.name());
        console.log("Total supply (preserved):", upgradedToken.totalSupply() / 1e18);
        console.log("Paused:", upgradedToken.paused());

        return newImplementation;
    }
}

/// @title MultiChainDeploy - Deploy to multiple chains
/// @notice Deploy same contract to multiple chains deterministically
///
/// Run for each chain:
///   forge script script/DeployUpgradeable.s.sol:MultiChainDeploy --rpc-url $MAINNET_RPC --broadcast
///   forge script script/DeployUpgradeable.s.sol:MultiChainDeploy --rpc-url $ARBITRUM_RPC --broadcast
///   forge script script/DeployUpgradeable.s.sol:MultiChainDeploy --rpc-url $OPTIMISM_RPC --broadcast
contract MultiChainDeploy is Script {
    // Use same salt across all chains for deterministic addresses
    bytes32 constant SALT = bytes32(uint256(0x1234));

    function run() public returns (address proxy, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying to chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy with CREATE2 for deterministic addresses
        UpgradeableTokenV1 impl = new UpgradeableTokenV1{salt: SALT}();
        implementation = address(impl);

        bytes memory initData =
            abi.encodeWithSelector(UpgradeableTokenV1.initialize.selector, "Multi Chain Token", "MCT", 1_000_000 ether);

        ERC1967Proxy proxyContract = new ERC1967Proxy{salt: SALT}(implementation, initData);
        proxy = address(proxyContract);

        vm.stopBroadcast();

        console.log("Implementation:", implementation);
        console.log("Proxy:", proxy);
        console.log("These addresses will be same on all chains using this script!");

        return (proxy, implementation);
    }
}

/// @title SafeUpgradeWithTimelock - Production-ready upgrade with safety checks
contract SafeUpgradeWithTimelock is Script {
    function run() public {
        // In production, upgrades should:
        // 1. Be proposed through governance
        // 2. Have a timelock delay
        // 3. Be executed by a multisig

        // This script shows the pattern for a timelocked upgrade

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address timelockAddress = vm.envAddress("TIMELOCK_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation (anyone can do this)
        UpgradeableTokenV2 implV2 = new UpgradeableTokenV2();
        console.log("New implementation deployed:", address(implV2));

        // 2. Create upgrade calldata
        bytes memory upgradeCalldata =
            abi.encodeWithSelector(UpgradeableTokenV1.upgradeTo.selector, address(implV2));

        console.log("Upgrade calldata:", vm.toString(upgradeCalldata));

        // 3. This would be scheduled through timelock:
        // ITimelock(timelockAddress).queueTransaction(
        //     proxyAddress,
        //     0,
        //     upgradeCalldata,
        //     block.timestamp + 2 days
        // );

        // 4. After delay, execute:
        // ITimelock(timelockAddress).executeTransaction(
        //     proxyAddress,
        //     0,
        //     upgradeCalldata,
        //     scheduledEta
        // );

        vm.stopBroadcast();

        console.log("\nSchedule this upgrade through your timelock/governance!");
        console.log("Target:", proxyAddress);
        console.log("Value: 0");
        console.log("Data:", vm.toString(upgradeCalldata));
    }
}
