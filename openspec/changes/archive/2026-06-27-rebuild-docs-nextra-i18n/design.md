## Context

A documentação vive em `nextra_docs/`, hoje em **Nextra 2 (Pages Router)**: páginas em `pages/**.mdx`, navegação em `_meta.json`, tema em `theme.config.tsx`, e `next.config.js` com `output: 'export'` + `basePath`/`assetPrefix` condicionais para GitHub Pages. O deploy é feito por `.github/workflows/deploy.yml` (build em `nextra_docs`, publica `nextra_docs/out`).

O conteúdo atual é monolíngue e parte está incorreta (sobretudo o Event Module, após a remoção de `ModularEventListener`/`eventImports()`/`EventListenerMixin`). A fonte de verdade do comportamento do pacote são as specs em `openspec/specs/` e a superfície pública em `lib/go_router_modular.dart`.

Decisões já tomadas com o usuário:
- Stack: **Nextra 4 (App Router)**.
- i18n: rotas `/en` e `/pt`, **padrão inglês**, raiz `/` redireciona para `/en`.
- Conteúdo: **paridade total** EN/PT de todos os tópicos.
- Hosting: permanece **GitHub Pages com export estático**.

## Goals / Non-Goals

**Goals:**

- Reescrever a documentação do zero em Nextra 4, correta e alinhada às specs/superfície pública.
- i18n idiomático com prefixo de locale e troca de idioma funcionando no export estático.
- Estrutura de navegação espelhada e consistente entre EN e PT (mesma árvore, textos traduzidos).
- Manter o pipeline de deploy do GitHub Pages (com os ajustes mínimos necessários).

**Non-Goals:**

- Alterar o pacote Dart, criar versionamento de docs, adicionar terceiro idioma ou trocar de hosting.

## Decisions

### Decisão 1: Nextra 4 com App Router e segmento `[lang]`

Adotar a estrutura padrão do Nextra 4: `app/layout.tsx` (raiz), `app/[lang]/layout.tsx` (layout de docs por idioma com `<Layout>` do `nextra-theme-docs`), conteúdo MDX em `content/{en,pt}/**`, navegação em arquivos `_meta` por idioma, e `mdx-components.js` reexportando os componentes do tema. O `generateStaticParams` em `[lang]` enumera `['en','pt']`, gerando as duas árvores no export estático.

- **Por que (SRP / Dependency Inversion)**: cada idioma é uma árvore de conteúdo independente sob o mesmo layout abstrato; o layout depende da abstração de "página de conteúdo MDX", não de páginas concretas. A navegação (`_meta`) é a única fonte de ordenação/títulos por idioma (sem duplicar ordem em vários lugares).
- **Alternativa considerada**: permanecer no Nextra 2 com pastas de locale como rotas comuns. Rejeitada — i18n não idiomático, switcher manual, e contraria o pedido de "forma correta".

### Decisão 2: i18n por prefixo de locale, inglês como padrão

Todas as rotas carregam o prefixo (`/en/...`, `/pt/...`). O `LocaleSwitch` do tema alterna entre os locales preservando a página atual. A configuração de i18n declara `locales: ['en','pt']` e `defaultLocale: 'en'`.

- **Open/Closed**: adicionar um idioma no futuro é incluir um valor em `generateStaticParams`, uma pasta `content/<lang>` e os `_meta.<lang>` — sem tocar nos layouts.

### Decisão 3: Redirecionamento da raiz no export estático

Como o export estático não executa middleware, o redirecionamento de `/` para `/en` é feito por uma página raiz que emite redirecionamento no cliente (componente em `app/page.tsx` com `redirect`/meta-refresh equivalente que funcione após `next export`), garantindo que abrir a raiz no GitHub Pages leve a `/en`.

- **Por que**: preserva a UX de "abrir a home" sem depender de servidor; mantém uma única responsabilidade (apenas redirecionar) na página raiz.
- **Alternativa considerada**: `redirects` no `next.config`. Rejeitada — não é aplicada em `output: 'export'`.

### Decisão 4: Conteúdo derivado das specs (exatidão como requisito)

Cada página é escrita a partir do comportamento normativo das specs (`openspec/specs/`) e dos símbolos exportados por `lib/go_router_modular.dart`. Exemplos de código devem compilar conceitualmente contra a API atual; termos removidos não aparecem.

- **Clean Code / DRY**: a navegação por idioma é a única fonte da estrutura; o conteúdo não repete definições já dadas pelas specs — referencia o comportamento correto. Pontos de extensão: novas páginas entram pelo `_meta` do idioma e por um arquivo MDX correspondente em cada locale (paridade obrigatória).

### Decisão 5: Árvore de conteúdo (espelhada nos 2 idiomas)

- `index` (Home)
- `getting-started/`: `quick-start`, `migration-guide`
- `routes/`: `routes-system`, `shell-route`, `navigation`, `transitions/` (`index`, `examples`), `loader-system`, `redirects`
- `dependency-injection`
- `event-module/`: `index` (overview atualizado), `widget-mixin`
- `microfrontends`
- `testing/`: `index`, `event-testing`, `fake-injector`
- `changelog`
- Links externos (GitHub, pub.dev) no `_meta`.

## Risks / Trade-offs

- **[Node/Next versão no CI]** Nextra 4/Next 15 exige Node ≥ 18.18 (idealmente 20). → Mitigação: bump do `node-version` para `20` no `deploy.yml` e validação local com a mesma versão.
- **[basePath + i18n no GitHub Pages]** Combinação de `basePath` do repositório com prefixo de locale pode quebrar links/asset prefix. → Mitigação: testar `npm run build` com `GITHUB_ACTIONS=true GITHUB_REPOSITORY=...` e validar os caminhos gerados em `out/en` e `out/pt`, além do redirect da raiz.
- **[Redirect estático da raiz]** Redirecionamento client-side pode causar flash. → Mitigação: página mínima de redirect com fallback de link manual; aceitável para um root redirect.
- **[Paridade de conteúdo]** Risco de divergência EN/PT ao longo do tempo. → Mitigação: estrutura idêntica de arquivos por locale e checklist de paridade nas tasks; toda página existe nos dois idiomas.
- **[Conteúdo desatualizado reaparecer]** Copiar do conteúdo antigo pode reintroduzir APIs removidas. → Mitigação: reescrever a partir das specs; varredura por termos proibidos (`ModularEventListener`, `eventImports`, `EventListenerMixin`) antes de concluir.

## Migration Plan

1. Congelar o conteúdo antigo (referência) e remover `pages/**` + `theme.config.tsx` ao introduzir a estrutura App Router.
2. Subir dependências (`nextra`, `nextra-theme-docs`, `next`) para 4.x/compatível; regenerar `package-lock.json`.
3. Criar `app/`, `content/{en,pt}`, `mdx-components.js`, `_meta` por idioma e o redirect da raiz.
4. Migrar/reescrever conteúdo com paridade EN/PT a partir das specs.
5. Atualizar `next.config.mjs`, `build.sh`, `DEPLOYMENT.md` e o `deploy.yml` (Node 20).
6. Validar build estático local e os caminhos do GitHub Pages.

**Rollback**: a documentação é isolada em `nextra_docs/` (mais o `deploy.yml`); reverter o commit restaura a versão Nextra 2 anterior sem afetar o pacote.

## Open Questions

- O domínio/baseURL final do GitHub Pages muda com i18n (ex.: precisa de página 404 custom por idioma)? Avaliar durante a validação do build.
- Manter `changelog` como página manual espelhada ou gerar a partir do `CHANGELOG.md` do pacote? Proposta inicial: página manual por idioma, revisada a cada release.
