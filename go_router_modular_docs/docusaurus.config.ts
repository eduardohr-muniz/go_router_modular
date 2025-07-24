import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'GoRouter Modular',
  tagline: 'Simplifying Flutter development with modular architecture 🧩',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://eduardohr-muniz.github.io',
  baseUrl: '/go_router_modular/',

  organizationName: 'eduardohr-muniz',
  projectName: 'go_router_modular',

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'pt'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/eduardohr-muniz/go_router_modular/edit/main/go_router_modular_docs/',
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          editUrl: 'https://github.com/eduardohr-muniz/go_router_modular/edit/main/go_router_modular_docs/',
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'warn',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],

  themeConfig: {
    image: 'img/go-router-modular-social.jpg',
    navbar: {
      title: 'GoRouter Modular',
      logo: {
        alt: 'GoRouter Modular Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: '📚 Docs',
        },
        // API sidebar será adicionada depois
        // {
        //   type: 'docSidebar',
        //   sidebarId: 'apiSidebar',
        //   position: 'left',
        //   label: '📖 API',
        // },
        { to: '/blog', label: '📝 Blog', position: 'left' },
        {
          type: 'localeDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/eduardohr-muniz/go_router_modular',
          label: 'GitHub',
          position: 'right',
        },
        {
          href: 'https://pub.dev/packages/go_router_modular',
          label: 'pub.dev',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: '📚 Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'Installation',
              to: '/docs/installation',
            },
            {
              label: 'API Reference',
              to: '/docs/api-reference',
            },
          ],
        },
        {
          title: '🧩 Features',
          items: [
            {
              label: 'Dependency Injection',
              to: '/docs/dependency-injection',
            },
            {
              label: 'Event System',
              to: '/docs/event-system',
            },
            {
              label: 'Routes',
              to: '/docs/routes',
            },
          ],
        },
        {
          title: '🌐 Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/eduardohr-muniz/go_router_modular',
            },
            {
              label: 'pub.dev',
              href: 'https://pub.dev/packages/go_router_modular',
            },
            {
              label: 'Issues',
              href: 'https://github.com/eduardohr-muniz/go_router_modular/issues',
            },
          ],
        },
        {
          title: '🚀 More',
          items: [
            {
              label: 'Quick Start',
              to: '/docs/quick-start',
            },
            {
              label: 'Migration Guide',
              to: '/docs/migration',
            },
            {
              label: 'Blog',
              to: '/blog',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} GoRouter Modular. Built with 💙 by Eduardo HR Muniz using Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml'],
    },
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    // Algolia search (configure later with real credentials)
    // algolia: {
    //   appId: 'YOUR_APP_ID',
    //   apiKey: 'YOUR_SEARCH_API_KEY',
    //   indexName: 'go_router_modular',
    //   contextualSearch: true,
    // },
  } satisfies Preset.ThemeConfig,
};

export default config;
