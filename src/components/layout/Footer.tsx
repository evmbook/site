import Link from 'next/link'

export function Footer() {
  return (
    <footer className="border-t-4 border-[var(--accent-primary)] bg-[var(--surface-base)]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-2">
            <h3 className="text-lg font-extrabold uppercase tracking-wider text-[var(--text-primary)]">
              Mastering EVM
            </h3>
            <p className="mt-4 text-sm text-[var(--text-secondary)] leading-relaxed">
              A comprehensive guide to the Ethereum Virtual Machine ecosystem.
              Free to read online, download, and share.
            </p>
            <p className="mt-4 text-xs text-[var(--text-muted)] leading-relaxed">
              Modernized and maintained by{' '}
              <a
                href="https://github.com/chris-mercer"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                Christopher Mercer
              </a>{' '}
              with Claude Code (claude-opus-4-5-20251101).
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-sm font-bold text-[var(--accent-primary)] uppercase tracking-wider">
              Book
            </h4>
            <ul className="mt-4 space-y-3">
              <li>
                <Link
                  href="/read"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  Read Online
                </Link>
              </li>
              <li>
                <Link
                  href="/download"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  Download PDF
                </Link>
              </li>
              <li>
                <Link
                  href="/download"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  Download EPUB
                </Link>
              </li>
            </ul>
          </div>

          {/* More Links */}
          <div>
            <h4 className="text-sm font-bold text-[var(--accent-primary)] uppercase tracking-wider">
              Resources
            </h4>
            <ul className="mt-4 space-y-3">
              <li>
                <Link
                  href="/about"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  About
                </Link>
              </li>
              <li>
                <a
                  href="https://github.com/evmbook"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  GitHub
                </a>
              </li>
              <li>
                <Link
                  href="/read/colophon"
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--link-color)] transition-colors duration-150"
                >
                  Colophon
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-12 pt-8 border-t-2 border-[var(--accent-primary)]/30">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-[var(--text-muted)]">
              Licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-sa/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                CC BY-SA 4.0
              </a>
            </p>
            <p className="text-xs text-[var(--text-muted)]">
              Last Updated: January 2026
            </p>
            <p className="text-xs text-[var(--text-muted)]/60">
              Derivative of Mastering Ethereum by Andreas M. Antonopoulos &amp;
              Gavin Wood
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
