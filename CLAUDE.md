# CLAUDE.md — evmbook-site

Website for Mastering EVM (2025 Edition). Static Next.js site deployed to masteringevm.com.

## Source of Truth

**evmbook-v2025 is authoritative.** Do not invent claims not supported by the book.

Key reference files in the book repo:
- `content/chapters/_index.json` — canonical chapter list (28 chapters, 8 appendices)
- `content/chapters/00-preface.mdx` — book philosophy and framing
- `images/covers/cover-back.svg` — author bio (use verbatim)
- `publishing/book-metadata.yaml` — ISBN, publisher, license info

## Stack

- **Framework:** Next.js 15 (App Router, static export)
- **Language:** TypeScript + MDX
- **Styling:** Tailwind CSS 4 with CSS variables
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
  components/    # React components
    layout/      # Header, Footer, Sidebar (chapter list here)
    home/        # Hero, Features (key marketing copy here)
    content/     # MDX rendering, ChapterNav
  lib/           # Utilities (content loading, animations, stats)
  styles/        # globals.css (theme variables, color palette)
content/
  chapters/      # MDX chapter files (00-*, 01-*, ...)
  appendices/    # Reference appendices (a-*, b-*, ...)
public/          # Static assets (favicons, OG images)
out/             # Build output (gitignored)
```

## Key Files for Copy Alignment

| Website Element | File | Book Source |
|----------------|------|-------------|
| Chapter list | `src/components/layout/Sidebar.tsx` | `_index.json` |
| Hero copy | `src/components/home/Hero.tsx` | Preface differentiators |
| Features | `src/components/home/Features.tsx` | Preface + back cover |
| About page | `src/app/about/page.tsx` | Back cover author bio |
| Footer | `src/components/layout/Footer.tsx` | Metadata |

## Design System

Theme aligned with book cover (indigo/purple/green, not orange):

```css
--accent-primary: #627EEA;   /* Indigo */
--accent-secondary: #8B5CF6; /* Purple */
--accent-tertiary: #3AB83A;  /* Green */
--surface-base: #0a0a1a;     /* Deep blue-black */
```

## Guardrails

- **Do not edit:** `.env*`, `CNAME`, `package-lock.json`
- **Do not commit:** `out/`, `.next/`, `node_modules/`
- **Tests:** Not configured — skip test-related commands
- **Copy accuracy:** Verify all claims against evmbook-v2025

## Conventions

- Components: PascalCase (`ChapterNav.tsx`)
- Utilities: camelCase (`animations.ts`)
- Chapters: numbered prefix (`00-preface.mdx`, `01-evm-today.mdx`)
- Use existing Tailwind classes and CSS variables
- MDX content uses rehype-pretty-code for syntax highlighting

## Brand Voice

From the book's Preface:
- Calm, systems-oriented, grounded, builder perspective
- No hype or marketing fluff
- "Decentralization is bounded from below"
- Evolution narratives, dependency trees, honest trust assumptions

## Working with Claude

1. **Verify against book** — all copy must be supported by evmbook-v2025
2. **Use `/plan`** before multi-file changes
3. **Keep diffs small** — one concern per change
4. **Formatting is automatic** — hooks run Prettier on edited files
5. **Cite file paths** with line numbers when discussing code

## Release Checklist

Before deploying:
- [ ] Sidebar chapters match `_index.json` (28 chapters)
- [ ] Appendices complete (8 appendices A-H)
- [ ] Author bio matches back cover exactly
- [ ] License shows CC BY-NC 4.0
- [ ] No unsupported claims in Hero/Features
- [ ] Colors use indigo/purple theme (not orange)
