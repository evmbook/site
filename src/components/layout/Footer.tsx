import Link from 'next/link'

export function Footer() {
  return (
    <footer className="border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-2">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">
              Mastering EVM
            </h3>
            <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
              A comprehensive guide to the Ethereum Virtual Machine ecosystem.
              Free to read online, download, and share.
            </p>
            <p className="mt-4 text-xs text-slate-500 dark:text-slate-500">
              Written by Nakamoto Wei
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider">
              Book
            </h4>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/read" className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400">
                  Read Online
                </Link>
              </li>
              <li>
                <Link href="/download" className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400">
                  Download PDF
                </Link>
              </li>
              <li>
                <Link href="/download" className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400">
                  Download EPUB
                </Link>
              </li>
            </ul>
          </div>

          {/* More Links */}
          <div>
            <h4 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider">
              Resources
            </h4>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/about" className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400">
                  About
                </Link>
              </li>
              <li>
                <a
                  href="https://github.com/evmbook"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400"
                >
                  GitHub
                </a>
              </li>
              <li>
                <Link href="/read/colophon" className="text-sm text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400">
                  Colophon
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-12 pt-8 border-t border-slate-200 dark:border-slate-800">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-sm text-slate-500 dark:text-slate-500">
              Licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-sa/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-brand-600 dark:hover:text-brand-400"
              >
                CC BY-SA 4.0
              </a>
            </p>
            <p className="text-xs text-slate-400 dark:text-slate-600 mt-2 md:mt-0">
              Derivative of Mastering Ethereum by Andreas M. Antonopoulos &amp; Gavin Wood
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
