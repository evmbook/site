import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Sidebar } from '@/components/layout/Sidebar'

export default function ReadLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <div className="flex-1 flex">
        <Sidebar />
        <main className="flex-1 overflow-auto">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 py-12">
            {children}
          </div>
        </main>
      </div>
      <Footer />
    </div>
  )
}
