import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  // Main documentation sidebar - todas as páginas
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'installation',
        'getting-started',
        'quick-start',
      ],
    },
    {
      type: 'category',
      label: 'Routes',
      items: [
        'routes_overview',
        'navigation',
        'shell',
        'child_and_module_routes',

      ],
    },
    'dependency-injection',
    {
      type: 'category',
      label: 'Advanced',
      items: [
        'event-system',
        'micro-frontend',
        'loader-system',
      ],
    },
    {
      type: 'category',
      label: 'Core Concepts',
      items: [
        'project-structure',
      ],
    },
    'migration',
  ],


};

export default sidebars;
