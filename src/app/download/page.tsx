import Link from 'next/link'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export const metadata = {
  title: 'Download',
  description: 'Download Mastering EVM in PDF or EPUB format. Free comprehensive guide to EVM development for offline reading.',
  openGraph: {
    title: 'Download Mastering EVM',
    description: 'Download Mastering EVM in PDF or EPUB format. Free comprehensive guide to EVM development for offline reading.',
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
              Download the Book
            </h1>
            <p className="mt-4 text-lg text-[var(--text-secondary)]">
              Get your free copy of Mastering EVM in your preferred format.
            </p>
          </div>

          <div className="grid gap-8 md:grid-cols-2">
            {/* PDF Download */}
            <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-primary)] p-8 text-center">
              <div className="mx-auto h-16 w-16 flex items-center justify-center border-4 border-[var(--accent-primary)] text-[var(--accent-primary)] mb-6">
                <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m.75 12l3 3m0 0l3-3m-3 3v-6m-1.5-9H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                </svg>
              </div>
              <h2 className="text-xl font-bold text-[var(--text-primary)] uppercase tracking-wider mb-2">
                PDF Format
              </h2>
              <p className="text-[var(--text-secondary)] mb-6">
                Best for printing or reading on desktop. Includes all diagrams and code examples with syntax highlighting.
              </p>
              <a
                href="/downloads/mastering-evm.pdf"
                className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-primary)] shadow-[4px_4px_0_0_var(--accent-primary)] hover:shadow-[2px_2px_0_0_var(--accent-primary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-primary)] hover:text-[#060606] transition-all duration-150"
              >
                Download PDF
                <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                </svg>
              </a>
              <p className="mt-4 text-sm text-[var(--text-muted)] uppercase tracking-wider">
                Coming soon — PDF generation in progress
              </p>
            </div>

            {/* EPUB Download */}
            <div className="bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-tertiary)] p-8 text-center">
              <div className="mx-auto h-16 w-16 flex items-center justify-center border-4 border-[var(--accent-tertiary)] text-[var(--accent-tertiary)] mb-6">
                <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
                </svg>
              </div>
              <h2 className="text-xl font-bold text-[var(--text-primary)] uppercase tracking-wider mb-2">
                EPUB Format
              </h2>
              <p className="text-[var(--text-secondary)] mb-6">
                Perfect for e-readers like Kindle, Kobo, or Apple Books. Reflowable text adapts to your screen.
              </p>
              <a
                href="/downloads/mastering-evm.epub"
                className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-tertiary)] shadow-[4px_4px_0_0_var(--accent-tertiary)] hover:shadow-[2px_2px_0_0_var(--accent-tertiary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-tertiary)] hover:text-[#060606] transition-all duration-150"
              >
                Download EPUB
                <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                </svg>
              </a>
              <p className="mt-4 text-sm text-[var(--text-muted)] uppercase tracking-wider">
                Coming soon — EPUB generation in progress
              </p>
            </div>
          </div>

          {/* License info */}
          <div className="mt-12 text-center bg-[var(--glass-bg)] backdrop-blur-sm border-4 border-[var(--accent-secondary)] p-8">
            <h3 className="text-lg font-bold text-[var(--text-primary)] uppercase tracking-wider mb-2">
              License
            </h3>
            <p className="text-[var(--text-secondary)]">
              Mastering EVM is licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-sa/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                CC BY-SA 4.0
              </a>
              . You are free to share and adapt this work for any purpose, even commercially,
              as long as you give appropriate credit and distribute your contributions under the same license.
            </p>
          </div>

          {/* Read online CTA */}
          <div className="mt-12 text-center">
            <p className="text-[var(--text-secondary)] mb-4">
              Prefer to read in your browser?
            </p>
            <Link
              href="/read"
              className="inline-flex items-center justify-center px-6 py-3 text-base font-bold uppercase tracking-wider bg-transparent text-[var(--text-primary)] border-4 border-[var(--accent-secondary)] shadow-[4px_4px_0_0_var(--accent-secondary)] hover:shadow-[2px_2px_0_0_var(--accent-secondary)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[var(--accent-secondary)] hover:text-[#060606] transition-all duration-150"
            >
              Read Online
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2.5" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
              </svg>
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  )
}
