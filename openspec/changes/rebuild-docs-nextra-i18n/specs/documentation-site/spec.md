## ADDED Requirements

### Requirement: Site de documentação roda em Nextra 4 com App Router

O sistema SHALL construir o site de documentação com **Nextra 4** sobre o **Next.js App Router**, com a estrutura: `app/layout.tsx` (raiz), `app/[lang]/layout.tsx` (layout de docs por idioma usando o tema `nextra-theme-docs`), conteúdo MDX em `content/{en,pt}/**`, `mdx-components.js` na raiz do projeto de docs e navegação declarada em arquivos `_meta` por idioma. O `dependencies` do `nextra_docs/package.json` MUST declarar `nextra` e `nextra-theme-docs` na linha `4.x` e uma versão de `next` compatível. O projeto MUST NOT conter mais a estrutura Nextra 2 (`pages/**`, `theme.config.tsx`).

Arquivos de referência: `nextra_docs/app/`, `nextra_docs/content/`, `nextra_docs/mdx-components.js`, `nextra_docs/package.json`, `nextra_docs/next.config.mjs`.

#### Scenario: Build de produção conclui sem erros

- **WHEN** `npm ci` e `npm run build` são executados em `nextra_docs/`
- **THEN** o build conclui com sucesso e gera o diretório de export estático `out/`

#### Scenario: Estrutura Nextra 2 foi removida

- **WHEN** o diretório `nextra_docs/` é inspecionado após a mudança
- **THEN** não existem `pages/**.mdx`, `pages/**/_meta.json` nem `theme.config.tsx`
- **AND** existe `app/[lang]/layout.tsx` e `content/en/` e `content/pt/`

#### Scenario: Dependências do Nextra estão na linha 4.x

- **WHEN** `nextra_docs/package.json` é inspecionado
- **THEN** `nextra` e `nextra-theme-docs` têm versão `^4` (ou compatível 4.x)

### Requirement: i18n com prefixo de locale e inglês como padrão

O sistema SHALL servir a documentação em dois idiomas sob prefixo de locale: `/en/...` e `/pt/...`, com `defaultLocale = 'en'`. O segmento `[lang]` MUST declarar `generateStaticParams` retornando exatamente `en` e `pt`, de modo que o export estático produza as duas árvores. A raiz `/` MUST redirecionar para `/en` mesmo no export estático (sem servidor). Um seletor de idioma (language switcher) MUST estar disponível e alternar entre os locales.

Arquivos de referência: `nextra_docs/app/[lang]/`, `nextra_docs/app/page` (redirect raiz), `nextra_docs/next.config.mjs`.

#### Scenario: Export gera as duas árvores de idioma

- **WHEN** o build estático é executado
- **THEN** `out/en/` e `out/pt/` são gerados com as páginas correspondentes

#### Scenario: Raiz redireciona para o idioma padrão

- **WHEN** um visitante abre `/` (índice do site exportado)
- **THEN** é redirecionado para `/en`

#### Scenario: Alternância de idioma preserva o contexto de navegação

- **WHEN** o visitante está em uma página em inglês e usa o seletor de idioma para português
- **THEN** é levado à versão em português da mesma página (mesma rota sob `/pt`)

#### Scenario: Apenas inglês e português são gerados

- **WHEN** `generateStaticParams` do segmento `[lang]` é avaliado
- **THEN** retorna somente `en` e `pt` (nenhum outro locale é gerado)

### Requirement: Paridade de conteúdo e navegação entre EN e PT

O sistema SHALL manter a mesma árvore de páginas e a mesma estrutura de navegação nos dois idiomas, com textos traduzidos. Para cada documento em `content/en/` MUST existir o documento correspondente em `content/pt/` (mesmo caminho relativo), e os arquivos `_meta` de cada idioma MUST listar as mesmas chaves de navegação na mesma ordem. A árvore MUST cobrir: `index` (Home); `getting-started/` (`quick-start`, `migration-guide`); `routes/` (`routes-system`, `shell-route`, `navigation`, `transitions/index`, `transitions/examples`, `loader-system`, `redirects`); `dependency-injection`; `event-module/` (`index`, `widget-mixin`); `microfrontends`; `testing/` (`index`, `event-testing`, `fake-injector`); `changelog`.

