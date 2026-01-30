import { Metadata } from 'next'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Hero } from '@/components/home/Hero'
import { Features } from '@/components/home/Features'
// import { DownloadCTA } from '@/components/home/DownloadCTA'
import { getBookStats } from '@/lib/stats'

export const metadata: Metadata = {
  title: 'Mastering EVM (2025 Edition) — The Complete Guide to the Ethereum Virtual Machine',
  description:
    'A systems-level guide to EVM development covering Ethereum and Ethereum Classic. Evolution narratives, dependency trees, and trust assumptions for smart contract developers.',
  keywords: [
    'EVM',
    'Ethereum Virtual Machine',
    'Ethereum',
    'Ethereum Classic',
    'Solidity',
    'Vyper',
    'smart contracts',
    'DeFi',
    'blockchain development',
  ],
  authors: [{ name: 'Christopher Mercer' }],
  openGraph: {
    title: 'Mastering EVM (2025 Edition)',
    description:
      'The Complete Guide to the Ethereum Virtual Machine. Free online book covering Ethereum and Ethereum Classic.',
    url: 'https://masteringevm.com',
    siteName: 'Mastering EVM',
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Mastering EVM (2025 Edition)',
    description:
      'The Complete Guide to the Ethereum Virtual Machine. Free online book covering Ethereum and Ethereum Classic.',
  },
  alternates: {
    canonical: 'https://masteringevm.com',
  },
}

export default function HomePage() {
  // Get stats at build time (Server Component)
  const stats = getBookStats()

  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-1">
        <Hero stats={stats} />
        <Features />
        {/* <DownloadCTA /> */}
      </main>
      <Footer />
    </div>
  )
}
