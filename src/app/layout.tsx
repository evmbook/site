import type { Metadata } from 'next'
import '@/styles/globals.css'

export const metadata: Metadata = {
  title: {
    default: 'Mastering EVM',
    template: '%s | Mastering EVM',
  },
  description: 'A comprehensive guide to the Ethereum Virtual Machine ecosystem, covering Ethereum and Ethereum Classic.',
  keywords: ['EVM', 'Ethereum', 'Ethereum Classic', 'Solidity', 'Smart Contracts', 'Blockchain', 'DeFi'],
  authors: [{ name: 'Nakamoto Wei' }],
  creator: 'Nakamoto Wei',
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
      <body className="min-h-screen bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 antialiased">
        {children}
      </body>
    </html>
  )
}
