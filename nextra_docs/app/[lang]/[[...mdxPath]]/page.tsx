import fs from 'node:fs'
import path from 'node:path'
import { importPage } from 'nextra/pages'
import type { FC } from 'react'
import { useMDXComponents as getMDXComponents } from '../../../mdx-components'

const LANGUAGES = ['en', 'pt']
const CONTENT_DIR = path.join(process.cwd(), 'content')

// Walk a locale's content folder and turn each `.mdx` file into route segments.
// `index.mdx` maps to its parent folder, so `routes/` (no index) never produces
// a phantom route.
function collectMdxPaths(dir: string, base: string[] = []): string[][] {
  const result: string[][] = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      result.push(...collectMdxPaths(path.join(dir, entry.name), [...base, entry.name]))
      continue
    }
    if (!entry.name.endsWith('.mdx')) continue
    const name = entry.name.replace(/\.mdx$/, '')
    result.push(name === 'index' ? base : [...base, name])
  }
  return result
}

export async function generateStaticParams() {
  const params: { lang: string; mdxPath: string[] }[] = []
  for (const lang of LANGUAGES) {
    for (const mdxPath of collectMdxPaths(path.join(CONTENT_DIR, lang))) {
      params.push({ lang, mdxPath })
    }
  }
  return params
}

type PageProps = Readonly<{
  params: Promise<{ mdxPath?: string[]; lang: string }>
}>

function contentPath(lang: string, mdxPath?: string[]): string[] {
  return [lang, ...(mdxPath ?? [])]
}

export async function generateMetadata(props: PageProps) {
  const params = await props.params
  const { metadata } = await importPage(contentPath(params.lang, params.mdxPath))
  return metadata
}

const Wrapper = getMDXComponents().wrapper

const Page: FC<PageProps> = async props => {
  const params = await props.params
  const result = await importPage(contentPath(params.lang, params.mdxPath))
  const { default: MDXContent, toc, metadata, sourceCode } = result
  return (
    <Wrapper toc={toc} metadata={metadata} sourceCode={sourceCode}>
      <MDXContent {...props} params={params} />
    </Wrapper>
  )
}

export default Page
