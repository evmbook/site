import Link from 'next/link'
import { getChapters, getAppendices } from '@/lib/content'

export const metadata = {
  title: 'Table of Contents',
  description: 'Read Mastering EVM online. Complete table of contents with chapters on Ethereum, Ethereum Classic, smart contracts, and DeFi development.',
  openGraph: {
    title: 'Read Mastering EVM - Table of Contents',
    description: 'Read Mastering EVM online. Complete table of contents with chapters on Ethereum, Ethereum Classic, smart contracts, and DeFi development.',
    url: 'https://masteringevm.com/read',
  },
}

export default function ReadPage() {
  const chapters = getChapters()
  const appendices = getAppendices()

  return (
    <div className="prose max-w-none">
      <h1>Table of Contents</h1>

      <p className="lead">
        Welcome to Mastering EVM. Use the sidebar or the links below to navigate through the book.
      </p>

      <h2>Chapters</h2>
      <ol className="space-y-2">
        {chapters.map((chapter) => (
          <li key={chapter.slug}>
            <Link
              href={`/read/${chapter.slug}`}
              className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors"
            >
              {chapter.title}
            </Link>
            {chapter.description && (
              <span className="text-[var(--text-muted)] text-sm ml-2">
                — {chapter.description}
              </span>
            )}
          </li>
        ))}
      </ol>

      {appendices.length > 0 && (
        <>
          <h2>Appendices</h2>
          <ol className="space-y-2" style={{ listStyleType: 'upper-alpha' }}>
            {appendices.map((appendix) => (
              <li key={appendix.slug}>
                <Link
                  href={`/read/appendix/${appendix.slug}`}
                  className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors"
                >
                  {appendix.title}
                </Link>
                {appendix.description && (
                  <span className="text-[var(--text-muted)] text-sm ml-2">
                    — {appendix.description}
                  </span>
                )}
              </li>
            ))}
          </ol>
        </>
      )}

      <hr />

      <h2>Getting Started</h2>
      <p>
        New to blockchain development? Start with <Link href="/read/00-preface" className="text-[var(--link-color)] hover:text-[var(--link-hover)] transition-colors">the Preface</Link> for
        an overview of the book, then proceed to Chapter 1.
      </p>
      <p>
        Experienced developers can jump directly to topics of interest using the sidebar navigation.
      </p>
    </div>
  )
}
