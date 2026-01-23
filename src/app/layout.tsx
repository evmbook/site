import type { Metadata } from 'next'
import { Inter, Space_Grotesk, JetBrains_Mono } from 'next/font/google'
import '@/styles/globals.css'
import { BackgroundSystem } from '@/components/BackgroundSystem'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-space-grotesk',
  display: 'swap',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-jetbrains-mono',
  display: 'swap',
})

export const metadata: Metadata = {
  title: {
    default: 'Mastering EVM',
    template: '%s | Mastering EVM',
  },
  description: 'A comprehensive guide to the Ethereum Virtual Machine ecosystem, covering Ethereum and Ethereum Classic.',
  keywords: ['EVM', 'Ethereum', 'Ethereum Classic', 'Solidity', 'Smart Contracts', 'Blockchain', 'DeFi'],
  authors: [{ name: 'Cipher Null' }],
  creator: 'Cipher Null',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://masteringevm.com',
    siteName: 'Mastering EVM',
    title: 'Mastering EVM',
    description: 'A comprehensive guide to the Ethereum Virtual Machine ecosystem',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Mastering EVM',
    description: 'A comprehensive guide to the Ethereum Virtual Machine ecosystem',
  },
  robots: {
    index: true,
    follow: true,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning className={`${inter.variable} ${spaceGrotesk.variable} ${jetbrainsMono.variable}`}>
      <body className="min-h-screen bg-void-black text-text-primary antialiased">
        <BackgroundSystem />
        <div className="relative z-10">
          {children}
        </div>
      </body>
    </html>
  )
}
