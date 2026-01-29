import { Metadata } from 'next'
import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata: Metadata = {
  title: 'Code Library — Mastering EVM',
  description:
    'Runnable Solidity and TypeScript code examples from Mastering EVM. Token standards, AMMs, lending protocols, governance, and more.',
}

const codeExamples = [
  {
    chapter: 8,
    slug: '08-solidity-fundamentals',
    title: 'Solidity Fundamentals',
    description: 'Core Solidity concepts: data types, functions, modifiers, events, and inheritance.',
    files: ['Counter.sol', 'DataTypes.sol', 'Visibility.sol', 'Modifiers.sol', 'ErrorHandling.sol', 'Inheritance.sol'],
  },
  {
    chapter: 9,
    slug: '09-advanced-solidity',
    title: 'Advanced Solidity Patterns',
    description: 'Proxy patterns, libraries, inline assembly, and gas optimization techniques.',
    files: ['ProxyPatterns.sol', 'Libraries.sol', 'Assembly.sol', 'GasPatterns.sol'],
  },
  {
    chapter: 10,
    slug: '10-security',
    title: 'Smart Contract Security',
    description: 'Security patterns: reentrancy prevention, access control, flash loan integration.',
    files: ['Reentrancy.sol', 'AccessControl.sol', 'CommonVulnerabilities.sol', 'FlashLoanSecurity.sol'],
  },
  {
    chapter: 11,
    slug: '11-testing-verification',
    title: 'Testing & Verification',
    description: 'Unit tests, fuzz testing, invariant testing, and fork testing with Foundry.',
    files: ['Counter.t.sol', 'Fork.t.sol', 'SimpleVault.invariant.t.sol'],
  },
  {
    chapter: 12,
    slug: '12-deployment-upgrades',
    title: 'Deployment & Upgrades',
    description: 'Deployment scripts, contract verification, and upgrade procedures.',
    files: ['Deploy.s.sol', 'DeployUpgradeable.s.sol', 'MultiChainConfig.s.sol', 'UpgradeableToken.sol'],
  },
  {
    chapter: 15,
    slug: '15-token-standards',
    title: 'Token Standards',
    description: 'Complete ERC-20, ERC-721, ERC-1155, and ERC-4626 vault implementations.',
    files: ['ERC20Token.sol', 'ERC721Token.sol', 'ERC1155Token.sol', 'ERC4626Vault.sol'],
  },
  {
    chapter: 16,
    slug: '16-amm-evolution',
    title: 'AMM (Automated Market Makers)',
    description: 'Uniswap V2-style constant product and V3-style concentrated liquidity AMMs.',
    files: ['ConstantProductAMM.sol', 'ConcentratedLiquidityAMM.sol'],
  },
  {
    chapter: 17,
    slug: '17-lending-evolution',
    title: 'Lending Protocols',
    description: 'Collateralized lending pools with liquidations, interest models, and flash loans.',
    files: ['SimpleLendingPool.sol', 'InterestRateModels.sol', 'FlashLoanArbitrage.sol', 'FlashbotsLiquidator.sol'],
  },
  {
    chapter: 18,
    slug: '18-governance-daos',
    title: 'Governance & DAOs',
    description: 'On-chain governance with proposals, voting, and timelock integration.',
    files: ['Governor.sol'],
  },
  {
    chapter: 19,
    slug: '19-nft-marketplaces',
    title: 'NFT Marketplaces',
    description: 'NFT marketplace with listings, offers, and platform fees.',
    files: ['NFTMarketplace.sol'],
  },
  {
    chapter: 21,
    slug: '21-prediction-markets',
    title: 'Prediction Markets',
    description: 'LMSR-based prediction markets with dynamic pricing.',
    files: ['PredictionMarket.sol'],
  },
  {
    chapter: 22,
    slug: '22-oracles',
    title: 'Oracles & Data Feeds',
    description: 'TWAP oracles, Chainlink integration, and multi-oracle aggregation patterns.',
    files: ['TWAPOracleV2.sol', 'TWAPOracleV3.sol', 'UniswapV4OracleHook.sol', 'ChainlinkConsumer.sol', 'MultiOracleAggregator.sol'],
  },
  {
    chapter: 24,
    slug: '24-zero-knowledge',
    title: 'Zero-Knowledge Proofs',
    description: 'ZK verification contracts for PLONK, Groth16, and rollup state transitions.',
    files: ['ZKVerifier.sol'],
  },
]

export default function CodeLibraryPage() {
  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-1 bg-[var(--surface-base)]">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 py-16">
          <div className="mb-12">
            <h1 className="text-4xl font-extrabold tracking-tight text-[var(--text-primary)]">
              Code Library
            </h1>
            <p className="mt-4 text-lg text-[var(--text-secondary)]">
              Runnable Solidity and TypeScript examples from Mastering EVM (2025 Edition).
              All code is tested with Foundry and follows modern best practices.
            </p>
            <div className="mt-6 flex items-center gap-4 text-sm">
              <span className="px-3 py-1 bg-[var(--accent-primary)]/20 text-[var(--accent-primary)] font-medium border border-[var(--accent-primary)]/30">
                Solidity 0.8.26+
              </span>
              <span className="px-3 py-1 bg-[var(--accent-tertiary)]/20 text-[var(--accent-tertiary)] font-medium border border-[var(--accent-tertiary)]/30">
                Foundry
              </span>
              <span className="px-3 py-1 bg-[var(--accent-secondary)]/20 text-[var(--accent-secondary)] font-medium border border-[var(--accent-secondary)]/30">
                TypeScript
              </span>
            </div>
          </div>

          <div className="space-y-6">
            {codeExamples.map((example) => (
              <div
                key={example.chapter}
                className="border-4 border-[var(--accent-primary)]/30 bg-[var(--surface-elevated)] p-6 hover:border-[var(--accent-primary)] transition-colors duration-150"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-sm font-bold text-[var(--accent-primary)]">
                        Chapter {example.chapter}
                      </span>
                      <Link
                        href={`/read/${example.slug}`}
                        className="text-xs text-[var(--link-color)] hover:text-[var(--link-hover)]"
                      >
                        Read chapter →
                      </Link>
                    </div>
                    <h2 className="text-xl font-bold text-[var(--text-primary)]">
                      {example.title}
                    </h2>
                    <p className="mt-2 text-[var(--text-secondary)]">
                      {example.description}
                    </p>
                  </div>
                </div>
                <div className="mt-4 flex flex-wrap gap-2">
                  {example.files.map((file) => (
                    <code
                      key={file}
                      className="px-2 py-1 text-xs bg-[var(--surface-base)] text-[var(--text-muted)] border border-[var(--text-muted)]/20 font-mono"
                    >
                      {file}
                    </code>
                  ))}
                </div>
                <div className="mt-4">
                  <a
                    href={`https://github.com/evmbook/evmbook/tree/main/code/chapter-${String(example.chapter).padStart(2, '0')}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center text-sm font-medium text-[var(--link-color)] hover:text-[var(--link-hover)]"
                  >
                    View on GitHub
                    <svg className="ml-1 h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                    </svg>
                  </a>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-12 p-6 border-4 border-[var(--accent-tertiary)]/30 bg-[var(--surface-elevated)]">
            <h2 className="text-lg font-bold text-[var(--text-primary)] mb-4">
              Running the Examples
            </h2>
            <pre className="bg-[var(--surface-base)] p-4 text-sm overflow-x-auto font-mono text-[var(--text-secondary)]">
{`# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and run tests
git clone https://github.com/evmbook/evmbook.git
cd evmbook/code
forge test`}
            </pre>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
