# CLAUDE.md — evmbook-site

Interactive EVM reference book. Static Next.js site deployed to masteringevm.com.

## Stack

- **Framework:** Next.js 15 (App Router, static export)
- **Language:** TypeScript + MDX
- **Styling:** Tailwind CSS 4
- **Node:** 22+ (see `.nvmrc`)

## Commands

```bash
npm install          # install deps
npm run dev          # dev server (localhost:3000)
npm run build        # production build → out/
npm run lint         # eslint check
npm run format       # format all files with prettier
npm run format:check # check formatting without writing
```

## Structure

```
src/
  app/           # Next.js pages (layout, routes)
  components/    # React components (layout/, content/, ui/, home/)
  lib/           # Utilities
  styles/        # globals.css
content/
  chapters/      # MDX chapter files (00-*, 01-*, ...)
public/          # Static assets
out/             # Build output (gitignored)
```

## Guardrails

- **Do not edit:** `.env*`, `CNAME`, `package-lock.json` (unless dependency changes)
- **Do not commit:** `out/`, `.next/`, `node_modules/`
- **Tests:** Not configured — skip test-related commands

## Conventions

- Components: PascalCase (`ChapterNav.tsx`)
- Utilities: camelCase (`animations.ts`)
- Chapters: numbered prefix (`00-preface.mdx`, `01-intro.mdx`)
- Use existing Tailwind classes; avoid inline styles
- MDX content uses rehype-pretty-code for syntax highlighting

## Working with Claude

1. **Use `/plan`** before multi-file changes — get alignment first
2. **Keep diffs small** — one concern per change
3. **Formatting is automatic** — hooks run Prettier on edited files
4. **Use `/review`** for code review before finalizing
5. **Cite file paths** with line numbers when discussing code
6. **Don't create new files** unless necessary — prefer editing existing ones
