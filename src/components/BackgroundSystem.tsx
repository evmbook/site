'use client';

import { motion, useReducedMotion } from 'framer-motion';

/**
 * BackgroundSystem - Sci-Fi Mountain Landscape
 *
 * Visual concept:
 * - Deep teal night sky gradient
 * - Large coral/red moon at horizon
 * - Layered mountain silhouettes creating depth
 * - Road leading to the moon with subtle reflection
 * - Scattered stars in the upper sky
 * - Atmospheric haze near horizon
 */

// Mountain path definitions - SVG viewBox is 0 0 100 100
const MOUNTAIN_PATHS = {
  // Distant mountains - gentle rolling peaks (positioned higher)
  far: 'M0,55 Q5,48 10,50 Q15,42 20,45 Q28,38 35,42 Q42,35 50,38 Q58,32 65,36 Q72,30 80,34 Q88,28 95,32 L100,35 L100,100 L0,100 Z',

  // Mid mountains - more dramatic peaks
  mid: 'M0,62 L8,55 L15,60 L22,48 L30,54 L38,45 L48,52 L55,42 L65,50 L72,44 L80,52 L88,46 L95,55 L100,50 L100,100 L0,100 Z',

  // Near mountains/hills - foreground silhouette
  near: 'M0,75 L10,70 L20,74 L30,68 L45,72 L55,65 L70,70 L80,66 L90,72 L100,68 L100,100 L0,100 Z',
};

