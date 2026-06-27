## Why

A documentação atual em `nextra_docs/` está em Nextra 2 (Pages Router), com um único idioma e conteúdo desatualizado — em especial o subsistema de eventos, que mudou (remoção de `ModularEventListener`, `eventImports()` e `EventListenerMixin`; composição agora via `OutroEventModule().listen()`). O usuário precisa de uma documentação reescrita do zero, **correta** e mantida em **dois idiomas (inglês e português)**.

Reconstruir sobre **Nextra 4 (App Router)** com i18n nativo (`[lang]` + `generateStaticParams`) entrega a forma idiomática e moderna, compatível com export estático no GitHub Pages, e estabelece uma base alinhada à fonte de verdade do projeto (as specs em `openspec/specs/` e a superfície pública em `lib/go_router_modular.dart`). Isso aplica Clean Code à documentação: remover conteúdo morto/incorreto, nomes claros, sem duplicação, e uma única fonte de navegação por idioma.

## What Changes

- **BREAKING (docs)** — Remover por completo o conteúdo atual de `nextra_docs/pages/` (Pages Router, `_meta.json`, `theme.config.tsx`) e a estrutura Nextra 2.
- Migrar a infraestrutura para **Nextra 4 + Next.js App Router**: `app/layout.tsx`, `app/[lang]/layout.tsx`, `mdx-components.js`, `content/` por idioma, `_meta.{en,pt}` (ou `_meta.global`), atualizando `next.config.mjs` para manter `output: 'export'` e o `basePath`/`assetPrefix` do GitHub Pages.
- Implementar **i18n com prefixo de locale**: rotas `/en/...` e `/pt/...`, idioma padrão **inglês**, raiz `/` redirecionando para `/en`, com **language switcher** funcional no export estático.
- Reescrever **todo o conteúdo com paridade total EN/PT**, cobrindo: Home, Getting Started (Quick Start, Migration Guide), Routes & Modules (routes-system, shell-route, navigation, transitions + examples, loader-system, redirects), Dependency Injection, Event Module (overview atualizado, ModularEventMixin), Micro Frontends, Testing (overview, testing events, unit testing/FakeInjector) e Changelog.
- Garantir **exatidão técnica**: cada página reflete o comportamento descrito nas specs (`openspec/specs/`) e usa apenas símbolos da superfície pública atual (sem `ModularEventListener`/`eventImports()`/`EventListenerMixin`).
- Atualizar scripts de build/deploy (`package.json`, `build.sh`, `DEPLOYMENT.md`) para o fluxo Nextra 4 e validar o build estático.

## Não-objetivos

- Não alterar o código do pacote Dart (`lib/`), seus testes ou comportamento — apenas a documentação.
- Não adicionar idiomas além de inglês e português.
- Não trocar o hosting (permanece GitHub Pages com export estático); não introduzir backend/SSR.
- Não redesenhar identidade visual/branding além do necessário para o tema Nextra 4 funcionar.
- Não criar versionamento de documentação (docs por versão) nesta entrega.

## Capabilities

### New Capabilities

- `documentation-site`: Comportamento e requisitos do site de documentação — stack (Nextra 4/App Router), i18n (`/en` e `/pt`, padrão inglês, raiz redireciona, switcher), export estático para GitHub Pages, estrutura de navegação por idioma, paridade de conteúdo EN/PT e exatidão técnica alinhada às specs e à superfície pública do pacote.

### Modified Capabilities

(nenhuma — as specs existentes descrevem o comportamento do pacote, que não muda)

## Impact

- **Arquivos/diretórios**: remoção de `nextra_docs/pages/**` e `nextra_docs/theme.config.tsx`; criação de `nextra_docs/app/**`, `nextra_docs/content/{en,pt}/**`, `nextra_docs/mdx-components.js`; atualização de `nextra_docs/next.config.*`, `nextra_docs/package.json`, `nextra_docs/build.sh`, `nextra_docs/DEPLOYMENT.md`, `nextra_docs/tsconfig.json`.
- **Dependências (npm)**: subir `nextra` e `nextra-theme-docs` para a linha 4.x e `next` para a versão compatível; ajustar `package-lock.json`.
- **Deploy**: o workflow do GitHub Pages (`.github/`) pode precisar de ajuste para o novo comando/saída de build.
- **Fonte de verdade**: conteúdo derivado de `openspec/specs/` e de `lib/go_router_modular.dart`; nenhum impacto no runtime do pacote.
