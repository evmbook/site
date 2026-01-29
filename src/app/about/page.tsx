import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata = {
  title: 'About',
  description:
    'Learn about Mastering EVM (2025 Edition) by Christopher Mercer, a systems-level guide to the Ethereum Virtual Machine.',
  openGraph: {
    title: 'About Mastering EVM',
    description:
      'Learn about Mastering EVM (2025 Edition) by Christopher Mercer, a systems-level guide to the Ethereum Virtual Machine.',
    url: 'https://masteringevm.com/about',
  },
}

export default function AboutPage() {
  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-1">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 py-16 sm:py-24">
          <div className="prose max-w-none">
            <h1>About Mastering EVM</h1>

            <p className="lead">
              The Complete Guide to the Ethereum Virtual Machine. 28 chapters, 8
              appendices, current through January 2026.
            </p>

            <h2>About the Author</h2>
            <p>
              Christopher Mercer is a blockchain architect and ecosystem builder
              focused on long-lived systems. He has deployed and maintained
              production application protocols and has participated in network
              protocol governance and infrastructure planning across multiple EVM
              networks.
            </p>
            <p>
              His work centers on understanding how decentralized applications
              evolve over time—technically, economically, and operationally—and
              how those dependencies shape what is realistically buildable.
              Mastering EVM reflects this systems-level approach to teaching the
              EVM as it exists today, not as it is often idealized.
            </p>

            <h2>About the Collaboration</h2>
            <p>
              Claude (Anthropic) serves as writing collaborator on this book,
              helping transform Mercer&apos;s vision into prose, researching
              technical details, and maintaining consistency across chapters. The
              human judgment about what matters, the lived experience of building
              on these systems, and the intuition from years in the ecosystem
              remain with the author.
            </p>

            <h2>What Makes This Book Different</h2>

            <h3>Evolution Narratives, Not Just Current State</h3>
            <p>
              Each major application type—AMMs, lending protocols, governance
              systems, marketplaces, launchpads—is presented as an evolution
              story. You&apos;ll understand not just <em>how</em> Uniswap V3
              works, but <em>why</em> it was designed that way, what problems it
              solved that V2 couldn&apos;t, and what tradeoffs it accepted.
            </p>

            <h3>Dependency Trees for Ecosystem Builders</h3>
            <p>
              If you&apos;re bootstrapping an EVM chain or building a DeFi stack,
              you need to know what depends on what. We map these relationships
              explicitly: token standards enable DEXs, DEXs enable price
              discovery, oracles bring external data on-chain, lending protocols
              enable capital efficiency.
            </p>

            <h3>Honest About Trust Assumptions</h3>
            <p>
              Too many projects claim &quot;decentralization&quot; while hiding
              centralized components. We teach you to identify trust
              assumptions—your own and others&apos;—and communicate them honestly.
              Decentralization is bounded from below.
            </p>

            <h2>The Dual-Chain Perspective</h2>
            <p>
              This book covers both Ethereum and Ethereum Classic. These chains
              share the same origin but diverged philosophically after The DAO
              incident in 2016:
            </p>
            <ul>
              <li>
                <strong>Ethereum (ETH)</strong> — The larger ecosystem, now
                proof-of-stake after The Merge
              </li>
              <li>
                <strong>Ethereum Classic (ETC)</strong> — Continuing proof-of-work,
                prioritizing immutability
              </li>
            </ul>
            <p>
              Where implementations differ—consensus mechanisms, fee handling,
              upgrade philosophy—we note it explicitly. Understanding both gives
              you perspective on a fundamental question: when is intervention
              appropriate, and what does &quot;immutability&quot; mean in practice?
            </p>

            <h2>Technical Coverage</h2>
            <p>This book covers the modern EVM landscape:</p>
            <ul>
              <li>
                <strong>Protocol upgrades</strong>: The Merge, EIP-4844, Pectra,
                Olympia (ETC)
              </li>
              <li>
                <strong>Scaling</strong>: L2 explosion, blob transactions, data
                availability
              </li>
              <li>
                <strong>Tooling</strong>: viem, Foundry, wagmi, TypeScript-first
                development
              </li>
              <li>
                <strong>Regulatory</strong>: MiCA, GENIUS Act, Tornado Cash
                sanctions
              </li>
              <li>
                <strong>Applications</strong>: ve(3,3) tokenomics, concentrated
                liquidity, ZK coprocessors
              </li>
            </ul>

            <h2>License</h2>
            <p>
              This work is licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-nc/4.0/"
                target="_blank"
                rel="noopener noreferrer"
              >
                CC BY-NC 4.0
              </a>{' '}
              (Creative Commons Attribution-NonCommercial 4.0 International).
            </p>
            <p>You are free to:</p>
            <ul>
              <li>
                <strong>Share</strong> — copy and redistribute the material in any
                medium or format
              </li>
              <li>
                <strong>Adapt</strong> — remix, transform, and build upon the
                material
              </li>
            </ul>
            <p>Under the following terms:</p>
            <ul>
              <li>
                <strong>Attribution</strong> — Give appropriate credit, provide a
                link to the license, and indicate if changes were made
              </li>
              <li>
                <strong>NonCommercial</strong> — You may not use the material for
                commercial purposes
              </li>
            </ul>

            <h2>Publisher</h2>
            <p>
              Published by White B0x Inc. ISBN (paperback): 979-8-9947278-0-5
            </p>

            <h2>Contributing</h2>
            <p>
              Found an error? Have a suggestion? Contributions are welcome via the{' '}
              <a
                href="https://github.com/evmbook"
                target="_blank"
                rel="noopener noreferrer"
              >
                GitHub repositories
              </a>
              .
            </p>
          </div>

          <div className="mt-12 flex flex-col sm:flex-row justify-center gap-4">
            <Link
              href="/read"
              className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-primary)] shadow-[4px_4px_0_0_var(--accent-primary)] hover:shadow-[2px_2px_0_0_var(--accent-primary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-primary)] hover:text-[#060606] transition-all duration-150"
            >
              Start Reading
            </Link>
            <a
              href="https://github.com/evmbook"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--text-primary)] shadow-[4px_4px_0_0_var(--text-primary)] hover:shadow-[2px_2px_0_0_var(--text-primary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--text-primary)] hover:text-[var(--surface-base)] transition-all duration-150"
            >
              View on GitHub
            </a>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
