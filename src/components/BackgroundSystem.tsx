'use client';

import { motion, useReducedMotion } from 'framer-motion';

/**
 * BackgroundSystem - Synthwave Neural Network Background
 * Dual-chain themed: ETC (green) + ETH (pink/purple) = EVM (cyan)
 *
 * Visual concept:
 * - Deep purple-black void as base
 * - Diamond/hexagonal grid pattern
 * - Neural pathways with flowing data
 * - Processing nodes with alternating green/pink glow
 * - Dual orbits representing the two chains
 * - Retrowave scan lines
 */

type Lane = {
  top: string;
  left: string;
  len: string;
  angle: number;
  dur: number;
  delay: number;
  chain: 'etc' | 'eth';
};

type Hub = {
  top: string;
  left: string;
  dur: number;
  delay: number;
  chain: 'etc' | 'eth' | 'evm';
};

export function BackgroundSystem() {
  const reduceMotion = useReducedMotion();

  // Neural pathway lanes - data flowing through the network
  const lanes: readonly Lane[] = [
    // Left side - ETC chain (green)
    { top: '12%', left: '-20%', len: '38%', angle: -5, dur: 11, delay: 0, chain: 'etc' },
    { top: '28%', left: '-24%', len: '42%', angle: 7, dur: 14, delay: 1.5, chain: 'etc' },
    { top: '48%', left: '-18%', len: '36%', angle: -6, dur: 12, delay: 0.8, chain: 'etc' },
    { top: '68%', left: '-22%', len: '40%', angle: 4, dur: 15, delay: 2.2, chain: 'etc' },
    { top: '85%', left: '-26%', len: '44%', angle: -3, dur: 13, delay: 1.0, chain: 'etc' },

    // Right side - ETH chain (pink)
    { top: '18%', left: '58%', len: '44%', angle: 5, dur: 13, delay: 0.5, chain: 'eth' },
    { top: '38%', left: '54%', len: '48%', angle: -7, dur: 16, delay: 2.0, chain: 'eth' },
    { top: '58%', left: '62%', len: '40%', angle: 4, dur: 14, delay: 1.2, chain: 'eth' },
    { top: '78%', left: '56%', len: '46%', angle: -5, dur: 15, delay: 2.8, chain: 'eth' },
  ] as const;

  // Processing hubs - nodes in the neural network
  const hubs: readonly Hub[] = [
    { top: '18%', left: '22%', dur: 6, delay: 0.2, chain: 'etc' },
    { top: '35%', left: '75%', dur: 7, delay: 1.0, chain: 'eth' },
    { top: '52%', left: '28%', dur: 6.5, delay: 0.5, chain: 'etc' },
    { top: '68%', left: '70%', dur: 7.5, delay: 1.5, chain: 'eth' },
    { top: '45%', left: '50%', dur: 8, delay: 0, chain: 'evm' }, // Central EVM hub
  ] as const;

  const getChainColors = (chain: 'etc' | 'eth' | 'evm') => {
    switch (chain) {
      case 'etc':
        return { primary: 'rgba(57, 255, 20, 0.6)', glow: 'rgba(57, 255, 20, 0.25)' };
      case 'eth':
        return { primary: 'rgba(255, 45, 149, 0.6)', glow: 'rgba(255, 45, 149, 0.25)' };
      case 'evm':
        return { primary: 'rgba(0, 245, 255, 0.8)', glow: 'rgba(0, 245, 255, 0.35)' };
    }
  };

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
    >
      {/* Base layer - void gradient */}
      <div
        className="absolute inset-0"
        style={{
          background: `
            linear-gradient(180deg, #0a0a0f 0%, #12091f 50%, #0f0f23 100%)
          `,
        }}
      />

      {/* Atmosphere - multi-colored glows */}
      <motion.div
        className="absolute inset-0"
        style={{
          background: `
            radial-gradient(900px 500px at 15% 20%, rgba(57, 255, 20, 0.06), transparent 55%),
            radial-gradient(800px 500px at 85% 25%, rgba(255, 45, 149, 0.05), transparent 50%),
            radial-gradient(1000px 600px at 50% 80%, rgba(189, 0, 255, 0.08), transparent 60%),
            radial-gradient(700px 400px at 25% 70%, rgba(0, 245, 255, 0.04), transparent 45%),
            radial-gradient(600px 400px at 75% 65%, rgba(255, 45, 149, 0.04), transparent 50%)
          `,
        }}
        animate={reduceMotion ? undefined : { opacity: [0.5, 0.8, 0.5] }}
        transition={
          reduceMotion
            ? undefined
            : { duration: 12, repeat: Infinity, ease: 'easeInOut' }
        }
      />

      {/* Dot lattice */}
      <motion.div
        className="absolute inset-0 opacity-[0.06]"
        style={{
          backgroundImage:
            'radial-gradient(rgba(189, 0, 255, 0.3) 1px, transparent 1px)',
          backgroundSize: '32px 32px',
          maskImage:
            'radial-gradient(ellipse at center, black 35%, transparent 70%)',
          WebkitMaskImage:
            'radial-gradient(ellipse at center, black 35%, transparent 70%)',
        }}
        animate={
          reduceMotion
            ? undefined
            : {
                backgroundPositionX: ['0px', '16px', '0px'],
                backgroundPositionY: ['0px', '16px', '0px'],
              }
        }
        transition={
          reduceMotion
            ? undefined
            : { duration: 20, repeat: Infinity, ease: 'easeInOut' }
        }
      />

      {/* Diamond grid overlay */}
      <div
        className="absolute inset-0 opacity-[0.025]"
        style={{
          backgroundImage: `
            linear-gradient(30deg, rgba(189, 0, 255, 0.4) 1px, transparent 1px),
            linear-gradient(150deg, rgba(189, 0, 255, 0.4) 1px, transparent 1px),
            linear-gradient(270deg, rgba(0, 245, 255, 0.3) 1px, transparent 1px)
          `,
          backgroundSize: '60px 104px',
        }}
      />

      {/* Processing hubs */}
      <div className="absolute inset-0">
        {hubs.map((h, idx) => {
          const colors = getChainColors(h.chain);
          const isCenter = h.chain === 'evm';

          return (
            <motion.div
              key={`hub-${idx}`}
              className="absolute rounded-full"
              style={{
                left: h.left,
                top: h.top,
                width: isCenter ? 12 : 6,
                height: isCenter ? 12 : 6,
                transform: 'translate(-50%, -50%)',
                background: colors.primary,
                boxShadow: `0 0 ${isCenter ? 50 : 25}px ${colors.glow}`,
              }}
              animate={
                reduceMotion ? undefined : { opacity: [0.4, 0.9, 0.4] }
              }
              transition={
                reduceMotion
                  ? undefined
                  : {
                      duration: h.dur,
                      repeat: Infinity,
                      ease: 'easeInOut',
                      delay: h.delay,
                    }
              }
            />
          );
        })}
      </div>

      {/* Neural pathways with data flow */}
      {!reduceMotion &&
        lanes.map((l, idx) => {
          const colors = getChainColors(l.chain);
          const isEth = l.chain === 'eth';
          const from = isEth ? '110%' : '-10%';
          const to = isEth ? '-10%' : '110%';

          return (
            <div
              key={`lane-${idx}`}
              className="absolute"
              style={{
                left: l.left,
                top: l.top,
                width: l.len,
                height: 10,
                transform: `rotate(${l.angle}deg)`,
                transformOrigin: 'left center',
              }}
            >
              {/* Faint lane trace */}
              <div
                className="absolute inset-0"
                style={{
                  background: `linear-gradient(90deg, transparent, ${colors.glow}, transparent)`,
                  filter: 'blur(0.5px)',
                  opacity: 0.3,
                }}
              />

              {/* Traveling data packet */}
              <motion.div
                className="absolute top-1/2 h-[2px] -translate-y-1/2"
                style={{
                  width: '35%',
                  background: isEth
                    ? 'linear-gradient(90deg, transparent, rgba(255, 45, 149, 0.5), rgba(189, 0, 255, 0.6), transparent)'
                    : 'linear-gradient(90deg, transparent, rgba(57, 255, 20, 0.5), rgba(0, 245, 255, 0.4), transparent)',
                  filter: 'blur(0.3px)',
                }}
                initial={{ x: from, opacity: 0 }}
                animate={{ x: [from, to], opacity: [0, 0.8, 0.8, 0] }}
                transition={{
                  duration: l.dur,
                  repeat: Infinity,
                  ease: 'linear',
                  delay: l.delay,
                  times: [0, 0.1, 0.85, 1],
                }}
              />
            </div>
          );
        })}

      {/* Processing pulses around hubs */}
      {!reduceMotion &&
        hubs.map((h, idx) => {
          const colors = getChainColors(h.chain);
          const isCenter = h.chain === 'evm';

          return (
            <motion.div
              key={`pulse-${idx}`}
              className="absolute rounded-full"
              style={{
                left: h.left,
                top: h.top,
                width: isCenter ? 24 : 16,
                height: isCenter ? 24 : 16,
                transform: 'translate(-50%, -50%)',
                border: `1px solid ${colors.primary}`,
                boxShadow: `0 0 15px ${colors.glow}`,
              }}
              animate={{ opacity: [0, 0.6, 0], scale: [1, 3, 4.5] }}
              transition={{
                duration: h.dur,
                repeat: Infinity,
                ease: 'easeOut',
                delay: h.delay + 1,
              }}
            />
          );
        })}

      {/* Dual orbit rings */}
      {!reduceMotion && (
        <>
          {/* ETC orbit (green, clockwise) */}
          <motion.div
            className="absolute left-1/2 top-[45%] h-[180px] w-[180px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-[rgba(57,255,20,0.12)]"
            animate={{ rotate: 360 }}
            transition={{
              duration: 50,
              repeat: Infinity,
              ease: 'linear',
            }}
          >
            <motion.div
              className="absolute -top-1 left-1/2 h-2 w-2 -translate-x-1/2 rounded-full bg-[rgba(57,255,20,0.7)]"
              style={{ boxShadow: '0 0 12px rgba(57, 255, 20, 0.5)' }}
            />
          </motion.div>

          {/* ETH orbit (pink, counter-clockwise) */}
          <motion.div
            className="absolute left-1/2 top-[45%] h-[280px] w-[280px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-[rgba(255,45,149,0.08)]"
            animate={{ rotate: -360 }}
            transition={{
              duration: 75,
              repeat: Infinity,
              ease: 'linear',
            }}
          >
            <motion.div
              className="absolute -top-1 left-1/2 h-1.5 w-1.5 -translate-x-1/2 rounded-full bg-[rgba(255,45,149,0.6)]"
              style={{ boxShadow: '0 0 10px rgba(255, 45, 149, 0.4)' }}
            />
          </motion.div>
        </>
      )}

      {/* Scan shimmer effect */}
      <motion.div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage:
            'linear-gradient(to bottom, transparent, rgba(189, 0, 255, 0.2), transparent)',
          backgroundSize: '100% 300px',
        }}
        animate={
          reduceMotion
            ? undefined
            : { backgroundPositionY: ['0px', '300px'] }
        }
        transition={
          reduceMotion
            ? undefined
            : { duration: 15, repeat: Infinity, ease: 'linear' }
        }
      />

      {/* Bottom glow anchor */}
      <div
        className="absolute inset-x-0 bottom-0 h-[35vh]"
        style={{
          background:
            'radial-gradient(900px 350px at 50% 100%, rgba(189, 0, 255, 0.1), transparent 60%)',
        }}
      />

      {/* Vignette overlay */}
      <div className="absolute inset-0 [background:radial-gradient(circle_at_center,transparent_25%,rgba(10,10,15,0.7)_100%)]" />
    </div>
  );
}
