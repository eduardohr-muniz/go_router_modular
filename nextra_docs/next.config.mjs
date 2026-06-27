import nextra from 'nextra'

const withNextra = nextra({
  defaultShowCopyCode: true,
  contentDirBasePath: '/'
})

// GitHub Pages serves the site under /<repo>/. Apply basePath only on CI.
const isGithubActions =
  process.env.GITHUB_ACTIONS === 'true' || process.env.GITHUB_ACTIONS === '1'
const repository =
  process.env.GITHUB_REPOSITORY?.replace(/.*?\//, '') || 'go_router_modular'
const basePath = isGithubActions ? `/${repository}` : ''

export default withNextra({
  output: 'export',
  images: { unoptimized: true },
  trailingSlash: true,
  basePath,
  typescript: { ignoreBuildErrors: true },
  // The repo lives on an external volume where webpack's filesystem cache
  // fails to snapshot dependencies; disable it to keep builds reliable.
  webpack(config) {
    if (config.cache && config.cache.type === 'filesystem') {
      config.cache = false
    }
    return config
  }
})
