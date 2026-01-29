'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import clsx from 'clsx'

// Canonical chapter list from evmbook-v2025 (authoritative source)
// Keep this in sync with content/chapters/_index.json
const chapters = [
  { slug: '00-preface', title: 'Preface', chapter: 0 },
  { slug: '01-evm-today', title: 'The EVM Today', chapter: 1 },
  { slug: '02-how-we-got-here', title: 'How We Got Here', chapter: 2 },
  { slug: '03-environment-setup', title: 'Setting Up Your Environment', chapter: 3 },
  { slug: '04-cryptography', title: 'Cryptography Essentials', chapter: 4 },
  { slug: '05-accounts-wallets', title: 'Accounts, Keys & Wallets', chapter: 5 },
  { slug: '06-transactions-gas', title: 'Transactions & Gas', chapter: 6 },
  { slug: '07-consensus-finality', title: 'Consensus & Finality', chapter: 7 },
  { slug: '08-solidity-fundamentals', title: 'Solidity Fundamentals', chapter: 8 },
  { slug: '09-advanced-solidity', title: 'Advanced Solidity Patterns', chapter: 9 },
  { slug: '10-security', title: 'Smart Contract Security', chapter: 10 },
  { slug: '11-testing-verification', title: 'Testing & Verification', chapter: 11 },
  { slug: '12-deployment-upgrades', title: 'Deployment & Upgrades', chapter: 12 },
  { slug: '13-evm-internals', title: 'EVM Internals', chapter: 13 },
  { slug: '14-gas-optimization', title: 'Gas Optimization', chapter: 14 },
  { slug: '15-token-standards', title: 'Token Standards & Evolution', chapter: 15 },
  { slug: '16-amm-evolution', title: 'AMM Evolution', chapter: 16 },
  { slug: '17-lending-evolution', title: 'Lending & Stablecoin Evolution', chapter: 17 },
  { slug: '18-governance-daos', title: 'Governance & DAOs', chapter: 18 },
  { slug: '19-nft-marketplaces', title: 'NFT Marketplace Evolution', chapter: 19 },
  { slug: '20-launchpads-distribution', title: 'Launchpads & Token Distribution', chapter: 20 },
  { slug: '21-prediction-markets', title: 'Prediction Markets', chapter: 21 },
  { slug: '22-oracles', title: 'Oracles & Data Feeds', chapter: 22 },
  { slug: '23-layer2-solutions', title: 'Layer 2 Solutions', chapter: 23 },
  { slug: '24-zero-knowledge', title: 'Zero-Knowledge Applications', chapter: 24 },
  { slug: '25-regulatory-landscape', title: 'Regulatory Landscape', chapter: 25 },
  { slug: '26-bootstrapping-ecosystem', title: 'Bootstrapping an EVM Ecosystem', chapter: 26 },
  { slug: '27-agentic-development', title: 'Agentic Development', chapter: 27 },
]

// Canonical appendices from evmbook-v2025 (authoritative source)
const appendices = [
  { slug: 'a-fork-history', title: 'Fork History' },
  { slug: 'b-eip-standards', title: 'EIP Standards Reference' },
  { slug: 'c-opcodes', title: 'EVM Opcodes' },
  { slug: 'd-dev-tools', title: 'Development Tools' },
  { slug: 'e-glossary', title: 'Glossary' },
  { slug: 'f-regulatory-timeline', title: 'Regulatory Timeline' },
  { slug: 'g-key-figures', title: 'Key Figures in Blockchain History' },
  { slug: 'h-essential-reading', title: 'Essential Reading List' },
]

