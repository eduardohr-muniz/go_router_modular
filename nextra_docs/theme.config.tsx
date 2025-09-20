import React from 'react'
import { DocsThemeConfig } from 'nextra-theme-docs'

const config: DocsThemeConfig = {
    logo: <span style={{ fontWeight: 'bold' }}>🛣️ GoRouter Modular</span>,
    project: {
        link: 'https://github.com/Flutterando/go_router_modular',
    },
    docsRepositoryBase: 'https://github.com/Flutterando/go_router_modular/tree/main/nextra_docs',
    footer: {
        text: '© 2024 Flutterando. Built with Nextra.'
    },
    search: {
        placeholder: 'Search documentation...'
    },
    editLink: {
        text: 'Edit this page on GitHub →'
    },
    feedback: {
        content: 'Question? Give us feedback →'
    },
    toc: {
        title: 'On This Page'
    }
}

export default config