export function BackgroundSystem() {
  const reduceMotion = useReducedMotion();

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
    >
      {/* Sky gradient - deep teal to horizon */}
      <div
        className="absolute inset-0"
        style={{
          background: `linear-gradient(180deg,
            #0A1419 0%,
            #0D1A20 25%,
            #0F1E24 45%,
            #152530 65%,
            #1A2830 80%,
            #1E2E38 100%
          )`,
        }}
      />

      {/* Stars layer - scattered dots in upper portion */}
      <div className="absolute inset-0">
        {/* Large stars */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: `
              radial-gradient(1.5px 1.5px at 15% 8%, rgba(255,255,255,0.6), transparent),
              radial-gradient(1px 1px at 35% 15%, rgba(255,255,255,0.4), transparent),
              radial-gradient(1.5px 1.5px at 55% 5%, rgba(255,255,255,0.5), transparent),
              radial-gradient(1px 1px at 75% 12%, rgba(255,255,255,0.4), transparent),
              radial-gradient(1.5px 1.5px at 88% 8%, rgba(255,255,255,0.5), transparent),
              radial-gradient(1px 1px at 25% 22%, rgba(255,255,255,0.3), transparent),
              radial-gradient(1px 1px at 65% 18%, rgba(255,255,255,0.35), transparent),
              radial-gradient(1px 1px at 92% 20%, rgba(255,255,255,0.3), transparent)
            `,
            backgroundSize: '100% 100%',
            opacity: 0.9,
            maskImage: 'linear-gradient(to bottom, black 0%, black 35%, transparent 55%)',
            WebkitMaskImage: 'linear-gradient(to bottom, black 0%, black 35%, transparent 55%)',
          }}
        />
        {/* Small stars - dense field */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: 'radial-gradient(0.5px 0.5px at center, rgba(255,255,255,0.25), transparent)',
            backgroundSize: '45px 35px',
            opacity: 0.7,
            maskImage: 'linear-gradient(to bottom, black 0%, black 30%, transparent 50%)',
            WebkitMaskImage: 'linear-gradient(to bottom, black 0%, black 30%, transparent 50%)',
          }}
        />
      </div>

      {/* Moon - large coral/red sphere at horizon */}
      <div className="absolute inset-0">
        {/* Moon outer atmosphere glow */}
        <motion.div
          className="absolute"
          style={{
            left: '50%',
            top: '42%',
            width: '500px',
            height: '500px',
            transform: 'translate(-50%, -50%)',
            background: 'radial-gradient(circle, rgba(232,90,90,0.08) 0%, rgba(232,90,90,0.03) 40%, transparent 70%)',
          }}
          animate={reduceMotion ? undefined : {
            scale: [1, 1.05, 1],
            opacity: [0.8, 1, 0.8]
          }}
          transition={reduceMotion ? undefined : {
            duration: 15,
            repeat: Infinity,
            ease: 'easeInOut'
          }}
        />

        {/* Moon middle glow */}
        <div
          className="absolute"
          style={{
            left: '50%',
            top: '42%',
            width: '320px',
            height: '320px',
            transform: 'translate(-50%, -50%)',
            background: 'radial-gradient(circle, rgba(255,123,123,0.12) 0%, rgba(232,90,90,0.06) 50%, transparent 75%)',
          }}
        />

        {/* Moon body */}
        <motion.div
          className="absolute rounded-full"
          style={{
            left: '50%',
            top: '42%',
            width: '180px',
            height: '180px',
            transform: 'translate(-50%, -50%)',
            background: `radial-gradient(circle at 40% 35%,
              #FFB4B4 0%,
              #FF9B9B 15%,
              #E85A5A 45%,
              #D04545 70%,
              #B83838 100%
            )`,
            boxShadow: `
              0 0 60px rgba(232,90,90,0.4),
              0 0 120px rgba(232,90,90,0.2),
              inset -15px -10px 40px rgba(0,0,0,0.15)
            `,
          }}
          animate={reduceMotion ? undefined : {
            scale: [1, 1.02, 1]
          }}
          transition={reduceMotion ? undefined : {
            duration: 20,
            repeat: Infinity,
            ease: 'easeInOut'
          }}
        />
      </div>

      {/* Atmospheric haze at horizon */}
      <div
        className="absolute inset-x-0 bottom-0 h-[50%]"
        style={{
          background: `linear-gradient(to top,
            rgba(26,40,48,0.6) 0%,
            rgba(26,40,48,0.3) 30%,
            transparent 70%
          )`,
        }}
      />

      {/* Mountain layers */}
      <svg
        className="absolute inset-0 w-full h-full"
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
      >
        {/* Far mountains - lightest, with subtle moon glow */}
        <defs>
          <linearGradient id="farMountainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#1A2830" />
            <stop offset="100%" stopColor="#152028" />
          </linearGradient>
          <linearGradient id="midMountainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#121C22" />
            <stop offset="100%" stopColor="#0D1518" />
          </linearGradient>
          <linearGradient id="nearMountainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#0A1114" />
            <stop offset="100%" stopColor="#080D0F" />
          </linearGradient>
        </defs>

        <path
          d={MOUNTAIN_PATHS.far}
          fill="url(#farMountainGradient)"
          opacity="0.95"
        />
        <path
          d={MOUNTAIN_PATHS.mid}
          fill="url(#midMountainGradient)"
          opacity="0.98"
        />
        <path
          d={MOUNTAIN_PATHS.near}
          fill="url(#nearMountainGradient)"
        />
      </svg>

      {/* Road surface */}
      <div
        className="absolute bottom-0 left-1/2 -translate-x-1/2"
        style={{
          width: '100%',
          height: '35%',
          clipPath: 'polygon(42% 0%, 58% 0%, 100% 100%, 0% 100%)',
          background: `linear-gradient(to bottom,
            #0C1215 0%,
            #0A0F12 50%,
            #080C0E 100%
          )`,
        }}
      >
        {/* Road center line with glow */}
        <div
          className="absolute left-1/2 -translate-x-1/2 h-full"
          style={{
            width: '2px',
            background: `linear-gradient(to bottom,
              rgba(232,90,90,0.5) 0%,
              rgba(232,90,90,0.2) 50%,
              rgba(232,90,90,0.05) 100%
            )`,
            boxShadow: '0 0 15px rgba(232,90,90,0.3)',
          }}
        />

        {/* Moon reflection on road */}
        <motion.div
          className="absolute left-1/2 -translate-x-1/2"
          style={{
            width: '60px',
            height: '100%',
            background: `linear-gradient(to bottom,
              rgba(232,90,90,0.15) 0%,
              rgba(232,90,90,0.08) 30%,
              rgba(232,90,90,0.02) 70%,
              transparent 100%
            )`,
            filter: 'blur(8px)',
          }}
          animate={reduceMotion ? undefined : {
            opacity: [0.6, 0.9, 0.6]
          }}
          transition={reduceMotion ? undefined : {
            duration: 8,
            repeat: Infinity,
            ease: 'easeInOut'
          }}
        />

        {/* Road edge lines */}
        <div
          className="absolute left-0 h-full"
          style={{
            width: '1px',
            background: 'linear-gradient(to bottom, rgba(168,180,188,0.1), transparent 80%)',
          }}
        />
        <div
          className="absolute right-0 h-full"
          style={{
            width: '1px',
            background: 'linear-gradient(to bottom, rgba(168,180,188,0.1), transparent 80%)',
          }}
        />
      </div>

      {/* Power/telephone poles silhouettes */}
      <div className="absolute inset-0">
        {/* Left pole */}
        <div
          className="absolute"
          style={{
            left: '18%',
            bottom: '25%',
            width: '2px',
            height: '15%',
            background: 'linear-gradient(to bottom, #0A0F12, #080C0E)',
          }}
        >
          <div
            className="absolute top-0 left-1/2 -translate-x-1/2"
            style={{
              width: '20px',
              height: '1px',
              background: '#0A0F12',
            }}
          />
        </div>
        {/* Right pole */}
        <div
          className="absolute"
          style={{
            right: '20%',
            bottom: '22%',
            width: '2px',
            height: '12%',
            background: 'linear-gradient(to bottom, #0A0F12, #080C0E)',
          }}
        >
          <div
            className="absolute top-0 left-1/2 -translate-x-1/2"
            style={{
              width: '16px',
              height: '1px',
              background: '#0A0F12',
            }}
          />
        </div>
      </div>

      {/* Subtle vignette */}
      <div
        className="absolute inset-0"
        style={{
          background: 'radial-gradient(ellipse at 50% 40%, transparent 30%, rgba(8,13,15,0.4) 100%)',
        }}
      />
    </div>
  );
}
