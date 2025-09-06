# GoRouter Modular Documentation

Documentação do GoRouter Modular construída com Nextra.

## 🚀 Desenvolvimento

```bash
# Instalar dependências
npm install

# Executar em modo de desenvolvimento
npm run dev

# Construir para produção
npm run build

# Iniciar servidor de produção
npm start
```

## 📁 Estrutura

```
pages/
├── index.mdx              # Página inicial
├── docs/
│   ├── _meta.json         # Configuração da sidebar
│   ├── index.mdx          # Introdução
│   ├── installation.mdx   # Instalação
│   ├── getting-started.mdx # Primeiros passos
│   ├── quick-start.mdx    # Início rápido
│   ├── routes.mdx         # Visão geral das rotas
│   ├── child_and_module_routes.mdx # Rotas filhas e módulos
│   ├── navigation.mdx     # Navegação
│   ├── shell.mdx          # Módulos shell
│   ├── dependency-injection.mdx # Injeção de dependência
│   ├── event-system.mdx   # Sistema de eventos
│   ├── loader-system.mdx  # Sistema de carregamento
│   ├── project-structure.mdx # Estrutura do projeto
│   ├── micro-frontend.mdx # Arquitetura micro frontend
│   └── migration.mdx      # Guia de migração
├── _app.tsx               # Configuração do app
└── _meta.json             # Configuração da sidebar principal
```

## 🎨 Configuração

- **Tema**: Nextra Theme Docs
- **Base Path**: `/go_router_modular`
- **Output**: Static export
- **Suporte**: Mermaid diagrams, busca, modo escuro

## 📝 Adicionando Nova Documentação

1. Crie um novo arquivo `.mdx` em `pages/docs/`
2. Adicione a entrada correspondente em `pages/docs/_meta.json`
3. Use a sintaxe MDX para componentes React quando necessário

## 🔧 Configurações

- **next.config.js**: Configuração do Next.js com Nextra
- **theme.config.tsx**: Configuração do tema e metadados
- **tsconfig.json**: Configuração do TypeScript