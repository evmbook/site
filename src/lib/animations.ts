/**
 * Framer Motion Animation Variants
 * Neo-Brutalist animations - snappy, purposeful, reduced motion support
 */

import type { Variants, Transition } from 'framer-motion'

// Default transition - snappy for Neo-Brutalist feel
export const defaultTransition: Transition = {
  duration: 0.15,
  ease: [0.25, 0.1, 0.25, 1],
}

export const springTransition: Transition = {
  type: 'spring',
  stiffness: 300,
  damping: 30,
}

// Fade in from bottom
export const fadeInUp: Variants = {
  hidden: {
    opacity: 0,
    y: 20,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: defaultTransition,
  },
}

// Fade in from left
export const fadeInLeft: Variants = {
  hidden: {
    opacity: 0,
    x: -20,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: defaultTransition,
  },
}

// Fade in from right
export const fadeInRight: Variants = {
  hidden: {
    opacity: 0,
    x: 20,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: defaultTransition,
  },
}

// Scale in
export const scaleIn: Variants = {
  hidden: {
    opacity: 0,
    scale: 0.95,
  },
  visible: {
    opacity: 1,
    scale: 1,
    transition: springTransition,
  },
}

// Stagger container - faster stagger for brutalist feel
export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
      delayChildren: 0.05,
    },
  },
}

// Stagger item
export const staggerItem: Variants = {
  hidden: {
    opacity: 0,
    y: 15,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.2,
      ease: 'easeOut',
    },
  },
}

// Section reveal
export const sectionReveal: Variants = {
  hidden: {
    opacity: 0,
    y: 30,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.3,
      ease: 'easeOut',
    },
  },
}

// Neo-Brutalist card hover effect - uses shadow offset
export const cardHover = {
  rest: {
    y: 0,
    transition: { duration: 0.15 },
  },
  hover: {
    y: -4,
    transition: { duration: 0.15 },
  },
}

// Button press effect - Neo-Brutalist shadow reduction
export const buttonPress = {
  rest: {
    x: 0,
    y: 0,
  },
  pressed: {
    x: 2,
    y: 2,
  },
  hover: {
    x: 0,
    y: 0,
  },
}

// Viewport settings for scroll-triggered animations
export const viewportSettings = {
  once: true,
  amount: 0.2,
  margin: '-50px',
}

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
      pathLength: { duration: 0.8, ease: 'easeInOut' },
      opacity: { duration: 0.2 },
    },
  },
}

// Reduced motion variants - minimal/no animation
export const reduceMotionFadeIn: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { duration: 0.01 },
  },
}
