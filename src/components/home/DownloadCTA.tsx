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
          className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-dark-purple via-midnight to-dark-blue border border-neon-purple/20 px-6 py-16 sm:px-16 sm:py-24 text-center"
        >
          {/* Background glow effects */}
          <div className="absolute inset-0 -z-10">
            <div className="absolute top-0 left-1/4 w-[400px] h-[400px] bg-neon-green/10 rounded-full blur-3xl" />
            <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-neon-orange/10 rounded-full blur-3xl" />
          </div>

          <h2 className="text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Take it with you
          </h2>
          <p className="mt-4 text-lg text-text-secondary max-w-2xl mx-auto">
            Download the complete book in PDF or EPUB format. Perfect for offline reading,
            printing, or loading onto your e-reader.
          </p>

          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/download"
              className="inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-neon-green to-neon-yellow px-6 py-3 text-base font-semibold text-void-black shadow-lg shadow-neon-green/25 hover:shadow-xl hover:shadow-neon-green/40 hover:scale-105 transition-all duration-200"
            >
              <svg className="mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m.75 12l3 3m0 0l3-3m-3 3v-6m-1.5-9H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
              </svg>
              Download PDF
            </Link>
            <Link
              href="/download"
              className="inline-flex items-center justify-center rounded-lg bg-transparent border border-neon-orange px-6 py-3 text-base font-semibold text-neon-orange hover:bg-neon-orange/10 shadow-md shadow-neon-orange/10 hover:shadow-lg hover:shadow-neon-orange/25 transition-all duration-200"
            >
              <svg className="mr-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
              </svg>
              Download EPUB
            </Link>
          </div>

          <p className="mt-8 text-sm text-text-muted">
            Licensed under CC BY-SA 4.0. Free for personal and commercial use.
          </p>
        </motion.div>
      </div>
    </section>
  )
}
