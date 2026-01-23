import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata = {
  title: 'About',
  description: 'Learn about the Mastering EVM project, its origins, and how to contribute to this free EVM development guide.',
  openGraph: {
    title: 'About Mastering EVM',
    description: 'Learn about the Mastering EVM project, its origins, and how to contribute to this free EVM development guide.',
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
              A comprehensive guide to the Ethereum Virtual Machine ecosystem,
              covering both Ethereum (ETH) and Ethereum Classic (ETC).
            </p>

            <h2>A Living Book</h2>
            <p>
              The blockchain space moves at lightning speed. The original <em>Mastering Ethereum</em> was
              written with content reflecting February 2017—a lifetime ago in this industry. Since then,
              we&apos;ve seen The Merge, Layer 2 scaling solutions, the DeFi explosion, and countless protocol
              upgrades.
            </p>
            <p>
              <strong>Mastering EVM</strong> is designed as a living document that evolves with the ecosystem.
              We continuously update content to reflect the current state of EVM development, ensuring you&apos;re
              learning modern practices, not historical artifacts.
            </p>

            <h2>Why This Book?</h2>
            <p>
              The EVM powers one of the most significant technological revolutions of our time.
              Yet comprehensive, up-to-date educational resources remain scarce. We wrote the
              book we wished existed when we started our blockchain journey.
            </p>
            <p>
              This isn&apos;t just another &quot;intro to Ethereum&quot; guide. We go deep. You&apos;ll understand
              not just <em>how</em> to write smart contracts, but <em>why</em> they work the
              way they do.
            </p>

            <h2>The Dual-Chain Perspective</h2>
            <p>
              A unique aspect of this book is our coverage of both:
            </p>
            <ul>
              <li><strong>Ethereum Classic (ETC)</strong> — The open and permissionless continuation of the original smart contract platform, perserving immutability from the July 30, 2015 genesis block. Now positioned as the Ethereum Virtual Machine ecosystem&apos;s Proof-of-Work anchor chain.</li>
              <li><strong>Ethereum (ETH)</strong> — The Ethereum Foundation operated chain which forked from Ethereum Classic at block 1,920,000 on July 20, 2016, innovating and growing to become the most widely used smart contract platform. Now positioned as the Ethereum Virtual Machine ecosystem&apos;s Proof-of-Stake anchor chain.</li>
            </ul>
            <p>
              These two chains share the same origin but have diverged philosophically and
              technically. Understanding both gives you a complete picture of the EVM ecosystem.
            </p>

            <h2>Attribution</h2>
            <p>
              This work is a derivative of <em>Mastering Ethereum</em> by Andreas M. Antonopoulos
              and Gavin Wood, available under the Creative Commons Attribution-ShareAlike 4.0
              International License (CC BY-SA 4.0).
            </p>
            <p>
              Mastering EVM has been substantially rewritten, reorganized, and updated for 2026.
              While we build upon the foundational concepts of the original work, all content has
              been reformulated with:
            </p>
            <ul>
              <li>New examples using modern tooling (Foundry, Hardhat, ethers.js v6)</li>
              <li>Dual-chain (Ethereum + Ethereum Classic) coverage</li>
              <li>Updated content reflecting post-Merge reality</li>
              <li>New chapters on DeFi, L2 scaling, and zero-knowledge proofs</li>
              <li>A different structure and voice</li>
            </ul>

            <h2>License</h2>
            <p>
              This derivative work is licensed under{' '}
              <a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noopener noreferrer">
                CC BY-SA 4.0
              </a>.
            </p>
            <p>You are free to:</p>
            <ul>
              <li><strong>Share</strong> — copy and redistribute the material in any medium or format</li>
              <li><strong>Adapt</strong> — remix, transform, and build upon the material for any purpose, even commercially</li>
            </ul>
            <p>Under the following terms:</p>
            <ul>
              <li><strong>Attribution</strong> — Give appropriate credit, provide a link to the license, and indicate if changes were made</li>
              <li><strong>ShareAlike</strong> — Distribute contributions under the same license</li>
            </ul>

            <h2>Contributing</h2>
            <p>
              Found an error? Have a suggestion? We welcome contributions via our{' '}
              <a href="https://github.com/evmbook" target="_blank" rel="noopener noreferrer">
                GitHub repositories
              </a>.
            </p>
            <ul>
              <li><strong>Content issues</strong> — Report or fix errors in the book content</li>
              <li><strong>Website issues</strong> — Report or fix bugs in the website</li>
              <li><strong>Discussions</strong> — Join the community conversation</li>
            </ul>

            <h2>Support</h2>
            <p>
              This book is free and always will be. If you find it valuable, consider:
            </p>
            <ul>
              <li>Starring our GitHub repositories</li>
              <li>Sharing with fellow developers</li>
              <li>Contributing improvements via pull requests</li>
            </ul>
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
