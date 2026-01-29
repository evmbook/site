/**
 * Flashbots Liquidation Searcher
 *
 * This example demonstrates how to:
 * 1. Monitor lending protocols for liquidatable positions
 * 2. Construct profitable liquidation transactions
 * 3. Submit bundles to Flashbots relay
 * 4. Handle bundle simulation and status checking
 *
 * Prerequisites:
 *   pnpm add viem @flashbots/ethers-provider-bundle
 */

import { createPublicClient, createWalletClient, http, parseAbi, formatEther, parseEther } from 'viem';
import { mainnet } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// ============================================================================
// Configuration
// ============================================================================

const config = {
  // Flashbots relay endpoints
  flashbotsRelay: 'https://relay.flashbots.net',
  flashbotsRpc: 'https://rpc.flashbots.net',

  // Your searcher private key (NEVER commit this!)
  searcherPrivateKey: process.env.SEARCHER_PRIVATE_KEY as `0x${string}`,

  // Contract addresses (mainnet examples)
  contracts: {
    aaveV3Pool: '0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2',
    uniswapRouter: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
    weth: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    usdc: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  },

  // MEV parameters
  minProfitWei: parseEther('0.01'), // Minimum 0.01 ETH profit
  maxGasPrice: parseEther('0.0001'), // Max 100 gwei
};

// ============================================================================
// ABIs (minimal for liquidation)
// ============================================================================

const lendingPoolAbi = parseAbi([
  'function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveAToken) external',
  'function getUserAccountData(address user) external view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor)',
]);

const erc20Abi = parseAbi([
  'function balanceOf(address owner) view returns (uint256)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function transfer(address to, uint256 amount) returns (bool)',
]);

// ============================================================================
// Types
// ============================================================================

interface LiquidatablePosition {
  borrower: string;
  healthFactor: bigint;
  totalDebt: bigint;
  totalCollateral: bigint;
  collateralAsset: string;
  debtAsset: string;
}

interface FlashbotsBundle {
  signedTransactions: string[];
  blockNumber: number;
  minTimestamp?: number;
  maxTimestamp?: number;
}

interface BundleSimulation {
  success: boolean;
  gasUsed: bigint;
  profit: bigint;
  error?: string;
}

// ============================================================================
// Flashbots Bundle Submission
// ============================================================================

/**
 * Sign and submit a bundle to Flashbots relay
 */
async function submitFlashbotsBundle(
  bundle: FlashbotsBundle,
  authSigner: ReturnType<typeof privateKeyToAccount>
): Promise<{ bundleHash: string; success: boolean }> {
  const body = {
    jsonrpc: '2.0',
    id: 1,
    method: 'eth_sendBundle',
    params: [
      {
        txs: bundle.signedTransactions,
        blockNumber: `0x${bundle.blockNumber.toString(16)}`,
        minTimestamp: bundle.minTimestamp,
        maxTimestamp: bundle.maxTimestamp,
      },
    ],
  };

  // Sign the bundle with auth key (Flashbots authentication)
  const signature = await authSigner.signMessage({
    message: JSON.stringify(body),
  });

  const response = await fetch(config.flashbotsRelay, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Flashbots-Signature': `${authSigner.address}:${signature}`,
    },
    body: JSON.stringify(body),
  });

  const result = await response.json();

  if (result.error) {
    console.error('Bundle submission error:', result.error);
    return { bundleHash: '', success: false };
  }

  return {
    bundleHash: result.result?.bundleHash || '',
    success: true,
  };
}

/**
 * Simulate bundle execution via Flashbots
 */
async function simulateBundle(
  bundle: FlashbotsBundle,
  authSigner: ReturnType<typeof privateKeyToAccount>
): Promise<BundleSimulation> {
  const body = {
    jsonrpc: '2.0',
    id: 1,
    method: 'eth_callBundle',
    params: [
      {
        txs: bundle.signedTransactions,
        blockNumber: `0x${bundle.blockNumber.toString(16)}`,
        stateBlockNumber: 'latest',
      },
    ],
  };

  const signature = await authSigner.signMessage({
    message: JSON.stringify(body),
  });

  const response = await fetch(config.flashbotsRelay, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Flashbots-Signature': `${authSigner.address}:${signature}`,
    },
    body: JSON.stringify(body),
  });

  const result = await response.json();

  if (result.error || !result.result) {
    return {
      success: false,
      gasUsed: 0n,
      profit: 0n,
      error: result.error?.message || 'Simulation failed',
    };
  }

  // Calculate profit from simulation results
  const coinbaseDiff = BigInt(result.result.coinbaseDiff || '0');
  const totalGasUsed = BigInt(result.result.totalGasUsed || '0');

  return {
    success: true,
    gasUsed: totalGasUsed,
    profit: coinbaseDiff,
  };
}