export function Sidebar() {
  const pathname = usePathname()
  const [mobileOpen, setMobileOpen] = useState(false)

  const isActive = (slug: string, isAppendix = false) => {
    const path = isAppendix ? `/read/appendix/${slug}` : `/read/${slug}`
    return pathname === path
  }

  const SidebarContent = () => (
    <nav className="space-y-8">
      {/* Chapters */}
      <div>
        <h3 className="text-xs font-bold text-[var(--accent-primary)] uppercase tracking-wider mb-4">
          Chapters
        </h3>
        <ul className="space-y-1">
          {chapters.map((chapter) => (
            <li key={chapter.slug}>
              <Link
                href={`/read/${chapter.slug}`}
                className={clsx(
                  'block px-3 py-2 text-sm transition-all duration-150',
                  isActive(chapter.slug)
                    ? 'bg-[var(--accent-primary)] text-white font-bold'
                    : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--surface-elevated)]'
                )}
                onClick={() => setMobileOpen(false)}
              >
                <span
                  className={clsx(
                    'mr-2',
                    isActive(chapter.slug) ? 'text-white' : 'text-[var(--text-muted)]'
                  )}
                >
                  {chapter.chapter === 0 ? '' : `${chapter.chapter}.`}
                </span>
                {chapter.title}
              </Link>
            </li>
          ))}
        </ul>
      </div>

      {/* Appendices */}
      <div>
        <h3 className="text-xs font-bold text-[var(--accent-tertiary)] uppercase tracking-wider mb-4">
          Appendices
        </h3>
        <ul className="space-y-1">
          {appendices.map((appendix, index) => (
            <li key={appendix.slug}>
              <Link
                href={`/read/appendix/${appendix.slug}`}
                className={clsx(
                  'block px-3 py-2 text-sm transition-all duration-150',
                  isActive(appendix.slug, true)
                    ? 'bg-[var(--accent-tertiary)] text-white font-bold'
                    : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--surface-elevated)]'
                )}
                onClick={() => setMobileOpen(false)}
              >
                <span
                  className={clsx(
                    'mr-2',
                    isActive(appendix.slug, true)
                      ? 'text-white'
                      : 'text-[var(--text-muted)]'
                  )}
                >
                  {String.fromCharCode(65 + index)}.
                </span>
                {appendix.title}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  )

  return (
    <>
      {/* Mobile toggle - Neo-Brutalist */}
      <button
        type="button"
        className="lg:hidden fixed bottom-4 right-4 z-50 bg-[var(--accent-primary)] text-white p-3 border-4 border-[var(--brutalist-black)] shadow-[var(--shadow-brutal)] hover:shadow-[var(--shadow-brutal-sm)] hover:translate-x-[2px] hover:translate-y-[2px] transition-all duration-150"
        onClick={() => setMobileOpen(!mobileOpen)}
      >
        <svg
          className="h-5 w-5"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth="2.5"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
          />
        </svg>
      </button>

      {/* Mobile sidebar */}
      <AnimatePresence>
        {mobileOpen && (
          <div className="lg:hidden fixed inset-0 z-40">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.15 }}
              className="absolute inset-0 bg-[var(--surface-base)]/90 backdrop-blur-sm"
              onClick={() => setMobileOpen(false)}
            />
            <motion.div
              initial={{ x: -288 }}
              animate={{ x: 0 }}
              exit={{ x: -288 }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              className="absolute left-0 top-0 bottom-0 w-72 bg-[var(--glass-bg-strong)] backdrop-blur-xl border-r-4 border-[var(--accent-primary)] p-6 overflow-y-auto"
            >
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-lg font-extrabold uppercase tracking-wider text-[var(--text-primary)]">
                  Contents
                </h2>
                <button
                  type="button"
                  className="text-[var(--text-muted)] hover:text-[var(--accent-primary)] transition-colors duration-150"
                  onClick={() => setMobileOpen(false)}
                >
                  <svg
                    className="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth="2.5"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </div>
              <SidebarContent />
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Desktop sidebar */}
      <aside className="hidden lg:block w-72 flex-shrink-0 border-r-4 border-[var(--accent-primary)]/30 bg-[var(--surface-base)]">
        <div className="sticky top-16 h-[calc(100vh-4rem)] overflow-y-auto p-6">
          <SidebarContent />
        </div>
      </aside>
    </>
  )
}
