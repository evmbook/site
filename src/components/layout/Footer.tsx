import Link from 'next/link'

export function Footer() {
  return (
    <footer className="border-t border-neon-purple/20 bg-void-black/80 backdrop-blur-sm">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-2">
            <h3 className="text-lg font-bold text-text-primary">
              Mastering EVM
            </h3>
            <p className="mt-2 text-sm text-text-secondary">
              A comprehensive guide to the Ethereum Virtual Machine ecosystem.
              Free to read online, download, and share.
            </p>
            <p className="mt-4 text-xs text-text-muted leading-relaxed">
              Modernized and maintained by Christopher Mercer with
              Claude Code (claude-opus-4-5-20251101).
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-sm font-semibold text-text-primary uppercase tracking-wider">
              Book
            </h4>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/read" className="text-sm text-text-secondary hover:text-neon-cyan transition-colors">
                  Read Online
                </Link>
              </li>
              <li>
                <Link href="/download" className="text-sm text-text-secondary hover:text-neon-cyan transition-colors">
                  Download PDF
                </Link>
              </li>
              <li>
                <Link href="/download" className="text-sm text-text-secondary hover:text-neon-cyan transition-colors">
                  Download EPUB
                </Link>
              </li>
            </ul>
          </div>

          {/* More Links */}
          <div>
            <h4 className="text-sm font-semibold text-text-primary uppercase tracking-wider">
              Resources
            </h4>
            <ul className="mt-4 space-y-2">
              <li>
                <Link href="/about" className="text-sm text-text-secondary hover:text-neon-cyan transition-colors">
                  About
                </Link>
              </li>
              <li>
                <a
                  href="https://github.com/evmbook"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-text-secondary hover:text-neon-cyan transition-colors"
                >
                  GitHub
                </a>
              </li>
              <li>
                <Link href="/read/colophon" className="text-sm text-text-secondary hover:text-neon-cyan transition-colors">
                  Colophon
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="mt-12 pt-8 border-t border-neon-purple/10">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-sm text-text-muted">
              Licensed under{' '}
              <a
                href="https://creativecommons.org/licenses/by-sa/4.0/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-neon-cyan hover:text-neon-pink transition-colors"
              >
                CC BY-SA 4.0
              </a>
            </p>
            <p className="text-xs text-text-muted/60 mt-2 md:mt-0">
              Derivative of Mastering Ethereum by Andreas M. Antonopoulos &amp; Gavin Wood
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}
