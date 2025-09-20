import React from 'react'
import { DocsThemeConfig } from 'nextra-theme-docs'
import { useRouter } from 'next/router'
import { useConfig } from 'nextra-theme-docs'

const config: DocsThemeConfig = {
    logo: (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <img src="/logo.png" alt="GoRouter Modular" width="32" height="32" />
            <span style={{ fontWeight: 'bold', fontSize: '18px' }}>GoRouter Modular</span>
        </div>
    ),
    project: {
        link: 'https://github.com/Flutterando/go_router_modular',
    },
    chat: {
        link: 'https://discord.gg/flutterando',
        icon: (
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20.317 4.370a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.211.375-.445.865-.608 1.250a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.370a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.010c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03z" />
            </svg>
        )
    },
    docsRepositoryBase: 'https://github.com/Flutterando/go_router_modular/tree/main/nextra_docs',
    footer: {
        text: (
            <div style={{ display: 'flex', width: '100%', justifyContent: 'space-between', alignItems: 'center' }}>
                <span>© 2024 Flutterando. Built with Nextra.</span>
                <div style={{ display: 'flex', gap: '16px' }}>
                    <a href="https://flutterando.com.br" target="_blank" rel="noopener noreferrer">
                        Flutterando
                    </a>
                    <a href="https://pub.dev/packages/go_router_modular" target="_blank" rel="noopener noreferrer">
                        pub.dev
                    </a>
                </div>
            </div>
        )
    },
    sidebar: {
        titleComponent: ({ title, type }) => {
            if (type === 'separator') {
                return <div style={{
                    background: 'var(--nextra-colors-gray-200)',
                    height: '1px',
                    margin: '8px 0'
                }} />
            }
            return <>{title}</>
        },
        defaultMenuCollapseLevel: 1,
        toggleButton: true
    },
    search: {
        placeholder: 'Buscar documentação...'
    },
    editLink: {
        text: 'Editar esta página no GitHub →'
    },
    feedback: {
        content: 'Dúvidas? Nos dê feedback →',
        labels: 'feedback'
    },
    toc: {
        title: 'Nesta página'
    },
    navigation: {
        prev: true,
        next: true
    },
    gitTimestamp: ({ timestamp }) => (
        <div style={{ fontSize: '14px', color: 'var(--nextra-colors-gray-500)' }}>
            Última atualização: {timestamp.toLocaleDateString('pt-BR')}
        </div>
    ),
    head: () => {
        const { asPath, defaultLocale, locale } = useRouter()
        const { frontMatter } = useConfig()
        const url = 'https://go-router-modular-docs.vercel.app' +
            (defaultLocale === locale ? asPath : `/${locale}${asPath}`)

        return (
            <>
                <meta property="og:url" content={url} />
                <meta property="og:title" content={frontMatter.title || 'GoRouter Modular'} />
                <meta property="og:description" content={frontMatter.description || 'Documentação oficial do GoRouter Modular - Sistema modular de navegação para Flutter.'} />
                <meta property="og:image" content="/banner.png" />
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:image" content="/banner.png" />
                <meta name="twitter:site:domain" content="go-router-modular-docs.vercel.app" />
                <meta name="twitter:url" content={url} />
                <link rel="icon" href="/favicon.ico" type="image/x-icon" />
                <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
                <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
                <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
            </>
        )
    },
    useNextSeoProps() {
        const { asPath } = useRouter()
        if (asPath !== '/') {
            return {
                titleTemplate: '%s – GoRouter Modular'
            }
        }
    }
}

export default config
