'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'

export function DownloadCTA() {
  return (
    <section className="py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="relative bg-[var(--surface-base)] border-4 border-[var(--accent-primary)] px-6 py-16 sm:px-16 sm:py-24 text-center"
        >
          {/* Corner accents - Neo-Brutalist */}
          <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-[var(--accent-tertiary)]" />
          <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-[var(--accent-secondary)]" />
          <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-[var(--accent-secondary)]" />
          <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-[var(--accent-tertiary)]" />

          <h2 className="text-3xl font-extrabold tracking-tight text-[var(--text-primary)] sm:text-4xl uppercase">
            Take it with you
          </h2>
          <p className="mt-4 text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
            Download the complete book in PDF or EPUB format. Perfect for
            offline reading, printing, or loading onto your e-reader.
          </p>

          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/download"
              className="inline-flex items-center justify-center px-8 py-4 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-secondary)] shadow-[4px_4px_0_0_var(--accent-secondary)] hover:shadow-[2px_2px_0_0_var(--accent-secondary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-secondary)] hover:text-[#060606] transition-all duration-150"
            >
              <svg
                className="mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth="2.5"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25"
                />
              </svg>
              Download EPUB
            </Link>
            <Link
              href="/download"
              className="inline-flex items-center justify-center px-8 py-4 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--text-primary)] shadow-[var(--shadow-brutal)] hover:shadow-[var(--shadow-brutal-sm)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--text-primary)] hover:text-[var(--surface-base)] transition-all duration-150"
            >
              <svg
                className="mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth="2.5"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m.75 12l3 3m0 0l3-3m-3 3v-6m-1.5-9H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
                />
              </svg>
              Download PDF
            </Link>
          </div>

          <p className="mt-8 text-sm text-[var(--text-muted)] uppercase tracking-wider">
            Licensed under CC BY-SA 4.0 — Free for personal and commercial use
          </p>
        </motion.div>
      </div>
    </section>
  )
}
