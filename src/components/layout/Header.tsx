'use client'

import Link from 'next/link'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 w-full border-b border-[#00D4D4]/10 bg-[#0A1419]/85 backdrop-blur-xl">
      <nav className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" aria-label="Top">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-2 group">
              <span className="text-xl font-bold text-[#E8E4E0] group-hover:text-[#00D4D4] transition-colors duration-300">
                Mastering EVM
              </span>
            </Link>
          </div>

          {/* Desktop navigation */}
          <div className="hidden md:flex md:items-center md:space-x-8">
            <Link
              href="/read"
              className="text-sm font-medium text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
            >
              Read Online
            </Link>
            <Link
              href="/download"
              className="text-sm font-medium text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
            >
              Download
            </Link>
            <Link
              href="/about"
              className="text-sm font-medium text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
            >
              About
            </Link>
            <a
              href="https://github.com/evmbook"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm font-medium text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
            >
              GitHub
            </a>
          </div>

          {/* CTA button - coral/moon accent */}
          <div className="hidden md:flex">
            <Link
              href="/read"
              className="inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-[#E85A5A]/15 to-[#FF7B7B]/10 border border-[#E85A5A]/20 px-4 py-2 text-sm font-medium text-[#E85A5A] hover:from-[#E85A5A]/25 hover:to-[#FF7B7B]/15 hover:border-[#E85A5A]/30 transition-all duration-200"
            >
              Start Reading
            </Link>
          </div>

          {/* Mobile menu button */}
          <div className="flex md:hidden">
            <button
              type="button"
              className="inline-flex items-center justify-center rounded-md p-2 text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <span className="sr-only">Open main menu</span>
              {mobileMenuOpen ? (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
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
              transition={{ duration: 0.2 }}
              className="md:hidden py-4 space-y-2 overflow-hidden"
            >
              <Link
                href="/read"
                className="block px-3 py-2 text-base font-medium text-[#A8B4BC] hover:text-[#00D4D4] hover:bg-white/[0.03] rounded-md transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Read Online
              </Link>
              <Link
                href="/download"
                className="block px-3 py-2 text-base font-medium text-[#A8B4BC] hover:text-[#00D4D4] hover:bg-white/[0.03] rounded-md transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Download
              </Link>
              <Link
                href="/about"
                className="block px-3 py-2 text-base font-medium text-[#A8B4BC] hover:text-[#00D4D4] hover:bg-white/[0.03] rounded-md transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                About
              </Link>
              <a
                href="https://github.com/evmbook"
                target="_blank"
                rel="noopener noreferrer"
                className="block px-3 py-2 text-base font-medium text-[#A8B4BC] hover:text-[#00D4D4] hover:bg-white/[0.03] rounded-md transition-colors"
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
