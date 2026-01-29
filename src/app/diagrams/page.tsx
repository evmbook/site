import { Metadata } from 'next'
import Image from 'next/image'
import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata: Metadata = {
  title: 'Diagrams — Mastering EVM',
  description:
    'Technical diagrams from Mastering EVM illustrating EVM architecture, transaction flows, DeFi protocols, and more.',
}

const diagrams = [
  {
    file: 'ch01-evm-landscape.svg',
    title: 'The EVM Landscape',
    chapter: 1,
    slug: '01-evm-today',
    description: 'Overview of the EVM ecosystem including L1s, L2s, and sidechains.',
  },
  {
    file: 'ch04-cryptography-flow.svg',
    title: 'Cryptography Flow',
    chapter: 4,
    slug: '04-cryptography',
    description: 'Key derivation, signing, and verification in Ethereum.',
  },
  {
    file: 'ch05-account-model.svg',
    title: 'Account Model',
    chapter: 5,
    slug: '05-accounts-wallets',
    description: 'EOAs vs contract accounts, nonces, and state.',
  },
  {
    file: 'ch06-transaction-flow.svg',
    title: 'Transaction Flow',
    chapter: 6,
    slug: '06-transactions-gas',
    description: 'From signing to inclusion: the lifecycle of a transaction.',
  },
  {
    file: 'ch07-pow-vs-pos.svg',
    title: 'PoW vs PoS Consensus',
    chapter: 7,
    slug: '07-consensus-finality',
    description: 'Comparing Proof of Work and Proof of Stake mechanisms.',
  },
  {
    file: 'ch09-proxy-patterns.svg',
    title: 'Proxy Patterns',
    chapter: 9,
    slug: '09-advanced-solidity',
    description: 'UUPS, Transparent, and Beacon proxy patterns.',
  },
  {
    file: 'ch13-evm-architecture.svg',
    title: 'EVM Architecture',
    chapter: 13,
    slug: '13-evm-internals',
    description: 'Stack, memory, storage, and execution context.',
  },
  {
    file: 'ch14-gas-cost-hierarchy.svg',
    title: 'Gas Cost Hierarchy',
    chapter: 14,
    slug: '14-gas-optimization',
    description: 'Relative costs of EVM operations from cheapest to most expensive.',
  },
  {
    file: 'ch16-amm-evolution.svg',
    title: 'AMM Evolution',
    chapter: 16,
    slug: '16-amm-evolution',
    description: 'From constant product to concentrated liquidity.',
  },
  {
    file: 'ch17-lending-protocol.svg',
    title: 'Lending Protocol Architecture',
    chapter: 17,
    slug: '17-lending-evolution',
    description: 'Supply, borrow, liquidation, and interest accrual.',
  },
  {
    file: 'ch18-dao-governance.svg',
    title: 'DAO Governance',
    chapter: 18,
    slug: '18-governance-daos',
    description: 'Proposals, voting, timelock, and execution.',
  },
  {
    file: 'ch22-oracle-architecture.svg',
    title: 'Oracle Architecture',
    chapter: 22,
    slug: '22-oracles',
    description: 'Push vs pull oracles, TWAP, and aggregation patterns.',
  },
  {
    file: 'ch23-l2-architecture.svg',
    title: 'Layer 2 Architecture',
    chapter: 23,
    slug: '23-layer2-solutions',
    description: 'Optimistic and ZK rollup architecture.',
  },
  {
    file: 'ch24-zk-proof-flow.svg',
    title: 'ZK Proof Flow',
    chapter: 24,
    slug: '24-zero-knowledge',
    description: 'Proving, verification, and on-chain settlement.',
  },
  {
    file: 'ch26-dependency-tree.svg',
    title: 'Ecosystem Dependency Tree',
    chapter: 26,
    slug: '26-bootstrapping-ecosystem',
    description: 'What to build first when bootstrapping an EVM ecosystem.',
  },
  {
    file: 'ch26-erc20-defi-stack.svg',
    title: 'ERC-20 DeFi Stack',
    chapter: 26,
    slug: '26-bootstrapping-ecosystem',
    description: 'Building blocks from tokens to complex DeFi.',
  },
  {
    file: 'ch26-erc721-nft-stack.svg',
    title: 'ERC-721 NFT Stack',
    chapter: 26,
    slug: '26-bootstrapping-ecosystem',
    description: 'NFT ecosystem from minting to marketplaces.',
  },
  {
    file: 'ch26-erc1155-multitoken-stack.svg',
    title: 'ERC-1155 Multi-Token Stack',
    chapter: 26,
    slug: '26-bootstrapping-ecosystem',
    description: 'Gaming and multi-token applications.',
  },
]

export default function DiagramsPage() {
  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-1 bg-[var(--surface-base)]">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-16">
          <div className="mb-12">
            <h1 className="text-4xl font-extrabold tracking-tight text-[var(--text-primary)]">
              Diagrams
            </h1>
            <p className="mt-4 text-lg text-[var(--text-secondary)]">
              Technical diagrams from Mastering EVM (2025 Edition). All diagrams are SVG format
              for crisp rendering at any size.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {diagrams.map((diagram) => (
              <div
                key={diagram.file}
                className="border-4 border-[var(--accent-primary)]/30 bg-[var(--surface-elevated)] overflow-hidden hover:border-[var(--accent-primary)] transition-colors duration-150"
              >
                <div className="aspect-[4/3] bg-white p-4 flex items-center justify-center">
                  <Image
                    src={`/diagrams/${diagram.file}`}
                    alt={diagram.title}
                    width={600}
                    height={450}
                    className="max-w-full max-h-full object-contain"
                  />
                </div>
                <div className="p-4 border-t-2 border-[var(--accent-primary)]/20">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs font-bold text-[var(--accent-primary)]">
                      Chapter {diagram.chapter}
                    </span>
                    <Link
                      href={`/read/${diagram.slug}`}
                      className="text-xs text-[var(--link-color)] hover:text-[var(--link-hover)]"
                    >
                      Read chapter →
                    </Link>
                  </div>
                  <h2 className="text-lg font-bold text-[var(--text-primary)]">
                    {diagram.title}
                  </h2>
                  <p className="mt-1 text-sm text-[var(--text-secondary)]">
                    {diagram.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
