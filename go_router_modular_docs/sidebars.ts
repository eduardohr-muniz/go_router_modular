import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  // Main documentation sidebar - todas as páginas
  docsSidebar: [
    'intro',
    'installation',
    'getting-started',
    'quick-start',
    'project-structure',
    'dependency-injection',
    'routes',
    'event-system',
    'loader-system',
    'micro-frontend',
    'migration',
    'api-reference',
  ],

  // API Reference sidebar - será criada depois
  // apiSidebar: [
  //   {
  //     type: 'category',
  //     label: '📖 API Reference',
  //     items: [
  //       'api/overview',
  //       'api/module',
  //       'api/event-module',
  //     ],
  //   },
  // ],
};

export default sidebars;
