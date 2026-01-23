import type { Metadata } from 'next'
import '@/styles/globals.css'
import { BackgroundSystem } from '@/components/BackgroundSystem'

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
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Space+Grotesk:wght@500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen bg-void-black text-text-primary antialiased">
        <BackgroundSystem />
        <div className="relative z-10">
          {children}
        </div>
      </body>
    </html>
  )
}
