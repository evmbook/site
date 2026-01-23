import Link from 'next/link'

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-950">
      {/* Background decoration */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-brand-500/10 rounded-full blur-3xl" />
      </div>

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-24 sm:py-32">
        <div className="text-center">
          {/* Badge */}
          <div className="inline-flex items-center rounded-full px-4 py-1.5 text-sm font-medium bg-brand-100 text-brand-700 dark:bg-brand-900/30 dark:text-brand-300 mb-8">
            Free &amp; Open Source
          </div>

          {/* Title */}
          <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight text-slate-900 dark:text-white">
            Mastering the
            <span className="block text-brand-600 dark:text-brand-400">
              Ethereum Virtual Machine
            </span>
          </h1>

          {/* Subtitle */}
          <p className="mt-6 text-lg sm:text-xl text-slate-600 dark:text-slate-400 max-w-3xl mx-auto">
            A comprehensive guide to EVM development. Learn Solidity, smart contract security,
            DeFi protocols, and more. Covering both Ethereum and Ethereum Classic.
          </p>

          {/* CTA Buttons */}
          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/read"
              className="inline-flex items-center justify-center rounded-md bg-brand-600 px-6 py-3 text-base font-semibold text-white shadow-sm hover:bg-brand-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600 transition-colors"
            >
              Read Online
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
              </svg>
            </Link>
            <Link
              href="/download"
              className="inline-flex items-center justify-center rounded-md bg-slate-100 dark:bg-slate-800 px-6 py-3 text-base font-semibold text-slate-900 dark:text-white shadow-sm hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
            >
              Download PDF
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
              </svg>
            </Link>
          </div>

          {/* Stats */}
          <div className="mt-16 grid grid-cols-2 sm:grid-cols-4 gap-8 max-w-2xl mx-auto">
            <div>
              <div className="text-3xl font-bold text-slate-900 dark:text-white">17</div>
              <div className="text-sm text-slate-600 dark:text-slate-400">Chapters</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-slate-900 dark:text-white">5</div>
              <div className="text-sm text-slate-600 dark:text-slate-400">Appendices</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-slate-900 dark:text-white">100+</div>
              <div className="text-sm text-slate-600 dark:text-slate-400">Code Examples</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-slate-900 dark:text-white">Free</div>
              <div className="text-sm text-slate-600 dark:text-slate-400">Forever</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
