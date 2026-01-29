import Link from 'next/link'

export const metadata = {
  title: 'Colophon',
  description: 'Technical details about how Mastering EVM was created, including design and licensing.',
  openGraph: {
    title: 'Colophon - Mastering EVM',
    description: 'Technical details about how Mastering EVM was created, including design and licensing.',
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
          <strong>Mastering EVM (2025 Edition)</strong> is a comprehensive guide to the Ethereum
          Virtual Machine ecosystem, covering both Ethereum (ETH) and Ethereum Classic (ETC).
          Written by Christopher Mercer with Claude (Anthropic) as writing collaborator.
        </p>
        <p>
          Published by White B0x Inc. ISBN (paperback): 979-8-9947278-0-5
        </p>

        <h2>Design</h2>
        <p>
          The visual design follows a <strong>Neo-Brutalist</strong> aesthetic with bold
          borders, high-contrast typography, and a dark theme optimized for extended reading.
        </p>
        <p>
          The color palette draws from both Ethereum ecosystems:
        </p>
        <ul>
          <li><strong>Ethereum Blue (#627EEA)</strong> — Primary accent</li>
          <li><strong>Purple (#8B5CF6)</strong> — Secondary accent</li>
          <li><strong>Ethereum Classic Green (#3AB83A)</strong> — ETC brand color</li>
          <li><strong>Vampire Black (#060606)</strong> — Dark background</li>
        </ul>

        <h2>License</h2>
        <p>
          This work is licensed under the{' '}
          <a
            href="https://creativecommons.org/licenses/by-nc/4.0/"
            target="_blank"
            rel="noopener noreferrer"
          >
            Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)
          </a>.
        </p>
        <p>You are free to:</p>
        <ul>
          <li><strong>Share</strong> — copy and redistribute the material in any medium or format</li>
          <li><strong>Adapt</strong> — remix, transform, and build upon the material</li>
        </ul>
        <p>Under the following terms:</p>
        <ul>
          <li><strong>Attribution</strong> — Give appropriate credit, provide a link to the license, and indicate if changes were made</li>
          <li><strong>NonCommercial</strong> — You may not use the material for commercial purposes</li>
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
