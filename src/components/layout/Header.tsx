'use client'

import Link from 'next/link'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ThemeToggle } from '@/components/theme'

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 w-full border-b-4 border-[var(--accent-primary)] bg-[var(--glass-bg-strong)] backdrop-blur-xl">
      <nav
        className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8"
        aria-label="Top"
      >
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-2 group">
              <span className="text-xl font-extrabold uppercase tracking-wider text-[var(--text-primary)] group-hover:text-[var(--accent-primary)] transition-colors duration-150">
                Mastering EVM
              </span>
            </Link>
          </div>

          {/* Desktop navigation */}
          <div className="hidden md:flex md:items-center md:space-x-8">
            <Link
              href="/read"
              className="text-sm font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
            >
              Read Online
            </Link>
            <Link
              href="/code"
              className="text-sm font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
            >
              Code
            </Link>
            <Link
              href="/diagrams"
              className="text-sm font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
            >
              Diagrams
            </Link>
            <Link
              href="/download"
              className="text-sm font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
            >
              Download
            </Link>
            <a
              href="https://github.com/evmbook"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
            >
              GitHub
            </a>
          </div>

          {/* CTA button and Theme Toggle - Neo-Brutalist */}
          <div className="hidden md:flex md:items-center md:space-x-4">
            <ThemeToggle />
            <Link
              href="/read"
              className="inline-flex items-center justify-center px-6 py-2 text-sm font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-secondary)] shadow-[4px_4px_0_0_var(--accent-secondary)] hover:shadow-[2px_2px_0_0_var(--accent-secondary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-secondary)] hover:text-[#060606] transition-all duration-150"
            >
              Start Reading
            </Link>
          </div>

          {/* Mobile menu button and theme toggle */}
          <div className="flex items-center space-x-2 md:hidden">
            <ThemeToggle />
            <button
              type="button"
              className="inline-flex items-center justify-center p-2 text-[var(--text-secondary)] hover:text-[var(--accent-primary)] transition-colors duration-150"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <span className="sr-only">Open main menu</span>
              {mobileMenuOpen ? (
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
              ) : (
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
                    d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                  />
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.15 }}
              className="md:hidden py-4 space-y-2 overflow-hidden border-t-2 border-[var(--accent-primary)]/30"
            >
              <Link
                href="/read"
                className="block px-3 py-3 text-base font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] hover:bg-[var(--surface-elevated)] transition-all duration-150"
                onClick={() => setMobileMenuOpen(false)}
              >
                Read Online
              </Link>
              <Link
                href="/code"
                className="block px-3 py-3 text-base font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] hover:bg-[var(--surface-elevated)] transition-all duration-150"
                onClick={() => setMobileMenuOpen(false)}
              >
                Code Library
              </Link>
              <Link
                href="/diagrams"
                className="block px-3 py-3 text-base font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] hover:bg-[var(--surface-elevated)] transition-all duration-150"
                onClick={() => setMobileMenuOpen(false)}
              >
                Diagrams
              </Link>
              <Link
                href="/download"
                className="block px-3 py-3 text-base font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] hover:bg-[var(--surface-elevated)] transition-all duration-150"
                onClick={() => setMobileMenuOpen(false)}
              >
                Download
              </Link>
              <a
                href="https://github.com/evmbook"
                target="_blank"
                rel="noopener noreferrer"
                className="block px-3 py-3 text-base font-bold uppercase tracking-wider text-[var(--text-secondary)] hover:text-[var(--accent-primary)] hover:bg-[var(--surface-elevated)] transition-all duration-150"
              >
                GitHub
              </a>
            </motion.div>
          )}
        </AnimatePresence>
      </nav>
    </header>
  )
}
