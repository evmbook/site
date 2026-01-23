import { getChapters, getAppendices } from './content'

export interface BookStats {
  chapters: number // Excludes preface (chapter 0)
  appendices: number
  totalContent: number
}

/**
 * Get book statistics dynamically from content files.
 * This ensures stats are always accurate when content is added/removed.
 */
export function getBookStats(): BookStats {
  const chapters = getChapters()
  const appendices = getAppendices()

  // Count chapters excluding preface (chapter 0)
  const chapterCount = chapters.filter((c) => c.chapter && c.chapter > 0).length

  return {
    chapters: chapterCount,
    appendices: appendices.length,
    totalContent: chapters.length + appendices.length,
  }
}
