import Link from 'next/link'
import type { ChapterMeta } from '@/lib/content'

interface ChapterNavProps {
  prev: ChapterMeta | null
  next: ChapterMeta | null
}

export function ChapterNav({ prev, next }: ChapterNavProps) {
  return (
    <nav className="mt-16 pt-8 border-t border-slate-200 dark:border-slate-800">
      <div className="flex justify-between items-center">
        {prev ? (
          <Link
            href={`/read/${prev.slug}`}
            className="group flex items-center gap-3 text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400 transition-colors"
          >
            <svg
              className="h-5 w-5 transform group-hover:-translate-x-1 transition-transform"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth="2"
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
            </svg>
            <div className="text-left">
              <div className="text-xs uppercase tracking-wider text-slate-500 dark:text-slate-500">
                Previous
              </div>
              <div className="font-medium">{prev.title}</div>
            </div>
          </Link>
        ) : (
          <div />
        )}

        {next ? (
          <Link
            href={`/read/${next.slug}`}
            className="group flex items-center gap-3 text-slate-600 dark:text-slate-400 hover:text-brand-600 dark:hover:text-brand-400 transition-colors"
          >
            <div className="text-right">
              <div className="text-xs uppercase tracking-wider text-slate-500 dark:text-slate-500">
                Next
              </div>
              <div className="font-medium">{next.title}</div>
            </div>
            <svg
              className="h-5 w-5 transform group-hover:translate-x-1 transition-transform"
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
