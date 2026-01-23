import clsx from 'clsx'

interface CalloutProps {
  type?: 'info' | 'warning' | 'note' | 'tip'
  title?: string
  children: React.ReactNode
}

const styles = {
  info: {
    container: 'bg-[var(--callout-info-bg)] border-l-[var(--accent-info)]',
    icon: 'text-[var(--accent-info)]',
    title: 'text-[var(--accent-info)]',
    content: 'text-[var(--text-secondary)]',
  },
  warning: {
    container: 'bg-[var(--callout-warning-bg)] border-l-[var(--accent-warning)]',
    icon: 'text-[var(--accent-warning)]',
    title: 'text-[var(--accent-warning)]',
    content: 'text-[var(--text-secondary)]',
  },
  note: {
    container: 'bg-[var(--surface-elevated)] border-l-[var(--accent-primary)]',
    icon: 'text-[var(--accent-primary)]',
    title: 'text-[var(--accent-primary)]',
    content: 'text-[var(--text-secondary)]',
  },
  tip: {
    container: 'bg-[var(--callout-tip-bg)] border-l-[var(--accent-tertiary)]',
    icon: 'text-[var(--accent-tertiary)]',
    title: 'text-[var(--accent-tertiary)]',
    content: 'text-[var(--text-secondary)]',
  },
}

const icons = {
  info: (
    <svg
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2.5"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
      />
    </svg>
  ),
  warning: (
    <svg
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2.5"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
      />
    </svg>
  ),
  note: (
    <svg
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2.5"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
      />
    </svg>
  ),
  tip: (
    <svg
      className="h-6 w-6"
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth="2.5"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 18v-5.25m0 0a6.01 6.01 0 001.5-.189m-1.5.189a6.01 6.01 0 01-1.5-.189m3.75 7.478a12.06 12.06 0 01-4.5 0m3.75 2.383a14.406 14.406 0 01-3 0M14.25 18v-.192c0-.983.658-1.823 1.508-2.316a7.5 7.5 0 10-7.517 0c.85.493 1.509 1.333 1.509 2.316V18"
      />
    </svg>
  ),
}

export function Callout({ type = 'info', title, children }: CalloutProps) {
  const style = styles[type]

  return (
    <div className={clsx('border-l-4 p-5 my-8', style.container)}>
      <div className="flex gap-4">
        <div className={clsx('flex-shrink-0', style.icon)}>{icons[type]}</div>
        <div className="flex-1 min-w-0">
          {title && (
            <h4
              className={clsx(
                'font-bold uppercase tracking-wider text-sm mb-2',
                style.title
              )}
            >
              {title}
            </h4>
          )}
          <div className={clsx('text-sm leading-relaxed', style.content)}>
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
