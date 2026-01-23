'use client'

/**
 * BackgroundSystem - Neo-Brutalist Theme
 *
 * Visual concept:
 * - Pure dark base (#0A0A0A)
 * - Bold geometric shapes with high contrast
 * - Orange accent glow zones
 * - Subtle noise/grain texture
 * - Grid pattern overlay
 */

export function BackgroundSystem() {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 overflow-hidden"
    >
      {/* Base - pure dark */}
      <div className="absolute inset-0 bg-[#0A0A0A]" />

      {/* Noise texture overlay */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        }}
      />

      {/* Subtle grid pattern */}
      <div
        className="absolute inset-0 opacity-[0.02]"
        style={{
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)
          `,
          backgroundSize: '60px 60px',
        }}
      />

      {/* Top-right accent glow */}
      <div
        className="absolute -top-1/4 -right-1/4 w-[800px] h-[800px]"
        style={{
          background:
            'radial-gradient(circle, rgba(255,77,0,0.08) 0%, rgba(255,77,0,0.02) 40%, transparent 70%)',
        }}
      />

      {/* Bottom-left accent glow (Ethereum blue) */}
      <div
        className="absolute -bottom-1/4 -left-1/4 w-[600px] h-[600px]"
        style={{
          background:
            'radial-gradient(circle, rgba(98,126,234,0.05) 0%, rgba(98,126,234,0.01) 40%, transparent 70%)',
        }}
      />

      {/* Geometric accent - top right corner block */}
      <div
        className="absolute top-0 right-0 w-[300px] h-[200px]"
        style={{
          background:
            'linear-gradient(135deg, rgba(255,77,0,0.03) 0%, transparent 60%)',
          clipPath: 'polygon(100% 0, 100% 100%, 0 0)',
        }}
      />

      {/* Geometric accent - bottom left corner block */}
      <div
        className="absolute bottom-0 left-0 w-[250px] h-[180px]"
        style={{
          background:
            'linear-gradient(315deg, rgba(58,184,58,0.03) 0%, transparent 60%)',
          clipPath: 'polygon(0 100%, 100% 100%, 0 0)',
        }}
      />

      {/* Horizontal accent line */}
      <div
        className="absolute top-[20%] left-0 right-0 h-[1px]"
        style={{
          background:
            'linear-gradient(90deg, transparent 0%, rgba(255,77,0,0.1) 20%, rgba(255,77,0,0.1) 80%, transparent 100%)',
        }}
      />

      {/* Vertical accent line */}
      <div
        className="absolute top-0 bottom-0 right-[15%] w-[1px]"
        style={{
          background:
            'linear-gradient(180deg, transparent 0%, rgba(98,126,234,0.08) 30%, rgba(98,126,234,0.08) 70%, transparent 100%)',
        }}
      />

      {/* Vignette - subtle darkening at edges */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'radial-gradient(ellipse at 50% 50%, transparent 40%, rgba(0,0,0,0.3) 100%)',
        }}
      />
    </div>
  )
}
