'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import clsx from 'clsx'

// Static chapter list - in production, this could be generated at build time
const chapters = [
  { slug: '00-preface', title: 'Preface', chapter: 0 },
  { slug: '01-what-is-evm', title: 'What is the EVM?', chapter: 1 },
  { slug: '02-getting-started', title: 'Getting Started', chapter: 2 },
  { slug: '03-clients', title: 'EVM Clients', chapter: 3 },
  { slug: '04-cryptography', title: 'Cryptography', chapter: 4 },
  { slug: '05-wallets', title: 'Wallets', chapter: 5 },
  { slug: '06-transactions', title: 'Transactions', chapter: 6 },
  { slug: '07-solidity', title: 'Smart Contracts with Solidity', chapter: 7 },
  { slug: '08-vyper', title: 'Smart Contracts with Vyper', chapter: 8 },
  { slug: '09-security', title: 'Smart Contract Security', chapter: 9 },
  { slug: '10-tokens', title: 'Tokens', chapter: 10 },
  { slug: '11-oracles', title: 'Oracles', chapter: 11 },
  { slug: '12-dapps', title: 'Decentralized Applications', chapter: 12 },
  { slug: '13-evm-deep-dive', title: 'The EVM in Depth', chapter: 13 },
  { slug: '14-consensus', title: 'Consensus Mechanisms', chapter: 14 },
  { slug: '15-defi', title: 'DeFi Protocols', chapter: 15 },
  { slug: '16-scaling', title: 'Scaling Solutions', chapter: 16 },
  { slug: '17-zero-knowledge', title: 'Zero-Knowledge Proofs', chapter: 17 },
]

const appendices = [
  { slug: 'a-fork-history', title: 'Fork History' },
  { slug: 'b-eip-standards', title: 'EIP Standards Reference' },
  { slug: 'c-opcodes', title: 'EVM Opcodes' },
  { slug: 'd-dev-tools', title: 'Development Tools' },
  { slug: 'e-glossary', title: 'Glossary' },
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
        <h3 className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-3">
          Chapters
        </h3>
        <ul className="space-y-1">
          {chapters.map((chapter) => (
            <li key={chapter.slug}>
              <Link
                href={`/read/${chapter.slug}`}
                className={clsx(
                  'block px-3 py-2 text-sm rounded-md transition-all duration-200',
                  isActive(chapter.slug)
                    ? 'bg-dark-purple border-l-2 border-neon-cyan text-neon-cyan font-medium shadow-[inset_0_0_20px_rgba(0,245,255,0.1)]'
                    : 'text-text-secondary hover:text-neon-pink hover:bg-dark-purple/50'
                )}
                onClick={() => setMobileOpen(false)}
              >
                <span className="text-text-muted mr-2">
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
        <h3 className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-3">
          Appendices
        </h3>
        <ul className="space-y-1">
          {appendices.map((appendix, index) => (
            <li key={appendix.slug}>
              <Link
                href={`/read/appendix/${appendix.slug}`}
                className={clsx(
                  'block px-3 py-2 text-sm rounded-md transition-all duration-200',
                  isActive(appendix.slug, true)
                    ? 'bg-dark-purple border-l-2 border-neon-cyan text-neon-cyan font-medium shadow-[inset_0_0_20px_rgba(0,245,255,0.1)]'
                    : 'text-text-secondary hover:text-neon-pink hover:bg-dark-purple/50'
                )}
                onClick={() => setMobileOpen(false)}
              >
                <span className="text-text-muted mr-2">
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
      {/* Mobile toggle */}
      <button
        type="button"
        className="lg:hidden fixed bottom-4 right-4 z-50 bg-gradient-to-r from-neon-pink to-neon-purple text-white p-3 rounded-full shadow-lg shadow-neon-pink/30 hover:shadow-xl hover:shadow-neon-pink/50 transition-all"
        onClick={() => setMobileOpen(!mobileOpen)}
      >
        <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
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
              className="absolute inset-0 bg-void-black/80 backdrop-blur-sm"
              onClick={() => setMobileOpen(false)}
            />
            <motion.div
              initial={{ x: -288 }}
              animate={{ x: 0 }}
              exit={{ x: -288 }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="absolute left-0 top-0 bottom-0 w-72 bg-void-black border-r border-neon-purple/20 p-6 overflow-y-auto"
            >
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-lg font-semibold text-text-primary">Contents</h2>
                <button
                  type="button"
                  className="text-text-muted hover:text-neon-cyan transition-colors"
                  onClick={() => setMobileOpen(false)}
                >
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <SidebarContent />
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Desktop sidebar */}
      <aside className="hidden lg:block w-72 flex-shrink-0 border-r border-neon-purple/20 bg-void-black/50 backdrop-blur-sm">
        <div className="sticky top-16 h-[calc(100vh-4rem)] overflow-y-auto p-6">
          <SidebarContent />
        </div>
      </aside>
    </>
  )
}
