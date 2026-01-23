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

## Milestone 2: Attribution & SEO ✅

**Status:** Complete

- [x] Remove "Cipher Null" across all files
- [x] Add Christopher Mercer + Claude Code attribution
- [x] Update footer, about page, preface, colophon
- [x] Add robots.txt with AI crawler permissions
- [x] Add sitemap.xml
- [x] Add favicon.svg
- [x] Enhanced metadata with JSON-LD

**Commit:** `ec7920a` — feat(theme): neo-brutalist redesign phase 1

---

## Milestone 3: Theme Foundation ✅

**Status:** Complete

- [x] Neo-Brutalist color palette (orange #FF4D00, Ethereum blue, ETC green)
- [x] Pure black base (#0A0A0A)
- [x] Replace BackgroundSystem with minimal brutalist design
- [x] Add noise texture, grid overlay, geometric accents

**Commit:** `ec7920a` — feat(theme): neo-brutalist redesign phase 1

---

## Milestone 4: Component Updates ✅

**Status:** Complete

### Tasks
- [x] Update Hero.tsx with Neo-Brutalist styling
- [x] Update Features.tsx with thick borders, shadow offset
- [x] Update DownloadCTA.tsx
- [x] Create BookDisplay component (CSS-only)
- [x] Update button styles
- [x] Fix about/page.tsx undefined Tailwind classes (purple text bug)
- [x] Make chapter/appendix count dynamic via stats.ts
- [x] Replace "Open Source" feature with "Agentic Development"
- [x] Link Christopher Mercer to GitHub across all files

**Commits:** Phase 1 complete

---

## Milestone 5: Light/Dark Theme Toggle ✅

**Status:** Complete

### Implementation
- [x] Create ThemeProvider (context + localStorage persistence)
- [x] Create ThemeToggle component (sun/moon icons)
- [x] Add light theme CSS variables to globals.css
- [x] Wrap layout.tsx with ThemeProvider
- [x] Add ThemeToggle to Header (desktop + mobile)
- [x] Update Header to use CSS variables for theme adaptability
- [x] Keep code blocks dark in light mode for readability
- [x] **Site-wide CSS variable implementation** (all pages and components)

### Files Created
- `src/components/theme/ThemeProvider.tsx`
- `src/components/theme/ThemeToggle.tsx`
- `src/components/theme/index.ts`

### Files Modified (Site-wide Theme)
- `src/styles/globals.css` (light theme variables, callout backgrounds)
- `src/app/layout.tsx` (ThemeProvider wrapper)
- `src/components/layout/Header.tsx` (ThemeToggle + CSS variables)
- `src/components/layout/Footer.tsx` (CSS variables)
- `src/components/layout/Sidebar.tsx` (CSS variables)
- `src/components/home/Hero.tsx` (CSS variables)
- `src/components/home/Features.tsx` (CSS variables)
- `src/components/home/DownloadCTA.tsx` (CSS variables)
- `src/components/home/BookDisplay.tsx` (CSS variables)
- `src/components/content/ChapterNav.tsx` (migrated from legacy to neo-brutalist)
- `src/components/content/Callout.tsx` (CSS variables)
- `src/components/ui/Button.tsx` (migrated to neo-brutalist theme)
- `src/app/download/page.tsx` (full neo-brutalist restyle)
- `src/app/about/page.tsx` (button CSS variables)
- `src/app/read/page.tsx` (fixed undefined Tailwind classes)

---

## Milestone 6: Readability Improvements ✅

**Status:** Complete

### Implementation
- [x] Improved typography in `.prose` (line height 1.85, max-width 75ch)
- [x] Better heading hierarchy with larger sizes and bottom borders
- [x] Enhanced code block styling (glassmorphism effect, dark in light mode)
- [x] Neo-Brutalist table styling (thick borders, colored headers)
- [x] Better callout/note boxes with CSS variable support
- [x] ChapterNav migrated to neo-brutalist theme
- [x] `.reading-panel` styling with brutal shadow

### Files Updated
- `src/styles/globals.css` (comprehensive prose styling)
- `src/components/content/ChapterNav.tsx` (neo-brutalist design)
- `src/components/content/Callout.tsx` (CSS variable support)

---

## Milestone 7: Book Cover & Physical Display ✅

**Status:** Complete (CSS-only version)

### Implementation
- [x] CSS-only 3D book display component (BookDisplay.tsx)
- [x] Book spine with text and accents
- [x] Interactive hover effects with Framer Motion
- [x] "Free" badge animation
- [x] Integrated in homepage hero section

### Decision
CSS-only book display is acceptable for initial release. Actual image assets deferred to future work.

### Files
- `src/components/home/BookDisplay.tsx` (existing CSS-only implementation)

---

## Milestone 8: SEO & Meta System ✅

**Status:** Complete (code portion)

### Implementation
- [x] favicon.svg exists
- [x] robots.txt exists (static file with AI crawler permissions)
- [x] sitemap.xml exists (static file)
- [x] JSON-LD structured data in layout.tsx
- [x] Comprehensive metadata in layout.tsx

### Deferred Assets (image files)
- [ ] favicon.ico, PNG favicons
- [ ] apple-touch-icon.png
- [ ] og-image.png (1200x630)
- [ ] twitter-card.png

### Files
- `public/favicon.svg`
- `public/robots.txt`
- `public/sitemap.xml`
- `src/app/layout.tsx` (metadata + JSON-LD)

---

## v0.1 Release Summary

**Release Date:** 2026-01-23

All 8 milestones complete. The website is in a production-ready state with:
- Full Neo-Brutalist + Organic Futurism design system
- Complete light/dark theme support across all pages and components
- SEO metadata and structured data
- Responsive design for all screen sizes

### Deferred to Future Releases
- Image assets (og-image.png, twitter-card.png, favicon.ico, apple-touch-icon.png)
- Book content review (evmbook-v1 repo)
- PDF/EPUB download files
- Actual book cover image

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
| 2026-01-23 | Fix purple text bug | Replace undefined Tailwind classes with explicit hex values |
| 2026-01-23 | Dynamic stats | Create stats.ts to auto-count chapters/appendices at build |
| 2026-01-23 | Agentic Development | Replace "Open Source" feature card per user request |
| 2026-01-23 | Author GitHub links | Link Christopher Mercer to github.com/chris-mercer |
| 2026-01-23 | Light/Dark theme | Add toggle with localStorage persistence, default dark |
| 2026-01-23 | Site-wide theme | Convert ALL components/pages to CSS variables for proper theme support |
| 2026-01-23 | Milestone 6 complete | Prose typography and readability improvements in globals.css |
| 2026-01-23 | Milestone 7 complete | CSS-only BookDisplay.tsx is acceptable for initial release |
| 2026-01-23 | Milestone 8 complete | SEO metadata complete, image assets deferred |
| 2026-01-23 | Readability fix | Replaced #627EEA (Ethereum blue) with #5eead4 (bright teal) for text/links |
| 2026-01-23 | Organic Futurism | Added glass effects (backdrop-blur, glass-bg variables) to Header, Hero, cards |
| 2026-01-23 | Ethereum brand color | #627EEA now only for decorative elements, never for text (readability) |
| 2026-01-23 | Color palette v2 | Black/Orange/Green/Teal scheme - Alloy Orange #C36312, Teal Green #02807D, Sage Green #0E7F6C |
| 2026-01-23 | v0.1 complete | All milestones complete, codebase cleaned of legacy variables, ready for deployment |
