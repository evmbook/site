import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

// TODO: Replace with your actual Lemon Squeezy checkout URL after creating the product
const LEMON_SQUEEZY_CHECKOUT_URL = 'https://masteringevm.lemonsqueezy.com/buy/YOUR_PRODUCT_ID'

export const metadata = {
  title: 'Get the Book',
  description: 'Get Mastering EVM as a DRM-free PDF + EPUB bundle. Read online for free or purchase the digital edition for offline reading.',
  openGraph: {
    title: 'Get Mastering EVM',
    description: 'Get Mastering EVM as a DRM-free PDF + EPUB bundle. Read online for free or purchase the digital edition for offline reading.',
    url: 'https://masteringevm.com/download',
  },
}

export default function DownloadPage() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--surface-base)]">
      <Header />
      <main className="flex-1">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 py-16 sm:py-24">
          <div className="text-center mb-12">
            <h1 className="text-4xl font-extrabold tracking-tight text-[var(--text-primary)] uppercase">
              Get the Book
            </h1>
            <p className="mt-4 text-lg text-[var(--text-secondary)]">
              Read online for free, or grab the digital edition for offline reading.
            </p>
          </div>

          {/* Digital Edition - Paid */}
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-tertiary)] p-8 mb-8">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h2 className="text-2xl font-bold text-[var(--text-primary)] uppercase tracking-wider">
                    Digital Edition
                  </h2>
                  <span className="px-3 py-1 text-sm font-bold uppercase tracking-wider bg-[var(--accent-tertiary)] text-[#060606]">
                    $6.99
                  </span>
                </div>
                <p className="text-lg text-[var(--text-secondary)] mb-4">
                  PDF + EPUB bundle
                </p>
                <ul className="space-y-2 text-[var(--text-secondary)]">
                  <li className="flex items-center gap-2">
                    <svg className="h-5 w-5 text-[var(--accent-tertiary)]" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    Instant download after purchase
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="h-5 w-5 text-[var(--accent-tertiary)]" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    Both formats included (PDF + EPUB)
                  </li>
                  <li className="flex items-center gap-2">
                    <svg className="h-5 w-5 text-[var(--accent-tertiary)]" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    DRM-free, yours forever
                  </li>
                </ul>
              </div>
              <div className="flex-shrink-0">
                <a
                  href={LEMON_SQUEEZY_CHECKOUT_URL}
                  className="lemonsqueezy-button inline-flex items-center justify-center px-8 py-4 text-lg font-bold uppercase tracking-wider bg-transparent text-[#060606] border-4 border-[var(--accent-tertiary)] shadow-[4px_4px_0_0_var(--text-primary)] hover:shadow-[2px_2px_0_0_var(--text-primary)] hover:translate-x-[2px] hover:translate-y-[2px] transition-all duration-150"
                >
                  Buy Now — $6.99
                  <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </a>
              </div>
            </div>
          </div>

          {/* Free Online Reading */}
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-tertiary)] p-8 mb-8">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h2 className="text-2xl font-bold text-[var(--text-primary)] uppercase tracking-wider">
                    Read Online
                  </h2>
                  <span className="px-3 py-1 text-sm font-bold uppercase tracking-wider border-2 border-[var(--accent-tertiary)] text-[var(--accent-tertiary)]">
                    Free
                  </span>
                </div>
                <p className="text-[var(--text-secondary)]">
                  Read the complete book in your browser. All 28 chapters, fully searchable, always up to date.
                </p>
              </div>
              <div className="flex-shrink-0">
                <Link
                  href="/read"
                  className="inline-flex items-center justify-center px-8 py-4 text-lg font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-tertiary)] shadow-[4px_4px_0_0_var(--text-primary)] hover:shadow-[2px_2px_0_0_var(--text-primary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:text-[#060606] transition-all duration-150"
                >
                  Start Reading
                  <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </Link>
              </div>
            </div>
          </div>

          {/* Coming Soon */}
          <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--border-subtle)] p-8 mb-8">
            <h3 className="text-lg font-bold text-[var(--text-primary)] uppercase tracking-wider mb-4">
              Coming Soon
            </h3>
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="flex items-center gap-3 text-[var(--text-muted)]">
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
                </svg>
                <span>Paperback</span>
              </div>
              <div className="flex items-center gap-3 text-[var(--text-muted)]">
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5h3m-6.75 2.25h10.5a2.25 2.25 0 002.25-2.25v-15a2.25 2.25 0 00-2.25-2.25H6.75A2.25 2.25 0 004.5 4.5v15a2.25 2.25 0 002.25 2.25z" />
                </svg>
                <span>Kindle</span>
              </div>
              <div className="flex items-center gap-3 text-[var(--text-muted)]">
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z" />
                </svg>
                <span>Audiobook</span>
              </div>
            </div>
          </div>

          {/* License info */}
          <div className="text-center bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-secondary)] p-8">
            <h3 className="text-lg font-bold text-[var(--text-primary)] uppercase tracking-wider mb-2">
              License
            </h3>
            <p className="text-[var(--text-secondary)]">
              The online version of Mastering EVM is licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-nc/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                CC BY-NC 4.0
              </a>
              . You are free to share and adapt the online content for non-commercial purposes,
              as long as you give appropriate credit.
            </p>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
