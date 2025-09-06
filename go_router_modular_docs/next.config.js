const withNextra = require('nextra')({
    theme: 'nextra-theme-docs',
    themeConfig: './theme.config.tsx',
    latex: true,
    flexsearch: {
        codeblocks: false
    },
    defaultShowCopyCode: true
})

module.exports = withNextra({
    basePath: '/go_router_modular',
    assetPrefix: '/go_router_modular/',
    output: 'export',
    trailingSlash: true,
    images: {
        unoptimized: true
    }
})