/**
 * Check bundle status (was it included?)
 */
async function getBundleStats(
  bundleHash: string,
  blockNumber: number,
  authSigner: ReturnType<typeof privateKeyToAccount>
): Promise<{ isIncluded: boolean; blockNumber?: number }> {
  const body = {
    jsonrpc: '2.0',
    id: 1,
    method: 'flashbots_getBundleStats',
    params: [{ bundleHash, blockNumber }],
  };

  const signature = await authSigner.signMessage({
    message: JSON.stringify(body),
  });

  const response = await fetch(config.flashbotsRelay, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Flashbots-Signature': `${authSigner.address}:${signature}`,
    },
    body: JSON.stringify(body),
  });

  const result = await response.json();

  return {
    isIncluded: result.result?.isSimulated === true,
    blockNumber: result.result?.simulatedAt,
  };
}

// ============================================================================
// Liquidation Logic
// ============================================================================

/**
 * Find liquidatable positions on Aave V3
 */
async function findLiquidatablePositions(
  publicClient: ReturnType<typeof createPublicClient>,
  borrowers: string[]
): Promise<LiquidatablePosition[]> {
  const liquidatable: LiquidatablePosition[] = [];

  for (const borrower of borrowers) {
    try {
      const accountData = await publicClient.readContract({
        address: config.contracts.aaveV3Pool as `0x${string}`,
        abi: lendingPoolAbi,
        functionName: 'getUserAccountData',
        args: [borrower as `0x${string}`],
      });

      const [totalCollateral, totalDebt, , , , healthFactor] = accountData as bigint[];

      // Health factor < 1e18 means liquidatable
      if (healthFactor < parseEther('1')) {
        liquidatable.push({
          borrower,
          healthFactor,
          totalDebt,
          totalCollateral,
          collateralAsset: config.contracts.weth, // Simplified - real impl checks actual collateral
          debtAsset: config.contracts.usdc,
        });

        console.log(`Found liquidatable position: ${borrower}`);
        console.log(`  Health Factor: ${formatEther(healthFactor)}`);
        console.log(`  Total Debt: ${formatEther(totalDebt)}`);
      }
    } catch (error) {
      // Skip positions that error (may not exist)
      continue;
    }
  }

  return liquidatable;
}

/**
 * Build liquidation transaction
 */
async function buildLiquidationTx(
  walletClient: ReturnType<typeof createWalletClient>,
  position: LiquidatablePosition,
  liquidatorContract: string
): Promise<{ signedTx: string; gasEstimate: bigint }> {
  const account = walletClient.account!;

  // Encode liquidation call
  // In practice, this would call your FlashbotsLiquidator contract
  const txData = {
    to: config.contracts.aaveV3Pool as `0x${string}`,
    data: '0x...', // Encoded liquidationCall
    value: 0n,
    gas: 500000n, // Estimated gas
    maxFeePerGas: config.maxGasPrice,
    maxPriorityFeePerGas: parseEther('0.00001'), // 10 gwei tip to builder
    nonce: await walletClient.getTransactionCount({ address: account.address }),
    chainId: mainnet.id,
  };

  // Sign transaction
  const signedTx = await walletClient.signTransaction(txData);

  return {
    signedTx,
    gasEstimate: txData.gas,
  };
}

// ============================================================================
// Main Searcher Loop
// ============================================================================

