'use client'

import { useTheme } from '@/components/theme/ThemeProvider'

/**
 * BackgroundSystem - Neo-Brutalist Theme
 *
 * Visual concept:
 * - Theme-aware base color (dark/light)
 * - Bold geometric shapes with high contrast
 * - Teal/orange accent glow zones
 * - Subtle noise/grain texture
 * - Grid pattern overlay
 */

export function BackgroundSystem() {
  const { theme } = useTheme()
  const isLight = theme === 'light'

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
    >
      {/* Base - theme aware */}
      <div
        className="absolute inset-0 transition-colors duration-300"
        style={{ backgroundColor: isLight ? '#fafafa' : '#060606' }}
      />

      {/* Noise texture overlay */}
      <div
        className="absolute inset-0"
        style={{
          opacity: isLight ? 0.02 : 0.03,
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        }}
      />

      {/* Subtle grid pattern */}
      <div
        className="absolute inset-0"
        style={{
          opacity: isLight ? 0.03 : 0.02,
          backgroundImage: isLight
            ? `
            linear-gradient(rgba(0,0,0,0.05) 1px, transparent 1px),
            linear-gradient(90deg, rgba(0,0,0,0.05) 1px, transparent 1px)
          `
            : `
            linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)
          `,
          backgroundSize: '60px 60px',
        }}
      />

      {/* Top-right accent glow - Teal */}
      <div
        className="absolute -top-1/4 -right-1/4 w-[800px] h-[800px]"
        style={{
          background: isLight
            ? 'radial-gradient(circle, rgba(2,128,125,0.06) 0%, rgba(2,128,125,0.02) 40%, transparent 70%)'
            : 'radial-gradient(circle, rgba(2,128,125,0.1) 0%, rgba(2,128,125,0.03) 40%, transparent 70%)',
        }}
      />

      {/* Bottom-left accent glow - Orange (subtle) */}
      <div
        className="absolute -bottom-1/4 -left-1/4 w-[600px] h-[600px]"
        style={{
          background: isLight
            ? 'radial-gradient(circle, rgba(195,99,18,0.04) 0%, rgba(195,99,18,0.01) 40%, transparent 70%)'
            : 'radial-gradient(circle, rgba(195,99,18,0.06) 0%, rgba(195,99,18,0.02) 40%, transparent 70%)',
        }}
      />

      {/* Geometric accent - top right corner block */}
      <div
        className="absolute top-0 right-0 w-[300px] h-[200px]"
        style={{
          background: isLight
            ? 'linear-gradient(135deg, rgba(2,128,125,0.04) 0%, transparent 60%)'
            : 'linear-gradient(135deg, rgba(2,128,125,0.05) 0%, transparent 60%)',
          clipPath: 'polygon(100% 0, 100% 100%, 0 0)',
        }}
      />

      {/* Geometric accent - bottom left corner block */}
      <div
        className="absolute bottom-0 left-0 w-[250px] h-[180px]"
        style={{
          background: isLight
            ? 'linear-gradient(315deg, rgba(14,127,108,0.04) 0%, transparent 60%)'
            : 'linear-gradient(315deg, rgba(14,127,108,0.05) 0%, transparent 60%)',
          clipPath: 'polygon(0 100%, 100% 100%, 0 0)',
        }}
      />

      {/* Horizontal accent line */}
      <div
        className="absolute top-[20%] left-0 right-0 h-[1px]"
        style={{
          background: isLight
            ? 'linear-gradient(90deg, transparent 0%, rgba(2,128,125,0.15) 20%, rgba(2,128,125,0.15) 80%, transparent 100%)'
            : 'linear-gradient(90deg, transparent 0%, rgba(2,128,125,0.12) 20%, rgba(2,128,125,0.12) 80%, transparent 100%)',
        }}
      />

      {/* Vertical accent line */}
      <div
        className="absolute top-0 bottom-0 right-[15%] w-[1px]"
        style={{
          background: isLight
            ? 'linear-gradient(180deg, transparent 0%, rgba(14,127,108,0.12) 30%, rgba(14,127,108,0.12) 70%, transparent 100%)'
            : 'linear-gradient(180deg, transparent 0%, rgba(14,127,108,0.1) 30%, rgba(14,127,108,0.1) 70%, transparent 100%)',
        }}
      />

      {/* Vignette - subtle darkening/lightening at edges */}
      <div
        className="absolute inset-0"
        style={{
          background: isLight
            ? 'radial-gradient(ellipse at 50% 50%, transparent 40%, rgba(0,0,0,0.05) 100%)'
            : 'radial-gradient(ellipse at 50% 50%, transparent 40%, rgba(0,0,0,0.3) 100%)',
        }}
      />
    </div>
  )
}
