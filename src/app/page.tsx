import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Hero } from '@/components/home/Hero'
import { Features } from '@/components/home/Features'
import { DownloadCTA } from '@/components/home/DownloadCTA'
import { getBookStats } from '@/lib/stats'

export default function HomePage() {
  // Get stats at build time (Server Component)
  const stats = getBookStats()

  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <main className="flex-1">
        <Hero stats={stats} />
        <Features />
        <DownloadCTA />
      </main>
      <Footer />
    </div>
  )
}
