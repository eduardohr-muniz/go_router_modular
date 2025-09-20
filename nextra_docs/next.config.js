const withNextra = require('nextra')({
    theme: 'nextra-theme-docs',
    themeConfig: './theme.config.tsx'
})

// GitHub Pages basePath/assetPrefix
const isGithubActions = process.env.GITHUB_ACTIONS || false
let assetPrefix = ''
let basePath = ''

if (isGithubActions) {
  const repo = process.env.GITHUB_REPOSITORY?.replace(/.*?\//, '') || 'go_router_modular'
  assetPrefix = `/${repo}/`
  basePath = `/${repo}`
}

module.exports = withNextra({
    output: 'export',
    trailingSlash: true,
    images: { unoptimized: true },
    assetPrefix,
    basePath,
    eslint: { ignoreDuringBuilds: true },
    typescript: { ignoreBuildErrors: true },
    experimental: { esmExternals: false },
    webpack: (config) => {
        // Desabilita cache de filesystem para evitar warnings e travas em alguns ambientes
        if (config.cache && config.cache.type === 'filesystem') {
            config.cache = false
        }
        return config
    }
})
