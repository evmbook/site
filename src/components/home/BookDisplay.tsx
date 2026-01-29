'use client'

import { motion } from 'framer-motion'
import Image from 'next/image'

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
          className="relative w-[280px] h-[365px]"
          style={{
            transformStyle: 'preserve-3d',
            transform: 'rotateY(-10deg)',
          }}
        >
          {/* Book spine */}
          <div
            className="absolute left-0 top-0 h-full w-[35px] overflow-hidden"
            style={{
              transform: 'rotateY(-90deg) translateX(-17.5px)',
              transformOrigin: 'left center',
            }}
          >
            <Image
              src="/images/covers/cover-spine.svg"
              alt="Book spine"
              fill
              className="object-cover"
              priority
            />
          </div>

          {/* Book cover front */}
          <div
            className="absolute inset-0 overflow-hidden shadow-2xl"
            style={{
              transform: 'translateZ(17.5px)',
              boxShadow: '8px 8px 0 0 rgba(98, 126, 234, 0.2)',
            }}
          >
            <Image
              src="/images/covers/cover-front.svg"
              alt="Mastering EVM - 2025 Edition"
              fill
              className="object-cover"
              priority
            />
          </div>

          {/* Book pages (side) */}
          <div
            className="absolute top-[2px] right-0 w-[35px] h-[calc(100%-4px)]"
            style={{
              transform: 'rotateY(90deg) translateX(17.5px)',
              transformOrigin: 'right center',
              background:
                'repeating-linear-gradient(to bottom, #F8F8F8 0px, #F8F8F8 1px, #EEEEEE 1px, #EEEEEE 3px)',
              borderTop: '1px solid #DDD',
              borderBottom: '1px solid #DDD',
            }}
          />

          {/* Book back */}
          <div
            className="absolute inset-0 bg-gradient-to-br from-[#0a0a1a] via-[#1a1a3a] to-[#0f0f2f]"
            style={{ transform: 'translateZ(-17.5px)' }}
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
