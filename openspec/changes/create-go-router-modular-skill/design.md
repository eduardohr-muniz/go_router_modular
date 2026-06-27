## Context

O repositório `go_router_modular` já tem: doc Nextra bilíngue (`nextra_docs/content/{en,pt}/routes/*`), specs normativas (`openspec/specs/routing-*`, `public-api-surface`) e skills do OpenSpec em `.claude/skills/`. Falta um artefato que faça um agente (Claude Code) **aplicar** as convenções de uso do pacote ao escrever código.

A convenção-alvo (definida pelo autor do pacote) organiza cada feature em dois arquivos lado a lado:
- `feature_module.dart` — o `Module` (binds/imports/rotas).
- `feature_route.dart` — duas classes: `<Feature>RouteRelative` (constantes de path/nome) e `<Feature>Route` (navegação por `BuildContext` + leitores estáticos de parâmetro).

Fatos do código que embasam a skill:
- `ChildRoute` aceita `name` (`lib/src/routing/child_route.dart`) e o builder o repassa ao `GoRoute` (`lib/src/routing/builders/child_route_builder.dart`). `ModuleRoute` também aceita `name`.
- Navegação nomeada usa a extension `GoRouterHelper` do go_router (`context.goNamed`/`pushNamed`), re-exportada pelo barril.
- "Módulo assíncrono" = `binds(Injector i)`/`imports()` retornando `Future` (`typedef FutureBinds = FutureOr<void>` em `lib/src/module/module.dart`). Síncrono é o caminho preferido.

Restrições: artefatos OpenSpec em pt-BR; a skill é tooling de agente e não muda `lib/`; usar `skill-creator` para montar/validar evals.

## Goals / Non-Goals

**Goals:**
- Capturar a convenção do projeto em uma skill versionada que o agente aplica por padrão.
- Tornar navegação nomeada e módulos síncronos o caminho de menor resistência ao gerar código.
- Validar a skill com evals (gatilho + qualidade) via skill-creator.

**Non-Goals:**
- Mudar API/runtime do pacote ou proibir padrões em runtime.
- Duplicar a doc Nextra/specs dentro da skill (referenciar, não copiar).
- Publicar a skill externamente.

## Decisions

### Decisão 1: Skill versionada no repo (`.claude/skills/go-router-modular/`)
Vive no repositório para que todos os contribuidores recebam a convenção ao clonar, e para evoluir junto com o pacote. Alternativa (skill global `~/.claude/skills/`) rejeitada: ficaria só na máquina do autor e divergiria do pacote.

### Decisão 2: Estrutura de arquivos da skill
`SKILL.md` enxuto (frontmatter + as regras e exemplos canônicos) e, se necessário, um `references/` ou `examples/` com o template completo de `feature_route.dart`. O `SKILL.md` referencia a doc Nextra e as specs como fonte da verdade para evitar drift.

### Decisão 3: `description` orientada a gatilho
A `description` do frontmatter lista os contextos de disparo (criar/editar rota, módulo, navegação com `go_router_modular`) porque é o campo que o runtime usa para decidir acionar a skill. Texto de gatilho ruim = skill que não dispara.

### Decisão 4: Convenção canônica (do autor) embutida como exemplo
A skill fixa o exemplo `MyRouteRelative`/`MyRoute` fornecido pelo autor, incluindo:
- Constantes de path relativo, `*Module` e `*Named`; chave de parâmetro `param$id` e path com parâmetro `myDetail$id`.
- Leitor estático `getMyIdParam(state)` na classe de navegação `MyRoute`.
- `MyRoute.of(context)` com métodos `go()`/`push()`/`pushMyDetail({required String id})`.
- Nomenclatura forte: `*RouteRelative` para constantes, `*Route` para navegação/leitura, chaves `param$`, paths `*$<param>`, nomes de rota em kebab-case.
- Contraexemplo explícito (`❌ context.go('/my')` vs `✅ MyRoute.of(context).go()`).
- `ChildRoute(MyRouteRelative.my, name: MyRouteRelative.myNamed, ...)`.

### Decisão 5: Evitar módulos assíncronos como regra "evitar ao máximo"
A skill recomenda `binds`/`imports` síncronos e trata a forma assíncrona como exceção justificada — alinhado ao pedido do autor, sem remover suporte do pacote.

### Decisão 6: Evals com skill-creator
Usar o fluxo do `skill-creator` para: (a) gerar prompts de teste de gatilho e de qualidade; (b) rodar o agente-com-a-skill; (c) avaliar qualitativa e quantitativamente. Asserções de qualidade incluem: presença de `goNamed`/`pushNamed`, `name:` no `ChildRoute`, ausência de `context.go('/...')` cru, e ausência de `binds`/`imports` assíncronos sem justificativa.

## Risks / Trade-offs

- **[Skill não dispara nos contextos certos]** → Iterar a `description` com o melhorador de descrição do skill-creator e cobrir o gatilho com eval positivo.
- **[Drift entre skill e doc/código]** → A skill referencia doc/specs como fonte da verdade e mantém apenas o mínimo canônico inline; evals verificam que os símbolos usados existem na API pública.
- **[Convenção opinativa demais para alguns consumidores]** → A skill é do repositório do pacote (orienta contribuição/uso recomendado); não impõe nada em runtime.
- **[Falsos positivos do eval de "path cru"]** (ex.: `context.go` legítimo em redirect) → Restringir a asserção a navegação imperativa de feature e revisar manualmente os casos de borda.

## Migration Plan

1. Rascunhar `SKILL.md` (frontmatter + regras + exemplo canônico) e referências.
2. Usar `skill-creator` para montar prompts de teste (gatilho + qualidade) e rodar.
3. Avaliar resultados; ajustar a skill e a `description`.
4. Expandir o conjunto de testes e repetir até estabilizar.
5. **Rollback**: remover o diretório `.claude/skills/go-router-modular/` — nenhum efeito no pacote.

## Open Questions

- Nenhuma bloqueante. Idioma do conteúdo do `SKILL.md` (a definir com o autor: PT, EN ou bilíngue) pode ser ajustado na fase de apply; a doc do pacote é bilíngue.
