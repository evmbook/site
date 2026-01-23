import Link from 'next/link'
import type { ChapterMeta } from '@/lib/content'

interface ChapterNavProps {
  prev: ChapterMeta | null
  next: ChapterMeta | null
}

export function ChapterNav({ prev, next }: ChapterNavProps) {
  return (
    <nav className="mt-12 pt-8 border-t border-[#00D4D4]/10">
      <div className="flex justify-between items-center">
        {prev ? (
          <Link
            href={`/read/${prev.slug}`}
            className="group flex items-center gap-3 text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
          >
            <svg
              className="h-4 w-4 transform group-hover:-translate-x-1 transition-transform"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth="2"
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
            </svg>
            <div className="text-left">
              <div className="text-xs uppercase tracking-wider text-[#5E6B73] mb-0.5">
                Previous
              </div>
              <div className="font-medium text-sm">{prev.title}</div>
            </div>
          </Link>
        ) : (
          <div />
        )}

        {next ? (
          <Link
            href={`/read/${next.slug}`}
            className="group flex items-center gap-3 text-[#A8B4BC] hover:text-[#00D4D4] transition-colors"
          >
            <div className="text-right">
              <div className="text-xs uppercase tracking-wider text-[#5E6B73] mb-0.5">
                Next
              </div>
              <div className="font-medium text-sm">{next.title}</div>
            </div>
            <svg
              className="h-4 w-4 transform group-hover:translate-x-1 transition-transform"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth="2"
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
            </svg>
          </Link>
        ) : (
          <div />
        )}
      </div>
    </nav>
  )
}
