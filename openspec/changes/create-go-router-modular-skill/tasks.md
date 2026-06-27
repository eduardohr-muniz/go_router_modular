## 1. Preparação e fonte da verdade

- [x] 1.1 Invocar a skill `skill-creator` para conduzir a criação e os evals desta skill.
- [x] 1.2 Levantar os pontos canônicos a referenciar: doc Nextra (`nextra_docs/content/{en,pt}/routes/navigation.mdx`, `routes-system.mdx`) e specs (`openspec/specs/routing-navigation`, `routing-routes`).
- [x] 1.3 Confirmar no código os fatos usados pela skill: `ChildRoute.name` e `ModuleRoute.name` existem e são repassados aos builders; `binds(Injector i)`/`imports()` aceitam forma síncrona (`FutureBinds = FutureOr<void>`).

## 2. Autoria do SKILL.md

- [x] 2.1 Criar `.claude/skills/go-router-modular/SKILL.md` com frontmatter (`name: go-router-modular`, `description` com gatilho: criar/editar rota, módulo, navegação com `go_router_modular`).
- [x] 2.2 Documentar o padrão `feature_route.dart` ao lado de `feature_module.dart`, com `<Feature>RouteRelative` (constantes de path/nome, `*Module`, `*Named`, chave `param$id`, path `myDetail$id`) e `<Feature>Route` (`of(context)`, `go()`/`push()`/`pushMyDetail({required String id})` e leitor estático `getMyIdParam(state)`).
- [x] 2.3 Escrever a regra de navegação exclusivamente nomeada com contraexemplo (`❌ context.go('/my')` vs `✅ MyRoute.of(context).go()`) e passagem de `pathParameters`/`extra` pelos métodos nomeados.
- [x] 2.4 Documentar `name:` obrigatório no `ChildRoute` (usando `*Named`) e `path` por constante de path relativo de `<Feature>RouteRelative`; cobrir `ModuleRoute` com `name` e o papel do `*Module` no ponto de montagem.
- [x] 2.5 Escrever a regra "evitar módulos assíncronos": preferir `binds`/`imports` síncronos; usar `Future` só quando inevitável e justificado.
- [x] 2.6 Fixar a nomenclatura: classe de constantes `*RouteRelative`, classe de navegação/leitura `*Route` (via `.of(context)`), chaves `param$`, paths `*$<param>`, nomes de rota em kebab-case.
- [x] 2.7 Referenciar a doc Nextra e as specs como fonte da verdade (sem duplicar conteúdo normativo); se necessário, extrair o template completo para `references/`/`examples/`.

## 3. Evals com skill-creator

- [x] 3.1 Criar prompts de teste de **gatilho** (ex.: "crie a rota da feature X em go_router_modular") e verificar que a skill é acionada.
- [x] 3.2 Criar prompts de teste de **qualidade** e asserções: saída usa `goNamed`/`pushNamed`, `name:` no `ChildRoute`, classes `*RouteRelative`/`*Route`, kebab-case; e NÃO contém `context.go('/...')` cru nem `binds`/`imports` assíncronos sem justificativa.
- [x] 3.3 Rodar os evals (agente-com-a-skill), revisar resultados qualitativa e quantitativamente.
- [x] 3.4 Ajustar `SKILL.md` e a `description` conforme os resultados; otimizar o gatilho com o melhorador de descrição do skill-creator.
- [x] 3.5 Expandir o conjunto de testes e repetir até o gatilho e a qualidade estabilizarem.

## 4. Verificação final

- [x] 4.1 Validar o frontmatter da skill (YAML correto; `name` e `description` presentes) e que o arquivo é descoberto como skill local do repo.
- [x] 4.2 Conferir que os símbolos usados nos exemplos existem na API pública (`lib/go_router_modular.dart`) — ex.: `Module`, `ChildRoute`, `ModuleRoute`, `Modular.get`, `context.goNamed`.
- [x] 4.3 Revisar que a skill não altera nada em `lib/` e que os links para doc/specs estão corretos.
