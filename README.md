# Mastering EVM (2025 Edition) — Website

The official website for [masteringevm.com](https://masteringevm.com).

## Source of Truth

**The book repo ([evmbook-v2025](../evmbook-v2025)) is authoritative for all content.**

When updating website copy, always verify against the book:
- Chapter names and structure → `evmbook-v2025/content/chapters/_index.json`
- Author bio → Back cover in `evmbook-v2025/images/covers/cover-back.svg`
- Book metadata → `evmbook-v2025/publishing/book-metadata.yaml`
- Preface framing → `evmbook-v2025/content/chapters/00-preface.mdx`

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
├── app/                 # Next.js App Router pages
│   ├── page.tsx        # Landing page
│   ├── read/           # Book reader
│   ├── download/       # Download options
│   └── about/          # About page
├── components/
│   ├── layout/         # Header, Footer, Sidebar
│   ├── content/        # MDX components, ChapterNav
│   └── home/           # Landing page components (Hero, Features)
├── lib/                # Utilities (content loading, animations)
└── styles/             # Global CSS (theme variables)

content/                # Book content (sourced from evmbook-v2025)
├── chapters/           # MDX chapter files (28 chapters)
├── appendices/         # Reference appendices (8 appendices)
└── meta/               # Colophon, about

public/                 # Static assets (favicons, OG images)
```

## Content Integration

The book content comes from the [evmbook-v2025](../evmbook-v2025) repository.

```bash
# Content is typically copied or symlinked from the book repo
ln -s ../evmbook-v2025/content content
```

## Release Checklist

Before deploying, verify:

- [ ] **TOC matches book**: Sidebar chapters match `evmbook-v2025/content/chapters/_index.json`
- [ ] **Author bio matches back cover**: About page uses exact back cover copy
- [ ] **License is correct**: CC BY-NC 4.0 (not CC BY-SA)
- [ ] **No unverified claims**: All features/promises are supported by book content
- [ ] **Stats are accurate**: Chapter count (28), appendix count (8)
- [ ] **Routes still work**: All existing URLs resolve correctly

## Design System

The site uses a systems-engineering theme aligned with the book cover:

**Colors** (from cover):
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
