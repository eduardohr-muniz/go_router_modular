## 1. Preparar infraestrutura Nextra 4

- [x] 1.1 Em `nextra_docs/package.json`, subir `nextra` e `nextra-theme-docs` para `^4`, ajustar `next` para a versão compatível e revisar `scripts` (`dev`, `build`, `start`); rodar `npm install` para regenerar `package-lock.json`.
- [x] 1.2 Converter `next.config.js` em `next.config.mjs` no formato Nextra 4 (`nextra({...})`), mantendo `output: 'export'`, `trailingSlash`, `images.unoptimized`, e `basePath`/`assetPrefix` condicionais a `GITHUB_ACTIONS`/`GITHUB_REPOSITORY`. Remover `next.config.complex.js` e `next.config.github.js` se obsoletos.
- [x] 1.3 Criar `mdx-components.js` reexportando os componentes do tema (`useMDXComponents` de `nextra-theme-docs`).
- [x] 1.4 Ajustar `tsconfig.json` para o App Router (paths/`jsx`), se necessário.
- [x] 1.5 Verificar (teste): `npm ci` instala sem erros e `npx next info` reporta versões esperadas de Next/Nextra.

## 2. Remover estrutura Nextra 2

- [x] 2.1 Remover `nextra_docs/pages/**` (todas as `.mdx` e `_meta.json`) e `nextra_docs/theme.config.tsx`.
- [x] 2.2 Verificar (teste): nenhum arquivo `pages/**.mdx`, `pages/**/_meta.json` ou `theme.config.tsx` permanece em `nextra_docs/`.

## 3. Implementar App Router e i18n

- [x] 3.1 Criar `app/layout.tsx` (raiz, `<html>`/`<body>`, metadados base).
- [x] 3.2 Criar `app/[lang]/layout.tsx` usando `Layout`/`Navbar`/`Footer` de `nextra-theme-docs`, com `pageMap` por idioma e `LocaleSwitch` (locales `en`/`pt`).
- [x] 3.3 Implementar `generateStaticParams` em `[lang]` retornando exatamente `en` e `pt`; configurar `i18n` (`locales: ['en','pt']`, `defaultLocale: 'en'`).
- [x] 3.4 Criar a página raiz `app/page.tsx` que redireciona `/` para `/en` de forma compatível com export estático (redirect client-side/meta-refresh + link de fallback).
- [x] 3.5 Verificar (teste): `npm run build` gera `out/en/` e `out/pt/`, e abrir `out/index.html` redireciona para `/en`.

## 4. Estrutura de conteúdo e navegação (paridade EN/PT)

- [x] 4.1 Criar a árvore de conteúdo em `content/en/` e `content/pt/` com os mesmos caminhos: `index`, `getting-started/{quick-start,migration-guide}`, `routes/{routes-system,shell-route,navigation,transitions/{index,examples},loader-system,redirects}`, `dependency-injection`, `event-module/{index,widget-mixin}`, `microfrontends`, `testing/{index,event-testing,fake-injector}`, `changelog`.
- [x] 4.2 Criar os arquivos `_meta` por idioma com as mesmas chaves/ordem (rótulos traduzidos) e os links externos (GitHub, pub.dev).
- [x] 4.3 Verificar (teste): script de paridade confirma que `content/en` e `content/pt` têm o mesmo conjunto de caminhos relativos e que os `_meta` têm as mesmas chaves na mesma ordem.

## 5. Escrever o conteúdo (correto, nos 2 idiomas)

- [x] 5.1 Home (`index`) EN/PT: visão geral do pacote, instalação, links rápidos.
- [x] 5.2 Getting Started EN/PT: `quick-start` (configuração de `ModularApp`/rotas/módulos) e `migration-guide`, derivados de `routing-configuration` e `module-*`.
- [x] 5.3 Routes & Modules EN/PT: `routes-system`, `shell-route`, `navigation`, `transitions/{index,examples}`, `loader-system`, `redirects`, derivados de `routing-routes`, `routing-navigation`, `routing-lifecycle`.
- [x] 5.4 Dependency Injection EN/PT: derivado de `dependency-injection`, `module-bind-scope`, `dependency-injection-protection` (usar `Injector`, `Bind`, escopos).
- [x] 5.5 Event Module EN/PT: `index` (overview atualizado com composição via `OutroEventModule().listen()`, `on<T>`, autoDispose, exclusivo) e `widget-mixin` (`ModularEventMixin`), derivados de `events-event-module`, `events-listening`, `events-bus`. NÃO citar `ModularEventListener`/`eventImports()`/`EventListenerMixin`.
- [x] 5.6 Micro Frontends EN/PT: derivado de `module-kinds`/`package-layering`.
- [x] 5.7 Testing EN/PT: `index`, `event-testing` e `fake-injector`, derivados de `events-testing` e da superfície de `lib/testing.dart` (`ModularTestScope`, `EventRecorder`, `FakeInjector`, `clearEventModuleState`).
- [x] 5.8 Changelog EN/PT: resumo alinhado ao `CHANGELOG.md` do pacote (incluindo a mudança BREAKING de eventos).
- [x] 5.9 Verificar (teste): varredura por termos proibidos (`ModularEventListener`, `eventImports`, `EventListenerMixin`) retorna zero ocorrências em `content/`; revisão de que os símbolos dos exemplos existem nos `export` de `lib/go_router_modular.dart`.

## 6. Deploy e documentação do projeto de docs

- [x] 6.1 Atualizar `.github/workflows/deploy.yml` para Node `20` e o comando de build do Nextra 4 (mantendo `touch out/.nojekyll` e publicação de `nextra_docs/out`).
- [x] 6.2 Atualizar `nextra_docs/build.sh`, `nextra_docs/README.md` e `nextra_docs/DEPLOYMENT.md` para o novo fluxo.
- [x] 6.3 Verificar (teste): build de deploy local `GITHUB_ACTIONS=true GITHUB_REPOSITORY=eduardohr-muniz/go_router_modular npm run build` aplica `basePath` e cria `out/.nojekyll`.

## 7. Verificação final

- [x] 7.1 Rodar `npm run build` limpo em `nextra_docs/` e validar manualmente as rotas `/en` e `/pt`, o redirect da raiz e o language switcher.
- [x] 7.2 Confirmar que o pacote Dart não foi afetado: `flutter analyze` sem issues e `flutter test --coverage` verdes (nenhuma mudança em `lib/`).
- [x] 7.3 Conferência final de paridade EN/PT e de links internos (sem links quebrados no `out/`).
