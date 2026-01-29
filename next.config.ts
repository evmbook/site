import type { NextConfig } from 'next'
import createMDX from '@next/mdx'
import rehypePrettyCode from 'rehype-pretty-code'
import rehypeSlug from 'rehype-slug'
import rehypeAutolinkHeadings from 'rehype-autolink-headings'
import remarkGfm from 'remark-gfm'

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  pageExtensions: ['js', 'jsx', 'ts', 'tsx', 'md', 'mdx'],
  eslint: {
    // Use ESLint CLI directly instead of Next.js built-in linting
    ignoreDuringBuilds: true,
  },
  // Use polling for file watching to avoid inotify limits
  // and exclude code examples directory
  webpack: (config, { dev }) => {
    if (dev) {
      config.watchOptions = {
        ...config.watchOptions,
        poll: 1000, // Check for changes every 1 second
        aggregateTimeout: 300,
        ignored: ['**/content/code/**', '**/node_modules/**', '**/.git/**'],
      }
    }
    return config
  },
}

const withMDX = createMDX({
  extension: /\.mdx?$/,
  options: {
    remarkPlugins: [remarkGfm],
    rehypePlugins: [
      rehypeSlug,
      [
        rehypePrettyCode,
        {
          theme: 'github-dark',
          keepBackground: true,
        },
      ],
      [
        rehypeAutolinkHeadings,
        {
          behavior: 'wrap',
          properties: {
            className: ['anchor'],
          },
        },
      ],
    ],
  },
})

export default withMDX(nextConfig)
