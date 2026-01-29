# Code Examples

This directory contains runnable code examples from **Mastering EVM (2025 Edition)**.

## Structure

```
code/
├── chapter-03/          # Environment Setup
├── chapter-08/          # Solidity Fundamentals
├── chapter-09/          # Advanced Solidity Patterns
├── chapter-10/          # Smart Contract Security
├── chapter-11/          # Testing & Verification
├── chapter-12/          # Deployment & Upgrades
├── chapter-15/          # Token Standards (ERC-20, ERC-721, ERC-1155, ERC-4626)
├── chapter-16/          # AMM Examples (Constant Product, Concentrated Liquidity)
├── chapter-17/          # Lending Examples (Collateralized Lending, Interest Rates)
├── chapter-18/          # Governance (Governor, Voting Tokens)
├── chapter-19/          # NFT Marketplaces (Listings, Auctions)
├── chapter-21/          # Prediction Markets (Binary Markets, LMSR)
├── chapter-22/          # Oracles (TWAP V2/V3/V4, Chainlink, Aggregators)
├── chapter-24/          # Zero-Knowledge (PLONK, Groth16, ZK Rollups)
└── foundry.toml         # Shared Foundry configuration
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- [Node.js](https://nodejs.org/) 20+ (for TypeScript examples)
- [pnpm](https://pnpm.io/) (recommended) or npm

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone https://github.com/evmbook/evmbook.git
cd evmbook/code

# Install dependencies
pnpm install

# Run all tests
forge test

# Run a specific chapter's examples
cd chapter-15
forge test
```

## Chapter Examples

### Chapter 8: Solidity Fundamentals
Basic Solidity contracts demonstrating core concepts:
- Data types and storage
- Functions and modifiers
- Events and errors
- Inheritance patterns

### Chapter 9: Advanced Solidity Patterns
Advanced patterns for production contracts:
- Proxy patterns (UUPS, Transparent, Beacon)
- Library usage
- Inline assembly
- Gas optimization techniques

### Chapter 10: Smart Contract Security
Security-focused examples:
- Reentrancy prevention
- Access control patterns
- Flash loan integration
- Safe math operations

### Chapter 11: Testing & Verification
Comprehensive testing examples:
- Unit tests with forge
- Fuzz testing
- Invariant testing
- Fork testing

### Chapter 12: Deployment & Upgrades
Deployment and upgrade scripts:
- Deployment scripts
- Contract verification
- Upgrade procedures
- Multi-chain deployment

### Chapter 15: Token Standards
Complete token implementations:
- `ERC20Token.sol` - ERC-20 with Permit, Mintable, Burnable, Capped variants
- `ERC721Token.sol` - ERC-721 with Enumerable, URIStorage extensions
- `ERC1155Token.sol` - Multi-token standard with GameItems example
- `ERC4626Vault.sol` - Tokenized vaults with yield and fee variants
- `WETH` - Wrapped Ether implementation

### Chapter 16: AMM (Automated Market Makers)
DEX implementations:
- `ConstantProductAMM.sol` - Uniswap V2-style x*y=k AMM
  - Liquidity provision and removal
  - Swap with 0.3% fee
  - Price impact calculations
  - Router for slippage protection
- `ConcentratedLiquidityAMM.sol` - Uniswap V3-style concentrated liquidity
  - Tick-based position management
  - Range orders

### Chapter 17: Lending Protocols
Collateralized lending:
- `SimpleLendingPool.sol` - Aave/Compound-style lending pool
  - Supply and borrow mechanics
  - Health factor and liquidations
  - Interest accrual
  - Flash loan provider
- `InterestRateModels.sol` - Interest rate strategies
  - Linear rate model
  - Jump rate model (with kink)
  - Variable rate model
  - Stable rate model

### Chapter 18: Governance
On-chain governance:
- `Governor.sol` - OpenZeppelin-style governor
  - Proposal creation and voting
  - Timelock integration
  - Vote delegation
- `GovernanceToken.sol` - ERC-20 with voting power
  - Checkpoints for historical voting power
  - Delegation

### Chapter 19: NFT Marketplaces
NFT trading:
- `NFTMarketplace.sol` - Basic marketplace
  - Fixed-price listings
  - Offers and counter-offers
  - Platform fees
- `EnglishAuction.sol` - Timed auctions
  - Reserve prices
  - Bid extensions

### Chapter 21: Prediction Markets
Binary outcome markets:
- `SimplePredictionMarket.sol` - LMSR-based prediction market
  - Buy/sell outcome shares
  - Dynamic pricing based on demand
  - Market resolution
- `ConditionalTokens.sol` - Gnosis-style conditional tokens
  - Position splitting and merging
  - Multi-outcome support

### Chapter 22: Oracles
Price feed implementations:
- `TWAPOracleV2.sol` - Uniswap V2 TWAP oracle
  - Cumulative price accumulators
  - Fixed-point math
  - Configurable observation periods
- `TWAPOracleV3.sol` - Uniswap V3 TWAP oracle
  - Built-in observation array
  - Geometric mean TWAP
  - Cardinality management
- `UniswapV4OracleHook.sol` - V4 hooks-based oracle
  - Modular oracle design
  - Truncated oracle variant
- `ChainlinkConsumer.sol` - Chainlink integration
  - Staleness checks
  - Circuit breakers
  - Multi-feed derivation
  - Fallback oracles
- `MultiOracleAggregator.sol` - Oracle aggregation patterns
  - Median oracle
  - Weighted oracle
  - Priority/fallback oracle
  - Deviation circuit breaker

### Chapter 24: Zero-Knowledge Proofs
ZK verification:
- `PlonkVerifier.sol` - PLONK proof verifier (educational)
- `Groth16Verifier.sol` - Groth16 SNARK verifier
  - Pairing-based verification
  - BN254 curve operations
- `ZKRollupVerifier.sol` - ZK rollup state transitions
- `PrivateTransferVerifier.sol` - Privacy-preserving transfers
  - Commitment schemes
  - Nullifier tracking

## Running Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testTransfer

# Run fuzz tests with more runs
forge test --fuzz-runs 10000

# Run fork tests (requires RPC URL)
forge test --fork-url https://eth.llamarpc.com

# Run tests for a specific chapter
cd chapter-22
forge test
```

## TypeScript Examples

TypeScript examples use viem and are located in `typescript/` subdirectories:

```bash
# Install dependencies
pnpm install

# Run TypeScript examples
pnpm tsx chapter-03/typescript/example.ts
```

## Configuration

### foundry.toml

The root `foundry.toml` provides shared configuration:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.26"
optimizer = true
optimizer_runs = 200
```

### Environment Variables

Create a `.env` file for sensitive configuration:

```bash
# RPC URLs for fork testing
MAINNET_RPC_URL=https://eth.llamarpc.com
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY

# Private key for deployment (NEVER commit this)
PRIVATE_KEY=your_private_key_here
```

## Contributing

Found an issue with a code example? Please [open an issue](https://github.com/evmbook/evmbook/issues) or submit a pull request.

## License

Code examples are provided under the MIT License unless otherwise noted.
