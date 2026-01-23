import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'
import { unified } from 'unified'
import remarkParse from 'remark-parse'
import remarkGfm from 'remark-gfm'
import remarkRehype from 'remark-rehype'
import rehypeRaw from 'rehype-raw'
import rehypeSlug from 'rehype-slug'
import rehypePrettyCode from 'rehype-pretty-code'
import rehypeStringify from 'rehype-stringify'

const CONTENT_DIR = path.join(process.cwd(), 'content')
const CHAPTERS_DIR = path.join(CONTENT_DIR, 'chapters')
const APPENDICES_DIR = path.join(CONTENT_DIR, 'appendices')
const META_DIR = path.join(CONTENT_DIR, 'meta')

export interface ChapterMeta {
  slug: string
  title: string
  description?: string
  chapter?: number
}

export interface Chapter extends ChapterMeta {
  content: string
}

// Create the unified processor for markdown to HTML conversion
async function processMarkdown(content: string): Promise<string> {
  const result = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype, { allowDangerousHtml: true })
    .use(rehypeRaw)
    .use(rehypeSlug)
    .use(rehypePrettyCode, {
      theme: 'github-dark',
      keepBackground: true,
    })
    .use(rehypeStringify)
    .process(content)

  return String(result)
}

// Strip out JSX components like <Callout> and convert to blockquotes for now
function preprocessMdx(content: string): string {
  // Convert <Callout type="..."> ... </Callout> to blockquotes
  // Handle both self-closing and regular tags
  let processed = content

  // Match <Callout type="..." title="..."> ... </Callout> patterns
  const calloutRegex = /<Callout\s+type="(\w+)"(?:\s+title="([^"]*)")?\s*>([\s\S]*?)<\/Callout>/g
  processed = processed.replace(calloutRegex, (_, type, title, innerContent) => {
    const prefix = type === 'warning' ? '⚠️ **Warning**' :
                   type === 'tip' ? '💡 **Tip**' :
                   type === 'note' ? '📝 **Note**' :
                   'ℹ️ **Info**'
    const titlePart = title ? `: ${title}` : ''
    return `> ${prefix}${titlePart}\n>\n> ${innerContent.trim().split('\n').join('\n> ')}\n`
  })

  return processed
}

export function getChapters(): ChapterMeta[] {
  if (!fs.existsSync(CHAPTERS_DIR)) {
    return []
  }

  const files = fs.readdirSync(CHAPTERS_DIR)
  const chapters = files
    .filter((file) => file.endsWith('.mdx') || file.endsWith('.md'))
    .map((file) => {
      const filePath = path.join(CHAPTERS_DIR, file)
      const fileContents = fs.readFileSync(filePath, 'utf8')
      const { data } = matter(fileContents)
      const slug = file.replace(/\.mdx?$/, '')

      return {
        slug,
        title: data.title || slug,
        description: data.description,
        chapter: data.chapter,
      }
    })
    .sort((a, b) => (a.chapter ?? 99) - (b.chapter ?? 99))

  return chapters
}

export async function getChapter(slug: string): Promise<Chapter | null> {
  const mdxPath = path.join(CHAPTERS_DIR, `${slug}.mdx`)
  const mdPath = path.join(CHAPTERS_DIR, `${slug}.md`)

  let filePath: string
  if (fs.existsSync(mdxPath)) {
    filePath = mdxPath
  } else if (fs.existsSync(mdPath)) {
    filePath = mdPath
  } else {
    return null
  }

  const fileContents = fs.readFileSync(filePath, 'utf8')
  const { data, content } = matter(fileContents)

  // Preprocess MDX to handle JSX components
  const preprocessed = preprocessMdx(content)
  // Compile markdown to HTML
  const html = await processMarkdown(preprocessed)

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    chapter: data.chapter,
    content: html,
  }
}

export function getAppendices(): ChapterMeta[] {
  if (!fs.existsSync(APPENDICES_DIR)) {
    return []
  }

  const files = fs.readdirSync(APPENDICES_DIR)
  const appendices = files
    .filter((file) => file.endsWith('.mdx') || file.endsWith('.md'))
    .map((file) => {
      const filePath = path.join(APPENDICES_DIR, file)
      const fileContents = fs.readFileSync(filePath, 'utf8')
      const { data } = matter(fileContents)
      const slug = file.replace(/\.mdx?$/, '')

      return {
        slug,
        title: data.title || slug,
        description: data.description,
      }
    })
    .sort((a, b) => a.slug.localeCompare(b.slug))

  return appendices
}

export async function getAppendix(slug: string): Promise<Chapter | null> {
  const mdxPath = path.join(APPENDICES_DIR, `${slug}.mdx`)
  const mdPath = path.join(APPENDICES_DIR, `${slug}.md`)

  let filePath: string
  if (fs.existsSync(mdxPath)) {
    filePath = mdxPath
  } else if (fs.existsSync(mdPath)) {
    filePath = mdPath
  } else {
    return null
  }

  const fileContents = fs.readFileSync(filePath, 'utf8')
  const { data, content } = matter(fileContents)

  // Preprocess MDX to handle JSX components
  const preprocessed = preprocessMdx(content)
  // Compile markdown to HTML
  const html = await processMarkdown(preprocessed)

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    content: html,
  }
}

export async function getMetaPage(slug: string): Promise<Chapter | null> {
  const mdxPath = path.join(META_DIR, `${slug}.mdx`)
  const mdPath = path.join(META_DIR, `${slug}.md`)

  let filePath: string
  if (fs.existsSync(mdxPath)) {
    filePath = mdxPath
  } else if (fs.existsSync(mdPath)) {
    filePath = mdPath
  } else {
    return null
  }

  const fileContents = fs.readFileSync(filePath, 'utf8')
  const { data, content } = matter(fileContents)

  // Preprocess MDX to handle JSX components
  const preprocessed = preprocessMdx(content)
  // Compile markdown to HTML
  const html = await processMarkdown(preprocessed)

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    content: html,
  }
}

export function getAllSlugs(): string[] {
  const chapters = getChapters().map((c) => c.slug)
  const appendices = getAppendices().map((a) => `appendix/${a.slug}`)
  return [...chapters, ...appendices]
}
