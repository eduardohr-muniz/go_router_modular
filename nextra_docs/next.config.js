const withNextra = require('nextra')({
    theme: 'nextra-theme-docs',
    themeConfig: './theme.config.tsx'
})

module.exports = withNextra({
    output: 'export',
    trailingSlash: true,
    images: {
        unoptimized: true
    },
    eslint: {
        ignoreDuringBuilds: true
    },
    typescript: {
        ignoreBuildErrors: true
    }
})
