import { notFound } from 'next/navigation'
import { getChapter, getChapters } from '@/lib/content'
import { ChapterNav } from '@/components/content/ChapterNav'

interface PageProps {
  params: Promise<{ slug: string }>
}

export async function generateStaticParams() {
  const chapters = getChapters()
  return chapters.map((chapter) => ({
    slug: chapter.slug,
  }))
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params
  const chapter = await getChapter(slug)
  if (!chapter) {
    return { title: 'Not Found' }
  }
  return {
    title: chapter.title,
    description: chapter.description,
  }
}

export default async function ChapterPage({ params }: PageProps) {
  const { slug } = await params
  const chapter = await getChapter(slug)

  if (!chapter) {
    notFound()
  }

  const chapters = getChapters()
  const currentIndex = chapters.findIndex((c) => c.slug === slug)
  const prevChapter = currentIndex > 0 ? chapters[currentIndex - 1] : null
  const nextChapter = currentIndex < chapters.length - 1 ? chapters[currentIndex + 1] : null

  return (
    <article>
      <div className="prose max-w-none">
        <h1>{chapter.title}</h1>
        {chapter.description && (
          <p className="lead">
            {chapter.description}
          </p>
        )}
        <hr />
        <div
          dangerouslySetInnerHTML={{ __html: chapter.content }}
        />
      </div>

      <ChapterNav prev={prevChapter} next={nextChapter} />
    </article>
  )
}
