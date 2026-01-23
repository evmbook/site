# Mastering EVM - Website

The official website for [masteringevm.com](https://masteringevm.com).

## Tech Stack

- **Framework**: Next.js 15 with App Router
- **UI**: React 19
- **Styling**: Tailwind CSS 4
- **Content**: MDX with rehype-pretty-code
- **Deployment**: Vercel

## Getting Started

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
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
│   └── home/           # Landing page components
├── lib/                # Utilities
└── styles/             # Global CSS

content/                # Book content (from evmbook-v1)
├── chapters/           # MDX chapter files
├── appendices/         # Reference appendices
└── meta/               # Colophon, about
```

## Content Integration

The book content comes from the [evmbook-v1](https://github.com/evmbook/evmbook) repository.

To set up content:

```bash
# Option 1: Git submodule
git submodule add https://github.com/evmbook/evmbook.git evmbook-v1
ln -s evmbook-v1/content content

# Option 2: Copy during build (CI)
# See .github/workflows/deploy.yml
```

## Development

```bash
npm run dev     # Start dev server on http://localhost:3000
npm run build   # Production build
npm run lint    # Run ESLint
```

## License

- **Code**: MIT License
- **Content**: CC BY-SA 4.0 (see [evmbook-v1](https://github.com/evmbook/evmbook))
