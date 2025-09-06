import React from 'react'
import { DocsThemeConfig } from 'nextra-theme-docs'

const config: DocsThemeConfig = {
    logo: (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <img src="/go_router_modular/img/logo.png" alt="GoRouter Modular" width="32" height="32" />
            <span style={{ fontWeight: 'bold' }}>GoRouter Modular</span>
        </div>
    ),
    project: {
        link: 'https://github.com/eduardohr-muniz/go_router_modular',
    },
    chat: {
        link: 'https://github.com/eduardohr-muniz/go_router_modular/discussions',
    },
    docsRepositoryBase: 'https://github.com/eduardohr-muniz/go_router_modular/edit/main/go_router_modular_docs/',
    footer: {
        text: (
            <span>
                Copyright © {new Date().getFullYear()} GoRouter Modular. Built with 💙 by Eduardo HR Muniz using Nextra.
            </span>
        ),
    },
    head: (
        <>
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <meta property="og:title" content="GoRouter Modular" />
            <meta property="og:description" content="Simplifying Flutter development with modular architecture 🧩" />
            <meta property="og:image" content="/go_router_modular/img/go-router-modular-social.jpg" />
            <link rel="icon" href="/go_router_modular/img/favicon.ico" />
        </>
    ),
    search: {
        placeholder: 'Search documentation...',
    },
    sidebar: {
        titleComponent({ title, type }) {
            if (type === 'separator') {
                return <span className="cursor-default">{title}</span>
            }
            return <>{title}</>
        },
        defaultMenuCollapseLevel: 1,
        toggleButton: true
    },
    toc: {
        backToTop: true
    },
    editLink: {
        text: 'Edit this page on GitHub →'
    },
    feedback: {
        content: 'Question? Give us feedback →',
        labels: 'feedback'
    },
    gitTimestamp: ({ timestamp }) => (
        <div>Last updated on {timestamp.toDateString()}</div>
    ),
    darkMode: true,
    nextThemes: {
        defaultTheme: 'light'
    }
}

export default config
