import Link from 'next/link'

export const metadata = {
  title: 'Colophon',
  description: 'Technical details about how Mastering EVM was created, including technology stack, design system, and licensing.',
  openGraph: {
    title: 'Colophon - Mastering EVM',
    description: 'Technical details about how Mastering EVM was created, including technology stack, design system, and licensing.',
    url: 'https://masteringevm.com/read/colophon',
  },
}

export default function ColophonPage() {
  return (
    <article>
      <div className="prose max-w-none">
        <h1>Colophon</h1>

        <p className="lead">
          Technical details about the creation and production of Mastering EVM.
        </p>

        <hr />

        <h2>About This Book</h2>
        <p>
          <strong>Mastering EVM</strong> is a comprehensive guide to the Ethereum Virtual Machine
          ecosystem, covering both Ethereum (ETH) and Ethereum Classic (ETC). This work is a
          derivative of <em>Mastering Ethereum</em> by Andreas M. Antonopoulos and Gavin Wood,
          substantially rewritten, reorganized, and updated for 2026.
        </p>

        <h2>Technology Stack</h2>
        <p>This website and book are built with:</p>
        <ul>
          <li><strong>Next.js 15</strong> — React framework with App Router and static export</li>
          <li><strong>TypeScript</strong> — Type-safe JavaScript</li>
          <li><strong>Tailwind CSS 4</strong> — Utility-first CSS framework</li>
          <li><strong>Framer Motion</strong> — Animation library for React</li>
          <li><strong>MDX</strong> — Markdown with JSX support for chapter content</li>
        </ul>

        <h2>Design System</h2>
        <p>
          The visual design follows a <strong>Neo-Brutalist</strong> aesthetic with{' '}
          <strong>Organic Futurism</strong> accents:
        </p>
        <ul>
          <li>Bold borders and shadows for emphasis</li>
          <li>High-contrast color palette optimized for readability</li>
          <li>Glassmorphism effects for depth</li>
          <li>Responsive typography with system font stack</li>
          <li>Full light/dark theme support</li>
        </ul>

        <h3>Color Palette</h3>
        <p>The theme uses a carefully selected palette:</p>
        <ul>
          <li><strong>Vampire Black (#060606)</strong> — Primary dark background</li>
          <li><strong>Alloy Orange (#C36312)</strong> — Primary accent</li>
          <li><strong>Teal Green (#02807D)</strong> — Secondary accent</li>
          <li><strong>Sage Green (#0E7F6C)</strong> — Tertiary accent</li>
          <li><strong>Ethereum Blue (#627EEA)</strong> — ETH brand color</li>
          <li><strong>Ethereum Classic Green (#3AB83A)</strong> — ETC brand color</li>
        </ul>

        <h2>Hosting &amp; Deployment</h2>
        <p>
          The site is statically generated and can be hosted on any static file server.
          The build process produces optimized HTML, CSS, and JavaScript bundles.
        </p>

        <h2>Development</h2>
        <p>
          This project was developed by{' '}
          <a href="https://github.com/claude" target="_blank" rel="noopener noreferrer">
            Claude
          </a>{' '}
          using Claude Code (claude-opus-4-5-20251101).
        </p>

        <h2>License</h2>
        <p>
          This work is licensed under the{' '}
          <a
            href="https://creativecommons.org/licenses/by-sa/4.0/"
            target="_blank"
            rel="noopener noreferrer"
          >
            Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)
          </a>.
        </p>
        <p>You are free to:</p>
        <ul>
          <li><strong>Share</strong> — copy and redistribute the material in any medium or format</li>
          <li><strong>Adapt</strong> — remix, transform, and build upon the material for any purpose, even commercially</li>
        </ul>
        <p>Under the following terms:</p>
        <ul>
          <li><strong>Attribution</strong> — Give appropriate credit, provide a link to the license, and indicate if changes were made</li>
          <li><strong>ShareAlike</strong> — Distribute contributions under the same license</li>
        </ul>

        <h2>Source Code</h2>
        <p>
          The source code for this book and website is available on{' '}
          <a
            href="https://github.com/evmbook"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>. Contributions, corrections, and improvements are welcome.
        </p>

        <hr />

        <p className="text-center">
          <Link href="/read">Return to Table of Contents</Link>
        </p>
      </div>
    </article>
  )
}
