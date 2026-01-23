'use client'

import { motion } from 'framer-motion'

export function BookDisplay() {
  return (
    <motion.div
      initial={{ opacity: 0, rotateY: -20 }}
      animate={{ opacity: 1, rotateY: 0 }}
      transition={{ duration: 0.8, ease: 'easeOut' }}
      className="relative"
      style={{ perspective: '1000px' }}
    >
      <motion.div
        className="relative"
        style={{ transformStyle: 'preserve-3d' }}
        whileHover={{
          rotateY: -15,
          rotateX: 5,
          transition: { duration: 0.3 },
        }}
      >
        {/* Book container */}
        <div
          className="relative w-[280px] h-[380px]"
          style={{
            transformStyle: 'preserve-3d',
            transform: 'rotateY(-10deg)',
          }}
        >
          {/* Book spine */}
          <div
            className="absolute left-0 top-0 h-full w-[40px] bg-gradient-to-r from-[var(--accent-primary)] to-[var(--accent-primary-dark)]"
            style={{
              transform: 'rotateY(-90deg) translateX(-20px)',
              transformOrigin: 'left center',
            }}
          >
            {/* Spine text */}
            <div
              className="absolute inset-0 flex items-center justify-center"
              style={{ writingMode: 'vertical-rl', textOrientation: 'mixed' }}
            >
              <span className="text-white font-bold text-xs uppercase tracking-[0.2em] rotate-180">
                Mastering EVM
              </span>
            </div>
            {/* Spine lines */}
            <div className="absolute top-4 left-1/2 -translate-x-1/2 w-[2px] h-8 bg-[var(--surface-base)]/30" />
            <div className="absolute bottom-4 left-1/2 -translate-x-1/2 w-[2px] h-8 bg-[var(--surface-base)]/30" />
          </div>

          {/* Book cover front */}
          <div
            className="absolute inset-0 bg-[var(--surface-base)] border-4 border-[var(--accent-primary)]"
            style={{
              transform: 'translateZ(20px)',
              boxShadow: '8px 8px 0 0 rgba(255, 77, 0, 0.3)',
            }}
          >
            {/* Cover design */}
            <div className="h-full flex flex-col p-6">
              {/* Top accent */}
              <div className="flex gap-2 mb-auto">
                <div className="w-3 h-3 bg-[var(--etc-brand)]" />
                <div className="w-3 h-3 bg-[var(--eth-brand)]" />
                <div className="w-3 h-3 bg-[var(--accent-primary)]" />
              </div>

              {/* Title section */}
              <div className="flex-1 flex flex-col justify-center">
                <div className="text-[10px] font-bold uppercase tracking-[0.3em] text-[var(--accent-primary)] mb-3">
                  The Complete Guide to
                </div>
                <h3 className="text-xl font-extrabold uppercase leading-tight text-[var(--text-primary)] tracking-tight">
                  Mastering the
                  <br />
                  <span className="text-[var(--text-primary)]">Ethereum</span><br />
                  <span className="text-[var(--text-primary)]">Virtual Machine</span>
                </h3>
                <div className="mt-4 h-1 w-16 bg-[var(--accent-primary)]" />
                <p className="mt-4 text-[10px] text-[var(--text-primary)] uppercase tracking-wider">
                  <span className="text-[var(--text-primary)]">Dual-Chain Perspective</span><br />
                  <span className="text-[var(--etc-brand)]">ETC | Proof of Work</span><br />
                  <span className="text-[var(--eth-brand)]">ETH | Proof of Stake</span>
                </p>
              </div>

              {/* Author section */}
              <div className="mt-auto pt-4 border-t border-[var(--accent-primary)]/30">
                <a
                  href="https://github.com/claude"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[9px] text-[var(--text-muted)] uppercase tracking-wider hover:text-[var(--link-hover)] transition-colors duration-150"
                >
                  Claude
                </a>
              </div>

              {/* Corner accents */}
              <div className="absolute top-0 right-0 w-6 h-6 border-t-2 border-r-2 border-[var(--eth-brand)]" />
              <div className="absolute bottom-0 left-0 w-6 h-6 border-b-2 border-l-2 border-[var(--accent-tertiary)]" />
            </div>
          </div>

          {/* Book pages (side) */}
          <div
            className="absolute top-[4px] right-0 w-[40px] h-[calc(100%-8px)]"
            style={{
              transform: 'rotateY(90deg) translateX(20px)',
              transformOrigin: 'right center',
              background:
                'repeating-linear-gradient(to bottom, #F5F5F5 0px, #F5F5F5 1px, #E5E5E5 1px, #E5E5E5 3px)',
            }}
          />

          {/* Book back */}
          <div
            className="absolute inset-0 bg-[var(--surface-elevated)] border-4 border-[var(--accent-primary)]/50"
            style={{ transform: 'translateZ(-20px)' }}
          />
        </div>

        {/* Shadow */}
        <div
          className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-[260px] h-[20px] bg-black/30 blur-lg"
          style={{
            transform: 'rotateX(90deg) translateY(10px)',
          }}
        />
      </motion.div>

      {/* Free badge */}
      <motion.div
        initial={{ scale: 0, rotate: -12 }}
        animate={{ scale: 1, rotate: -12 }}
        transition={{ delay: 0.5, type: 'spring', stiffness: 200 }}
        className="absolute -top-4 -right-4 bg-[var(--accent-tertiary)] text-white px-4 py-2 font-bold text-sm uppercase tracking-wider border-4 border-[var(--brutalist-black)] shadow-[4px_4px_0_0_var(--brutalist-black)]"
      >
        Free
      </motion.div>
    </motion.div>
  )
}
