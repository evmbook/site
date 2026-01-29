# Mastering EVM (2025 Edition) — Website

The official website for [masteringevm.com](https://masteringevm.com).

## Source of Truth

**The book repo ([evmbook-v2025](../evmbook-v2025)) is authoritative for all content.**

The website syncs the following from the book repo:
- `content/chapters/` — 28 chapters (MDX)
- `content/appendices/` — 8 appendices (MDX)
- `content/chapters/_index.json` — Canonical TOC
- `content/code/` — Code examples (Solidity, TypeScript)
- `public/diagrams/` — Technical diagrams (SVG)

## Content Sync

To sync content from the book repo:

```bash
# Copy all content from book repo
cp -r ../evmbook-v2025/content/chapters/*.mdx content/chapters/
cp ../evmbook-v2025/content/chapters/_index.json content/chapters/
cp -r ../evmbook-v2025/content/appendices/*.mdx content/appendices/
cp -r ../evmbook-v2025/code/* content/code/
cp ../evmbook-v2025/images/diagrams/*.svg public/diagrams/
```

**After syncing, update:**
1. `src/components/layout/Sidebar.tsx` — Match chapters/appendices arrays to `_index.json`
2. `src/components/layout/Footer.tsx` — Update chapter/appendix counts
3. `public/sitemap.xml` — Regenerate with all chapter/appendix URLs

## Tech Stack

- **Framework**: Next.js 15 with App Router (static export)
- **UI**: React 19
- **Styling**: Tailwind CSS 4
- **Content**: MDX with rehype-pretty-code
- **Fonts**: Inter, Space Grotesk, JetBrains Mono
- **Deployment**: Vercel (static export to `out/`)

## Getting Started

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Format code
npm run format
```

## Project Structure

```
src/
├── app/
│   ├── page.tsx         # Landing page
│   ├── read/            # Book reader (chapters, appendices)
│   ├── code/            # Code library
│   ├── diagrams/        # Diagram gallery
│   ├── download/        # Download options
│   └── about/           # About page
├── components/
│   ├── layout/          # Header, Footer, Sidebar
│   ├── content/         # MDX components, ChapterNav
│   └── home/            # Landing page components
├── lib/                 # Utilities (content loading, animations)
└── styles/              # Global CSS (theme variables)

content/                 # Book content (synced from evmbook-v2025)
├── chapters/            # 28 MDX chapter files
├── appendices/          # 8 MDX appendix files
├── code/                # Solidity & TypeScript examples
└── meta/                # Colophon, about

public/
├── diagrams/            # 18 SVG technical diagrams
└── ...                  # Favicons, OG images
```

## Anti-Regression Checklist

Before deploying, verify:

### Content Alignment
- [ ] **28 chapters present**: `ls content/chapters/*.mdx | wc -l` = 28
- [ ] **8 appendices present**: `ls content/appendices/*.mdx | wc -l` = 8
- [ ] **_index.json matches book**: Compare with `evmbook-v2025/content/chapters/_index.json`

### Navigation
- [ ] **Sidebar matches TOC**: All 28 chapters + 8 appendices listed in `Sidebar.tsx`
- [ ] **Footer stats correct**: Shows "28 Chapters | 8 Appendices"
- [ ] **Sitemap complete**: All chapter/appendix URLs present

### Routes
- [ ] **Build succeeds**: `npm run build` completes without errors
- [ ] **No 404s**: All sidebar links resolve to actual pages
- [ ] **Code library works**: `/code` page renders
- [ ] **Diagrams render**: `/diagrams` page shows all 18 diagrams

### Content Accuracy
- [ ] **Author bio matches back cover**: About page uses exact back cover copy
- [ ] **License is correct**: CC BY-NC 4.0 (not CC BY-SA)
- [ ] **No unverified claims**: All features match actual book content

## Design System

**Colors** (from book cover):
- Primary: `#627EEA` (Indigo)
- Secondary: `#8B5CF6` (Purple)
- Tertiary: `#3AB83A` (Green)
- Background: `#0a0a1a` → `#1a1a3a`

**Typography**:
- Headers: Space Grotesk
- Body: Inter
- Code: JetBrains Mono

## License

- **Website Code**: MIT License
- **Book Content**: CC BY-NC 4.0 (see evmbook-v2025)
- **Author**: Christopher Mercer with Claude (Anthropic)
- **Publisher**: White B0x Inc.
