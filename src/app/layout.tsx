import type { Metadata } from 'next'
import { Inter, Space_Grotesk, JetBrains_Mono } from 'next/font/google'
import '@/styles/globals.css'
import { BackgroundSystem } from '@/components/BackgroundSystem'
import { ThemeProvider } from '@/components/theme'

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
  metadataBase: new URL('https://masteringevm.com'),
  title: {
    default: 'Mastering the Ethereum Virtual Machine',
    template: '%s | Mastering EVM',
  },
  description:
    'A comprehensive guide to the Ethereum Virtual Machine ecosystem, covering Ethereum and Ethereum Classic. Free to read online.',
  keywords: [
    'EVM',
    'Ethereum',
    'Ethereum Classic',
    'Solidity',
    'Smart Contracts',
    'Blockchain',
    'DeFi',
    'Web3',
    'Vyper',
    'dApp',
  ],
  authors: [{ name: 'Claude' }],
  creator: 'Claude',
  publisher: 'Mastering EVM',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://masteringevm.com',
    siteName: 'Mastering EVM',
    title: 'Mastering the Ethereum Virtual Machine',
    description:
      'A comprehensive guide to the Ethereum Virtual Machine ecosystem, covering Ethereum and Ethereum Classic.',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Mastering EVM Book Cover',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Mastering the Ethereum Virtual Machine',
    description:
      'A comprehensive guide to the Ethereum Virtual Machine ecosystem, covering Ethereum and Ethereum Classic.',
    images: ['/og-image.png'],
  },
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.svg', type: 'image/svg+xml' },
      { url: '/favicon-16x16.png', sizes: '16x16', type: 'image/png' },
      { url: '/favicon-32x32.png', sizes: '32x32', type: 'image/png' },
      { url: '/favicon-192x192.png', sizes: '192x192', type: 'image/png' },
      { url: '/favicon-512x512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180' }],
  },
  manifest: '/site.webmanifest',
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
}

// JSON-LD structured data for the book
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Book',
  name: 'Mastering the Ethereum Virtual Machine',
  author: {
    '@type': 'Organization',
    name: 'Claude',
    url: 'https://github.com/claude',
  },
  bookFormat: 'EBook',
  isAccessibleForFree: true,
  license: 'https://creativecommons.org/licenses/by-sa/4.0/',
  publisher: 'Mastering EVM',
  inLanguage: 'en',
  about: {
    '@type': 'Thing',
    name: 'Ethereum Virtual Machine',
  },
  url: 'https://masteringevm.com',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${inter.variable} ${spaceGrotesk.variable} ${jetbrainsMono.variable}`}
    >
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="min-h-screen bg-background text-foreground antialiased">
        <ThemeProvider>
          <BackgroundSystem />
          <div className="relative z-10">{children}</div>
        </ThemeProvider>
      </body>
    </html>
  )
}