async function runSearcher() {
  // Initialize clients
  const publicClient = createPublicClient({
    chain: mainnet,
    transport: http(),
  });

  const account = privateKeyToAccount(config.searcherPrivateKey);

  const walletClient = createWalletClient({
    account,
    chain: mainnet,
    transport: http(config.flashbotsRpc), // Use Flashbots RPC for privacy
  });

  console.log('Searcher started');
  console.log(`Address: ${account.address}`);

  // Monitor for new blocks
  publicClient.watchBlockNumber({
    onBlockNumber: async (blockNumber) => {
      console.log(`\nNew block: ${blockNumber}`);

      // In practice, you'd have a list of borrowers to monitor
      // This could come from indexing protocol events
      const borrowersToCheck: string[] = [
        // Add borrower addresses to monitor
      ];

      // Find liquidatable positions
      const positions = await findLiquidatablePositions(publicClient, borrowersToCheck);

      if (positions.length === 0) {
        console.log('No liquidatable positions found');
        return;
      }

      // Build and submit bundles for each position
      for (const position of positions) {
        try {
          // Build liquidation transaction
          const { signedTx, gasEstimate } = await buildLiquidationTx(
            walletClient,
            position,
            '0x...' // Your FlashbotsLiquidator contract
          );

          // Create bundle targeting next block
          const targetBlock = Number(blockNumber) + 1;
          const bundle: FlashbotsBundle = {
            signedTransactions: [signedTx],
            blockNumber: targetBlock,
          };

          // Simulate bundle first
          const simulation = await simulateBundle(bundle, account);

          if (!simulation.success) {
            console.log(`Simulation failed: ${simulation.error}`);
            continue;
          }

          console.log(`Simulation successful:`);
          console.log(`  Gas used: ${simulation.gasUsed}`);
          console.log(`  Profit: ${formatEther(simulation.profit)} ETH`);

          // Check profitability
          if (simulation.profit < config.minProfitWei) {
            console.log('Profit below threshold, skipping');
            continue;
          }

          // Submit bundle
          const { bundleHash, success } = await submitFlashbotsBundle(bundle, account);

          if (success) {
            console.log(`Bundle submitted: ${bundleHash}`);
            console.log(`Target block: ${targetBlock}`);

            // Monitor bundle status
            setTimeout(async () => {
              const stats = await getBundleStats(bundleHash, targetBlock, account);
              if (stats.isIncluded) {
                console.log(`Bundle included in block ${stats.blockNumber}!`);
              } else {
                console.log('Bundle not included (may have been outbid)');
              }
            }, 15000); // Check after ~1 block
          }
        } catch (error) {
          console.error(`Error processing position ${position.borrower}:`, error);
        }
      }
    },
  });
}

// ============================================================================
// MEV-Share Example
// ============================================================================

/**
 * Submit transaction via MEV-Share for partial MEV refund
 *
 * MEV-Share allows users to get back a portion of the MEV
 * extracted from their transaction.
 */
async function submitToMEVShare(
  walletClient: ReturnType<typeof createWalletClient>,
  tx: { to: string; data: string; value: bigint }
) {
  const mevShareEndpoint = 'https://relay.flashbots.net';

  // MEV-Share hint configuration
  const hints = {
    // What to share with searchers
    calldata: true,     // Share calldata
    contractAddress: true, // Share target contract
    logs: true,         // Share emitted logs
    functionSelector: true, // Share function being called
  };

  // Build MEV-Share request
  const mevShareTx = {
    version: 'v0.1',
    inclusion: {
      block: 'latest',
      maxBlock: 'latest + 5',
    },
    body: [
      {
        tx: '0x...', // Signed transaction
        canRevert: false,
      },
    ],
    validity: {
      refund: [
        {
          bodyIdx: 0,
          percent: 90, // 90% of MEV back to user
        },
      ],
    },
    privacy: {
      hints,
    },
  };

  console.log('Submitting to MEV-Share with 90% refund...');

  // Submit to MEV-Share
  // In practice, use Flashbots SDK for proper signing and submission
}

// ============================================================================
// Flashbots Protect Example
// ============================================================================

/**
 * Send transaction via Flashbots Protect RPC
 *
 * This is the simplest way to get MEV protection - just change your RPC endpoint.
 * Transactions are sent directly to block builders, bypassing the public mempool.
 */
async function sendViaFlashbotsProtect() {
  const protectedClient = createWalletClient({
    account: privateKeyToAccount(config.searcherPrivateKey),
    chain: mainnet,
    transport: http('https://rpc.flashbots.net'),
  });

  // Any transaction sent through this client goes to Flashbots Protect
  // It won't appear in the public mempool, protecting from frontrunning/sandwich attacks

  console.log('Transaction will be sent via Flashbots Protect');
  console.log('- No public mempool exposure');
  console.log('- Protected from sandwich attacks');
  console.log('- May take 1-2 blocks longer to include');
}

// ============================================================================
// Run
// ============================================================================

// Uncomment to run searcher
// runSearcher().catch(console.error);

// Export for use as module
export {
  submitFlashbotsBundle,
  simulateBundle,
  getBundleStats,
  findLiquidatablePositions,
  buildLiquidationTx,
  runSearcher,
  submitToMEVShare,
  sendViaFlashbotsProtect,
};
