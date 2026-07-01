import type { Metadata } from 'next'
import { Footer, Layout, Navbar, LocaleSwitch } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import type { FC, ReactNode } from 'react'
import 'nextra-theme-docs/style.css'

const REPO = 'https://github.com/eduardohr-muniz/go_router_modular'
// Prefix static assets with the GitHub Pages basePath (empty in dev/local).
const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? ''

export const metadata: Metadata = {
  title: {
    absolute: '',
    template: '%s – go_router_modular'
  },
  description:
    'Modular dependency injection and per-module routing on top of go_router for Flutter.',
  icons: { icon: `${BASE}/favicon.png` }
}

type LayoutProps = Readonly<{
  children: ReactNode
  params: Promise<{ lang: string }>
}>

const RootLayout: FC<LayoutProps> = async ({ children, params }) => {
  const { lang } = await params
  const pageMap = await getPageMap(`/${lang}`)

  const logo = (
    <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={`${BASE}/logo-small.png`}
        alt="go_router_modular"
        width={28}
        height={28}
      />
      <b>go_router_modular</b>
    </span>
  )

  const navbar = (
    <Navbar logo={logo} projectLink={REPO}>
      <LocaleSwitch lite />
    </Navbar>
  )

  const footer = (
    <Footer>
      MIT {new Date().getFullYear()} © go_router_modular
    </Footer>
  )

  return (
    <html lang={lang} dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          navbar={navbar}
          footer={footer}
          pageMap={pageMap}
          docsRepositoryBase={`${REPO}/tree/master/nextra_docs`}
          i18n={[
            { locale: 'en', name: 'English' },
            { locale: 'pt', name: 'Português' }
          ]}
          sidebar={{ defaultMenuCollapseLevel: 1, autoCollapse: true }}
          editLink="Edit this page on GitHub"
          feedback={{ content: null }}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}

export default RootLayout
