'use client'

import { motion } from 'framer-motion'
import { staggerContainer, staggerItem } from '@/lib/animations'

const features = [
  {
    name: 'Dual-Chain Coverage',
    description: 'Learn about both Ethereum and Ethereum Classic. Understand the technical and philosophical differences between PoS and PoW.',
    color: 'neon-blue',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5" />
      </svg>
    ),
  },
  {
    name: 'Modern Tooling',
    description: 'Updated for 2025 with Solidity 0.8.x, Foundry, Hardhat, ethers.js v6, and the latest development best practices.',
    color: 'neon-green',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z" />
      </svg>
    ),
  },
  {
    name: 'Security First',
    description: 'Dedicated chapter on smart contract security covering common vulnerabilities, attack vectors, and defensive patterns.',
    color: 'neon-orange',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
      </svg>
    ),
  },
  {
    name: 'DeFi & Scaling',
    description: 'Deep dives into DeFi protocols, L2 scaling solutions, rollups, and zero-knowledge proofs.',
    color: 'neon-yellow',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" />
      </svg>
    ),
  },
  {
    name: 'EVM Internals',
    description: 'Understand how the EVM actually works—opcodes, gas mechanics, memory layout, and execution model.',
    color: 'neon-cyan',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 002.25-2.25V6.75a2.25 2.25 0 00-2.25-2.25H6.75A2.25 2.25 0 004.5 6.75v10.5a2.25 2.25 0 002.25 2.25zm.75-12h9v9h-9v-9z" />
      </svg>
    ),
  },
  {
    name: 'Open Source',
    description: 'Licensed under CC BY-SA 4.0. Read online for free, download in multiple formats, or contribute on GitHub.',
    color: 'neon-green',
    icon: (
      <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
      </svg>
    ),
  },
]

const colorStyles: Record<string, { bg: string; border: string; shadow: string }> = {
  'neon-cyan': {
    bg: 'bg-neon-cyan/10',
    border: 'border-neon-cyan/30 hover:border-neon-cyan/60',
    shadow: 'hover:shadow-[0_0_30px_rgba(0,245,255,0.15)]',
  },
  'neon-green': {
    bg: 'bg-neon-green/10',
    border: 'border-neon-green/30 hover:border-neon-green/60',
    shadow: 'hover:shadow-[0_0_30px_rgba(57,255,20,0.15)]',
  },
  'neon-orange': {
    bg: 'bg-neon-orange/10',
    border: 'border-neon-orange/30 hover:border-neon-orange/60',
    shadow: 'hover:shadow-[0_0_30px_rgba(255,107,0,0.15)]',
  },
  'neon-yellow': {
    bg: 'bg-neon-yellow/10',
    border: 'border-neon-yellow/30 hover:border-neon-yellow/60',
    shadow: 'hover:shadow-[0_0_30px_rgba(255,230,0,0.15)]',
  },
  'neon-blue': {
    bg: 'bg-neon-blue/10',
    border: 'border-neon-blue/30 hover:border-neon-blue/60',
    shadow: 'hover:shadow-[0_0_30px_rgba(0,168,255,0.15)]',
  },
}

export function Features() {
  return (
    <section className="py-24 sm:py-32 bg-section-alt">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="text-center"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
        >
          <h2 className="text-3xl font-bold tracking-tight text-text-primary sm:text-4xl">
            Everything you need to{' '}
            <span className="text-gradient-neon">master the EVM</span>
          </h2>
          <p className="mt-4 text-lg text-text-secondary max-w-2xl mx-auto">
            From fundamentals to advanced topics, this book covers the complete EVM development journey.
          </p>
        </motion.div>

        <motion.div
          className="mt-16 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          {features.map((feature) => {
            const styles = colorStyles[feature.color]
            return (
              <motion.div
                key={feature.name}
                variants={staggerItem}
                whileHover={{ scale: 1.02, y: -4 }}
                className={`relative rounded-xl border ${styles.border} ${styles.shadow} bg-dark-purple/40 backdrop-blur-sm p-8 transition-all duration-300`}
              >
                <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${styles.bg} text-${feature.color}`}>
                  {feature.icon}
                </div>
                <h3 className="mt-4 text-lg font-semibold text-text-primary">
                  {feature.name}
                </h3>
                <p className="mt-2 text-text-secondary text-sm">
                  {feature.description}
                </p>
              </motion.div>
            )
          })}
        </motion.div>
      </div>
    </section>
  )
}
