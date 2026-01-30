'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'
import { staggerContainer, staggerItem } from '@/lib/animations'
import { BookDisplay } from './BookDisplay'

interface HeroProps {
  stats: {
    chapters: number
    appendices: number
  }
}

export function Hero({ stats }: HeroProps) {
  return (
    <section className="relative overflow-hidden py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="lg:grid lg:grid-cols-2 lg:gap-16 lg:items-center">
          {/* Left column - Text content */}
          <motion.div
            variants={staggerContainer}
            initial="hidden"
            animate="visible"
          >
            {/* Badge - Neo-Brutalist with glass effect */}
            <motion.div variants={staggerItem}>
              <span className="inline-flex items-center px-4 py-2 text-sm font-bold uppercase tracking-wider bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-primary)] text-[var(--accent-primary)] shadow-[var(--shadow-brutal-sm)] mb-8">
                2025 Edition — Free to Read
              </span>
            </motion.div>

            {/* Title - Bold Neo-Brutalist */}
            <motion.h1
              variants={staggerItem}
              className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight leading-[1.1]"
            >
              <span className="text-[var(--text-primary)]">Mastering the</span>
              <span className="block mt-2 text-[var(--accent-primary)]">Ethereum</span>
              <span className="text-[var(--text-primary)]">Virtual Machine</span>
            </motion.h1>

            {/* Subtitle - aligned with Preface differentiators */}
            <motion.p
              variants={staggerItem}
              className="mt-8 text-lg sm:text-xl text-[var(--text-secondary)] max-w-xl leading-relaxed"
            >
              Evolution narratives show how protocols matured. Dependency trees
              map what to build first. Trust assumptions reveal what&apos;s actually
              decentralized. Covering both{' '}
              <span className="text-[var(--eth-brand)] font-semibold">Ethereum</span> and{' '}
              <span className="text-[var(--etc-brand)] font-semibold">
                Ethereum Classic
              </span>
              .
            </motion.p>

            {/* CTA Buttons - Neo-Brutalist */}
            <motion.div
              variants={staggerItem}
              className="mt-10 flex flex-col sm:flex-row items-start gap-4"
            >
              <Link
                href="/read"
                className="inline-flex items-center justify-center px-8 py-4 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-secondary)] shadow-[4px_4px_0_0_var(--accent-secondary)] hover:shadow-[2px_2px_0_0_var(--accent-secondary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-secondary)] hover:text-[#060606] transition-all duration-150"
              >
                Read Online
                <svg
                  className="ml-2 h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth="2.5"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
                  />
                </svg>
              </Link>
{/* <Link
                href="/download"
                className="inline-flex items-center justify-center px-8 py-4 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--text-primary)] shadow-[var(--shadow-brutal)] hover:shadow-[var(--shadow-brutal-sm)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--text-primary)] hover:text-[var(--surface-base)] transition-all duration-150"
              >
                Download PDF
                <svg
                  className="ml-2 h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth="2.5"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                  />
                </svg>
              </Link> */}
            </motion.div>

            {/* Dual chain indicator - Neo-Brutalist */}
            <motion.div
              variants={staggerItem}
              className="mt-10 flex items-center gap-6"
            >
              <div className="flex items-center gap-3">
                <div className="w-4 h-4 bg-[var(--etc-brand)] border-2 border-[var(--surface-base)]" />
                <span className="text-sm font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  ETC (Proof of Work)
                </span>
              </div>
              <div className="w-1 h-6 bg-[var(--text-muted)]" />
              <div className="flex items-center gap-3">
                <div className="w-4 h-4 bg-[var(--eth-brand)] border-2 border-[var(--surface-base)]" />
                <span className="text-sm font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  ETH (Proof of Stake)
                </span>
              </div>
            </motion.div>
          </motion.div>

          {/* Right column - Book display (hidden on mobile) */}
          <div className="hidden lg:flex justify-center items-center mt-16 lg:mt-0">
            <BookDisplay />
          </div>
        </div>

        {/* Stats - Neo-Brutalist boxes with glass effect - Full width below */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="mt-20 grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-3xl mx-auto lg:max-w-none"
        >
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-secondary)] p-4 text-center">
            <div className="text-3xl font-extrabold text-[var(--accent-secondary)]">
              {stats.chapters}
            </div>
            <div className="text-xs uppercase tracking-wider text-[var(--text-muted)] mt-1">
              Chapters
            </div>
          </div>
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-primary)] p-4 text-center">
            <div className="text-3xl font-extrabold text-[var(--accent-primary)]">
              {stats.appendices}
            </div>
            <div className="text-xs uppercase tracking-wider text-[var(--text-muted)] mt-1">
              Appendices
            </div>
          </div>
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-tertiary)] p-4 text-center">
            <div className="text-3xl font-extrabold text-[var(--accent-tertiary)]">100+</div>
            <div className="text-xs uppercase tracking-wider text-[var(--text-muted)] mt-1">
              Code Examples
            </div>
          </div>
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--text-primary)] p-4 text-center">
            <div className="text-3xl font-extrabold text-[var(--text-primary)]">Free</div>
            <div className="text-xs uppercase tracking-wider text-[var(--text-muted)] mt-1">
              Forever
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
