/**
 * Framer Motion Animation Variants
 * Reusable animation presets for Mastering EVM
 */

import type { Variants, Transition } from 'framer-motion';

// Default transition settings
export const defaultTransition: Transition = {
  duration: 0.5,
  ease: [0.25, 0.1, 0.25, 1],
};

export const springTransition: Transition = {
  type: 'spring',
  stiffness: 100,
  damping: 15,
};

// Fade in from bottom
export const fadeInUp: Variants = {
  hidden: {
    opacity: 0,
    y: 30,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: defaultTransition,
  },
};

// Fade in from left
export const fadeInLeft: Variants = {
  hidden: {
    opacity: 0,
    x: -30,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: defaultTransition,
  },
};

// Fade in from right
export const fadeInRight: Variants = {
  hidden: {
    opacity: 0,
    x: 30,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: defaultTransition,
  },
};

// Scale in
export const scaleIn: Variants = {
  hidden: {
    opacity: 0,
    scale: 0.8,
  },
  visible: {
    opacity: 1,
    scale: 1,
    transition: springTransition,
  },
};

// Stagger container
export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.1,
    },
  },
};

// Stagger item
export const staggerItem: Variants = {
  hidden: {
    opacity: 0,
    y: 20,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: defaultTransition,
  },
};

// Pulse animation
export const pulse: Variants = {
  initial: { scale: 1, opacity: 0.5 },
  animate: {
    scale: [1, 1.1, 1],
    opacity: [0.5, 1, 0.5],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

// Float animation
export const float: Variants = {
  animate: {
    y: [0, -10, 0],
    transition: {
      duration: 3,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

// Rotate continuous
export const rotateContinuous: Variants = {
  animate: {
    rotate: 360,
    transition: {
      duration: 60,
      repeat: Infinity,
      ease: 'linear',
    },
  },
};

// Section reveal
export const sectionReveal: Variants = {
  hidden: {
    opacity: 0,
    y: 50,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: 'easeOut',
    },
  },
};

// Card hover effect
export const cardHover = {
  rest: {
    scale: 1,
    y: 0,
    transition: { duration: 0.2 },
  },
  hover: {
    scale: 1.02,
    y: -4,
    transition: { duration: 0.2 },
  },
};

// Button press effect
export const buttonPress = {
  rest: { scale: 1 },
  pressed: { scale: 0.95 },
  hover: { scale: 1.02 },
};

// Viewport settings for scroll-triggered animations
export const viewportSettings = {
  once: true,
  amount: 0.3,
  margin: '-50px',
};

// SVG path drawing animation
export const pathDraw: Variants = {
  hidden: {
    pathLength: 0,
    opacity: 0,
  },
  visible: {
    pathLength: 1,
    opacity: 1,
    transition: {
      pathLength: { duration: 1.5, ease: 'easeInOut' },
      opacity: { duration: 0.3 },
    },
  },
};

// Glow pulse
export const glowPulse: Variants = {
  animate: {
    boxShadow: [
      '0 0 0 0 rgba(0, 245, 255, 0)',
      '0 0 20px 10px rgba(0, 245, 255, 0.3)',
      '0 0 0 0 rgba(0, 245, 255, 0)',
    ],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

// Neon flicker (synthwave effect)
export const neonFlicker: Variants = {
  animate: {
    opacity: [1, 0.8, 1, 0.9, 1],
    transition: {
      duration: 0.5,
      repeat: Infinity,
      repeatDelay: 3,
      ease: 'easeInOut',
    },
  },
};

// Orbit animation (for background)
export const orbit = (duration: number, reverse: boolean = false): Variants => ({
  animate: {
    rotate: reverse ? -360 : 360,
    transition: {
      duration,
      repeat: Infinity,
      ease: 'linear',
    },
  },
});

// Breathing animation (for nodes/hubs)
export const breathe = (duration: number = 4): Variants => ({
  animate: {
    opacity: [0.3, 0.8, 0.3],
    scale: [1, 1.05, 1],
    transition: {
      duration,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
});

// Data flow (for lanes/pathways)
export const dataFlow = (duration: number, reverse: boolean = false): Variants => {
  const from = reverse ? '110%' : '-10%';
  const to = reverse ? '-10%' : '110%';

  return {
    animate: {
      x: [from, to],
      opacity: [0, 0.7, 0.7, 0],
      transition: {
        duration,
        repeat: Infinity,
        ease: 'linear',
        times: [0, 0.15, 0.8, 1],
      },
    },
  };
};
