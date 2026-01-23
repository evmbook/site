import { notFound } from 'next/navigation'
import { getAppendix, getAppendices } from '@/lib/content'
import { ChapterNav } from '@/components/content/ChapterNav'

interface PageProps {
  params: Promise<{ slug: string }>
}

export async function generateStaticParams() {
  const appendices = getAppendices()
  return appendices.map((appendix) => ({
    slug: appendix.slug,
  }))
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params
  const appendix = await getAppendix(slug)
  if (!appendix) {
    return { title: 'Not Found' }
  }
  return {
    title: appendix.title,
    description: appendix.description,
  }
}

export default async function AppendixPage({ params }: PageProps) {
  const { slug } = await params
  const appendix = await getAppendix(slug)

  if (!appendix) {
    notFound()
  }

  const appendices = getAppendices()
  const currentIndex = appendices.findIndex((a) => a.slug === slug)
  const prevAppendix = currentIndex > 0 ? appendices[currentIndex - 1] : null
  const nextAppendix = currentIndex < appendices.length - 1 ? appendices[currentIndex + 1] : null

  return (
    <article>
      <div className="prose max-w-none">
        <h1>{appendix.title}</h1>
        {appendix.description && (
          <p className="lead">
            {appendix.description}
          </p>
        )}
        <hr />
        <div
          dangerouslySetInnerHTML={{ __html: appendix.content }}
        />
      </div>

      <ChapterNav
        prev={prevAppendix ? { ...prevAppendix, slug: `appendix/${prevAppendix.slug}` } : null}
        next={nextAppendix ? { ...nextAppendix, slug: `appendix/${nextAppendix.slug}` } : null}
      />
    </article>
  )
}