Arquivos de referência: `nextra_docs/content/en/`, `nextra_docs/content/pt/`, `_meta` por idioma.

#### Scenario: Toda página existe nos dois idiomas

- **WHEN** as árvores `content/en/` e `content/pt/` são comparadas por caminho relativo
- **THEN** o conjunto de arquivos de conteúdo é idêntico entre os dois idiomas (nenhuma página existe em apenas um idioma)

#### Scenario: Navegação espelhada na mesma ordem

- **WHEN** os arquivos `_meta` de EN e PT são comparados
- **THEN** as chaves de navegação e sua ordem são as mesmas (apenas os rótulos diferem por idioma)

#### Scenario: Tópico obrigatório ausente é detectado

- **WHEN** qualquer tópico da árvore obrigatória não possui arquivo em um dos idiomas
- **THEN** a entrega é considerada incompleta (falha de paridade)

### Requirement: Exatidão técnica alinhada à API pública e às specs

O sistema SHALL produzir conteúdo tecnicamente correto: cada página reflete o comportamento normativo das specs em `openspec/specs/` e usa apenas símbolos presentes na superfície pública atual (`lib/go_router_modular.dart`). O conteúdo MUST NOT referenciar APIs removidas — em particular `ModularEventListener`, `eventImports` e `EventListenerMixin` — e a documentação do Event Module MUST descrever a composição via `OutroEventModule().listen()`.

Arquivos de referência: `openspec/specs/`, `lib/go_router_modular.dart`, `nextra_docs/content/`.

#### Scenario: Símbolos removidos não aparecem na documentação

- **WHEN** o conteúdo de `nextra_docs/content/` é varrido pelos termos `ModularEventListener`, `eventImports` e `EventListenerMixin`
- **THEN** nenhuma ocorrência é encontrada em nenhum dos idiomas

#### Scenario: Event Module documenta a composição atual

- **WHEN** a página de overview do Event Module é lida (EN e PT)
- **THEN** ela descreve a composição chamando `OutroEventModule().listen()` dentro de `listen()`

#### Scenario: Exemplos usam apenas a API pública

- **WHEN** os blocos de código das páginas são revisados
- **THEN** os símbolos usados existem nos `export` de `lib/go_router_modular.dart` (ex.: `Module`, `EventModule`, `ModularEventMixin`, `Injector`, `ChildRoute`, `ModuleRoute`, `ShellModularRoute`)

### Requirement: Build estático compatível com GitHub Pages

O sistema SHALL preservar o deploy por GitHub Pages com export estático. O `next.config.mjs` MUST manter `output: 'export'` e aplicar `basePath`/`assetPrefix` do repositório quando `GITHUB_ACTIONS` estiver definido. O workflow `.github/workflows/deploy.yml` MUST construir `nextra_docs`, publicar `nextra_docs/out`, criar `out/.nojekyll` e usar uma versão de Node compatível com Nextra 4 (Node ≥ 20).

Arquivos de referência: `nextra_docs/next.config.mjs`, `nextra_docs/build.sh`, `.github/workflows/deploy.yml`.

#### Scenario: Build com contexto do GitHub Pages aplica basePath

- **WHEN** `GITHUB_ACTIONS=true GITHUB_REPOSITORY=owner/go_router_modular npm run build` é executado
- **THEN** os assets e links gerados em `out/` usam o `basePath`/`assetPrefix` do repositório

#### Scenario: Saída inclui marcador para o GitHub Pages

- **WHEN** o build de deploy termina
- **THEN** o arquivo `out/.nojekyll` existe

#### Scenario: Node incompatível falha cedo

- **WHEN** o build roda em uma versão de Node abaixo da exigida pelo Nextra 4
- **THEN** o build falha (o workflow deve fixar Node ≥ 20 para evitar isso)
