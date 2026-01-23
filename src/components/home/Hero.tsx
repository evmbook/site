'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'
import { fadeInUp, staggerContainer, staggerItem } from '@/lib/animations'

export function Hero() {
  return (
    <section className="relative overflow-hidden py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="text-center"
          variants={staggerContainer}
          initial="hidden"
          animate="visible"
        >
          {/* Badge */}
          <motion.div variants={staggerItem}>
            <span className="inline-flex items-center rounded-full px-4 py-1.5 text-sm font-medium bg-dark-purple border border-neon-purple/30 text-neon-cyan mb-8">
              Free &amp; Open Source
            </span>
          </motion.div>

          {/* Title */}
          <motion.h1
            variants={staggerItem}
            className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight"
          >
            <span className="text-text-primary">Mastering the</span>
            <span className="block mt-2 text-gradient-neon">
              Ethereum Virtual Machine
            </span>
          </motion.h1>

          {/* Subtitle */}
          <motion.p
            variants={staggerItem}
            className="mt-6 text-lg sm:text-xl text-text-secondary max-w-3xl mx-auto"
          >
            A comprehensive guide to EVM development. Learn Solidity, smart contract security,
            DeFi protocols, and more. Covering both{' '}
            <span className="text-neon-pink">Ethereum</span> and{' '}
            <span className="text-neon-green">Ethereum Classic</span>.
          </motion.p>

          {/* CTA Buttons */}
          <motion.div
            variants={staggerItem}
            className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4"
          >
            <Link
              href="/read"
              className="inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-neon-green to-neon-yellow px-6 py-3 text-base font-semibold text-void-black shadow-lg shadow-neon-green/25 hover:shadow-xl hover:shadow-neon-green/40 hover:scale-105 transition-all duration-200"
            >
              Read Online
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
              </svg>
            </Link>
            <Link
              href="/download"
              className="inline-flex items-center justify-center rounded-lg bg-transparent border border-neon-blue px-6 py-3 text-base font-semibold text-neon-blue shadow-md shadow-neon-blue/10 hover:bg-neon-blue/10 hover:shadow-lg hover:shadow-neon-blue/25 transition-all duration-200"
            >
              Download PDF
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
              </svg>
            </Link>
          </motion.div>

          {/* Stats */}
          <motion.div
            variants={staggerItem}
            className="mt-16 grid grid-cols-2 sm:grid-cols-4 gap-8 max-w-2xl mx-auto"
          >
            <div className="text-center">
              <div className="text-3xl font-bold text-neon-blue">17</div>
              <div className="text-sm text-text-muted">Chapters</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-neon-orange">5</div>
              <div className="text-sm text-text-muted">Appendices</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-neon-green">100+</div>
              <div className="text-sm text-text-muted">Code Examples</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-neon-yellow">Free</div>
              <div className="text-sm text-text-muted">Forever</div>
            </div>
          </motion.div>

          {/* Dual chain indicator */}
          <motion.div
            variants={staggerItem}
            className="mt-12 flex items-center justify-center gap-8"
          >
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-neon-green shadow-lg shadow-neon-green/50" />
              <span className="text-sm text-text-muted">ETC (PoW)</span>
            </div>
            <div className="w-px h-4 bg-text-muted/30" />
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-neon-pink shadow-lg shadow-neon-pink/50" />
              <span className="text-sm text-text-muted">ETH (PoS)</span>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}
