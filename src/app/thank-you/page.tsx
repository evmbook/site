import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata = {
  title: 'Thank You',
  description: 'Thank you for purchasing Mastering EVM. Check your email for download links.',
  robots: {
    index: false,
    follow: false,
  },
}

export default function ThankYouPage() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--surface-base)]">
      <Header />
      <main className="flex-1">
        <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8 py-16 sm:py-24">
          <div className="text-center">
            {/* Success icon */}
            <div className="mx-auto h-20 w-20 flex items-center justify-center border-4 border-[var(--accent-tertiary)] text-[var(--accent-tertiary)] mb-8">
              <svg className="h-10 w-10" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
            </div>

            <h1 className="text-4xl font-extrabold tracking-tight text-[var(--text-primary)] uppercase mb-4">
              Thank You!
            </h1>

            <p className="text-xl text-[var(--text-secondary)] mb-8">
              Your purchase of Mastering EVM is complete.
            </p>

            <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-primary)] p-8 mb-8 text-left">
              <h2 className="text-lg font-bold text-[var(--text-primary)] uppercase tracking-wider mb-4">
                What happens next?
              </h2>
              <ol className="space-y-4 text-[var(--text-secondary)]">
                <li className="flex gap-3">
                  <span className="flex-shrink-0 h-6 w-6 flex items-center justify-center border-2 border-[var(--accent-primary)] text-[var(--accent-primary)] text-sm font-bold">
                    1
                  </span>
                  <span>
                    <strong className="text-[var(--text-primary)]">Check your email</strong> — You should receive a receipt with download links within a few minutes.
                  </span>
                </li>
                <li className="flex gap-3">
                  <span className="flex-shrink-0 h-6 w-6 flex items-center justify-center border-2 border-[var(--accent-primary)] text-[var(--accent-primary)] text-sm font-bold">
                    2
                  </span>
                  <span>
                    <strong className="text-[var(--text-primary)]">Download your files</strong> — Click the links in the email to download your PDF and EPUB files.
                  </span>
                </li>
                <li className="flex gap-3">
                  <span className="flex-shrink-0 h-6 w-6 flex items-center justify-center border-2 border-[var(--accent-primary)] text-[var(--accent-primary)] text-sm font-bold">
                    3
                  </span>
                  <span>
                    <strong className="text-[var(--text-primary)]">Enjoy the book</strong> — The files are DRM-free, so read them anywhere you like.
                  </span>
                </li>
              </ol>
            </div>

            <p className="text-sm text-[var(--text-muted)] mb-8">
              Didn&apos;t receive the email? Check your spam folder, or contact support if you need help.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/read"
                className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-[var(--accent-primary)] text-[#060606] border-4 border-[var(--accent-primary)] shadow-[4px_4px_0_0_var(--text-primary)] hover:shadow-[2px_2px_0_0_var(--text-primary)] hover:translate-x-[2px] hover:translate-y-[2px] transition-all duration-150"
              >
                Start Reading Online
                <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                </svg>
              </Link>
              <Link
                href="/"
                className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--border-subtle)] hover:border-[var(--accent-secondary)] transition-all duration-150"
              >
                Back to Home
              </Link>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
