# MILESTONES.md — evmbook-site Redesign

## Project Overview

Modernize evmbook-site with a Web3-native aesthetic while improving readability, SEO, and establishing proper attribution.

**Domain:** masteringevm.com
**Stack:** Next.js 15, TypeScript, Tailwind CSS 4, MDX

---

## Milestone 1: Claude Bootstrap ✅

**Status:** Complete

- [x] CLAUDE.md with project context
- [x] `.claude/commands/` (plan.md, review.md)
- [x] `.claude/agents/code-reviewer.md`
- [x] `.claude/hooks.json` (protected files, format-on-edit)
- [x] Prettier integration

**Commits:**
- `982c575` — initial claude bootstrap
- `75df343` — add prettier with format-on-edit hook

---

## Milestone 2: Theme Redesign 🔄

**Status:** Planning

### Goals
Adopt a modern Web3 aesthetic per Gemini's recommendations:
- **Neo-Brutalism** with **Organic Futurism** accents
- High-contrast colors, thick borders, bold typography
- Glassmorphism for code blocks and panels
- Maintain dark mode focus

### Tasks
- [ ] Update color palette in `globals.css`
- [ ] Revise `BackgroundSystem.tsx` (simplify or evolve)
- [ ] Update component styling (Hero, Features, Cards)
- [ ] Improve code block styling (glass texture)
- [ ] Test readability and contrast

### Files to Modify
- `src/styles/globals.css`
- `src/components/BackgroundSystem.tsx`
- `src/components/home/Hero.tsx`
- `src/components/home/Features.tsx`
- `src/components/home/DownloadCTA.tsx`

---

## Milestone 3: Attribution Update 🔄

**Status:** Planning

### Goals
Remove "Cipher Null" pseudonym, update to real attribution:
> "This derivative work has been modernized and maintained by Christopher Mercer with the heavy lifting by our trusted Claude Code (claude-opus-4-5-20251101)."

### Files to Update
- `src/app/layout.tsx` (metadata.authors, metadata.creator)
- `src/components/layout/Footer.tsx` (author credit)
- `src/app/about/page.tsx` (about section)
- `content/chapters/00-preface.mdx` (signature)
- `content/meta/colophon.mdx` (author description)
- `content/meta/about.mdx` (author section)

---

## Milestone 4: Readability Improvements 🔄

**Status:** Planning

### Goals
Optimize the "Read Online" section for long-form technical reading:
- Improve typography (line height, font sizes, spacing)
- Better heading hierarchy
- Enhanced code block styling
- Improved table styling
- Better callout/note boxes

### Files to Review
- `src/styles/globals.css` (prose styling, lines 336-517)
- `src/app/read/layout.tsx`
- `src/components/content/ChapterNav.tsx`
- `.reading-panel` class styling

---

## Milestone 5: Book Cover & Physical Display 🔄

**Status:** Planning

### Goals
Create visual assets showing a physical book representation:
- Design book cover image ("Mastering the Ethereum Virtual Machine")
- Create 3D book mockup similar to masteringmonero.com
- Add to homepage hero section

### Reference
- https://masteringmonero.com/ (book display style)

### Assets to Create
- `public/images/book-cover.png` (flat cover)
- `public/images/book-3d.png` (3D mockup)
- Component to display book with shadow/perspective

---

## Milestone 6: SEO & Meta System 🔄

**Status:** Planning

### Goals
Comprehensive SEO and social sharing optimization:
- Favicon (multiple sizes)
- OpenGraph images (1200x630)
- Twitter cards
- Structured data (JSON-LD)
- AI crawler optimization (robots.txt, meta tags)

### Files to Create
- `public/favicon.ico`
- `public/favicon-16x16.png`
- `public/favicon-32x32.png`
- `public/apple-touch-icon.png`
- `public/og-image.png`
- `public/twitter-card.png`
- `src/app/robots.ts`
- `src/app/sitemap.ts`

### Files to Update
- `src/app/layout.tsx` (complete metadata)

---

## Current Exploration Findings

### Project Structure
```
src/
  app/           # Next.js pages
  components/    # React components
    home/        # Hero, Features, DownloadCTA
    layout/      # Header, Footer, Sidebar
    content/     # ChapterNav, Callout
  lib/           # Utilities (content.ts, animations.ts)
  styles/        # globals.css
content/
  chapters/      # 18+ MDX chapter files
  meta/          # about.mdx, colophon.mdx
public/
  downloads/     # Empty (for PDF/EPUB)
  fonts/         # Empty
  images/        # Empty (needs assets)
```

### Current Author References (Cipher Null)
1. `src/app/layout.tsx:31-32` — metadata.authors, metadata.creator
2. `src/components/layout/Footer.tsx:18` — "Written by Cipher Null"
3. `src/app/about/page.tsx:64` — about page content
4. `content/chapters/00-preface.mdx` — signature
5. `content/meta/colophon.mdx` — author description
6. `content/meta/about.mdx` — author section

### Current Color Palette
- Void black: `#080D0F`
- Accent cyan: `#00D4D4`
- Accent teal: `#2DD4BF`
- Moon coral: `#E85A5A`
- Text primary: `#E8E4E0`
- Text secondary: `#A8B4BC`

### Missing Assets
- No favicon
- No OG image
- No Twitter card
- No book cover images
- Empty public/images/ directory

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-23 | Add Prettier | Enable format-on-edit hook |
| 2026-01-23 | Neo-Brutalism + Organic Futurism | Gemini recommendation for Web3 aesthetic |
| 2026-01-23 | Remove Cipher Null | Author is doxxed via GitHub commits |
| 2026-01-23 | Replace background entirely | User chose Neo-Brutalist bold shapes over moon/mountain |
| 2026-01-23 | Primary accent: #FF4D00 (orange) | User approved bold orange for Neo-Brutalism |
| 2026-01-23 | CSS-only book cover | Build CSS/SVG display first, add real images later |

---

## Approved Implementation Order

```
Phase 1: Attribution Update (first priority)
    ↓
Phase 2: SEO & Meta Foundation
    ↓ (parallel with Phase 3A-B)
Phase 3: Theme Redesign
  A. Color palette update
  B. Replace BackgroundSystem
  C. Typography updates
  D. Component styling
    ↓
Phase 4: Readability Improvements
    ↓
Phase 5: Book Cover Display (CSS-only)
    ↓
Phase 6: Polish & Testing
```

---

## New Color Palette (Approved)

```css
/* Neo-Brutalist */
--brutalist-black: #0A0A0A;
--brutalist-white: #FAFAFA;
--accent-primary: #FF4D00;     /* Bold orange */
--accent-secondary: #627EEA;   /* Ethereum blue */
--accent-tertiary: #3AB83A;    /* ETC green */
```
