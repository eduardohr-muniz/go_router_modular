const withNextra = require('nextra')({
    theme: 'nextra-theme-docs',
    themeConfig: './theme.config.tsx',
    latex: true,
    search: {
        codeblocks: false
    },
    defaultShowCopyCode: true
})

module.exports = withNextra({
    output: 'standalone',
    trailingSlash: false,
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
