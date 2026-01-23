import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'

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

export function getChapter(slug: string): Chapter | null {
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

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    chapter: data.chapter,
    content,
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

export function getAppendix(slug: string): Chapter | null {
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

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    content,
  }
}

export function getMetaPage(slug: string): Chapter | null {
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

  return {
    slug,
    title: data.title || slug,
    description: data.description,
    content,
  }
}

export function getAllSlugs(): string[] {
  const chapters = getChapters().map((c) => c.slug)
  const appendices = getAppendices().map((a) => `appendix/${a.slug}`)
  return [...chapters, ...appendices]
}
