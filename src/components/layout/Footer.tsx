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
            <p className="mt-2 text-sm text-[var(--text-muted)]">2025 Edition</p>
            <p className="mt-4 text-sm text-[var(--text-secondary)] leading-relaxed">
              The Complete Guide to the Ethereum Virtual Machine. A systems-level
              approach to teaching the EVM as it exists today.
            </p>
            <p className="mt-4 text-xs text-[var(--text-muted)] leading-relaxed">
              By Christopher Mercer with{' '}
              <a
                href="https://anthropic.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                Claude
              </a>{' '}
              (Anthropic). Published by White B0x Inc.
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
                href="https://creativecommons.org/licenses/by-nc/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors duration-150"
              >
                CC BY-NC 4.0
              </a>
            </p>
            <p className="text-xs text-[var(--text-muted)]">
              Current through January 2026
            </p>
            <p className="text-xs text-[var(--text-muted)]/60">
              19 Chapters | 5 Appendices | Ethereum &amp; Ethereum Classic
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
