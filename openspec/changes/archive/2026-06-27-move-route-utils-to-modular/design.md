## Context

A `GoRouterExtension` em `lib/src/ui/route_extension.dart` acumula três responsabilidades: navegação assíncrona (`*Async`), utilitários de pop (`popUntil`, `popUntilNamed`) e **leitura** do estado da rota (`getPathParam`, `getPath`, `state`). Por ser uma extension sobre `BuildContext`, esses três grupos aparecem no autocomplete de qualquer widget do app.

Em paralelo, a fachada `Modular` (`lib/src/bootstrap/go_router_modular_configure.dart`) já oferece leitura de estado por contexto via `getCurrentPathOf(context)` e `stateOf(context)` — ou seja, há **duplicação de conceito** entre extension e fachada, com nomes inconsistentes entre si (`getCurrentPathOf` vs `stateOf`).

O barril `lib/go_router_modular.dart` já re-exporta `package:go_router/go_router.dart` com `hide GoRouter, ShellRoute`, então `GoRouterState` e a extension `GoRouterHelper` (`context.go`, `context.push`, …) já chegam ao consumidor. O pedido de "exportar os utils do go_router" se traduz em: (a) confirmar/garantir esse re-export como contrato e (b) oferecer wrappers explícitos na fachada para descoberta por um único ponto.

Restrições: pt-BR nos artefatos; Effective Dart, Object Calisthenics, Clean Code e SOLID no código; sem abreviações em nomes; cobertura de testes 100%.

## Goals / Non-Goals

**Goals:**

- Consolidar a leitura de estado da rota na fachada `Modular` com nomes consistentes no padrão `...Of(context)`.
- Expor wrappers explícitos para os utilitários úteis do `go_router` (path params, query params, uri, location, extra).
- Reduzir o ruído da `GoRouterExtension`, deixando-a focada em navegação assíncrona + pop.
- Manter compatibilidade total nesta release via `@Deprecated`.

**Non-Goals:**

- Remover qualquer símbolo agora (remoção fica para a próxima major).
- Alterar navegação assíncrona e utilitários de pop.
- Encapsular ou reimplementar o `go_router`: os wrappers apenas delegam.

## Decisions

### Decisão 1: Leitura de estado na fachada `Modular`, não em nova classe

Centralizar a leitura nos métodos estáticos de `Modular`, reaproveitando o ponto único que o consumidor já conhece (`Modular`/`Modular`).

- **Alternativa considerada**: criar uma nova classe utilitária (ex.: `ModularRouteState`). Rejeitada por adicionar mais um símbolo público e mais um ponto de descoberta, contrariando coesão.
- **Alternativa considerada**: manter na extension. Rejeitada por sobrecarregar `BuildContext` e manter a duplicação.

### Decisão 2: Convenção de nomes `...Of(context)`

Todos os acessos por contexto seguem `routerStateOf`, `currentPathOf`, `pathParamOf`, `pathParamsOf`, `queryParamOf`, `queryParamsOf`, `currentUriOf`, `currentLocationOf`, `extraOf`. Consistente com `stateOf`/`getCurrentPathOf` já existentes e explícito sobre exigir `context`.

- `getCurrentPathOf` → depreciado em favor de `currentPathOf`; `stateOf` → depreciado em favor de `routerStateOf`.
- **Alternativa considerada**: nomes curtos sem `Of` (`path(context)`, `state(context)`). Rejeitada por colidir conceitualmente com a extension e ser menos explícita.

### Decisão 3: Depreciar em vez de remover (sem breaking nesta release)

`getPathParam`, `getPath`, `state` na extension e `getCurrentPathOf`, `stateOf` na fachada recebem `@Deprecated('Use Modular.<novo> ...')`. Cada símbolo legado delega ao novo, evitando duplicação de lógica (DRY).

- **Alternativa considerada**: remoção imediata. Rejeitada por quebrar consumidores; o usuário optou explicitamente por depreciar e manter.

### Decisão 4: Wrappers do `go_router` delegam ao `GoRouterState`/`GoRouter`

Cada wrapper é uma linha que lê de `GoRouterState.of(context)` (ou `GoRouter.of(context)` quando aplicável), respeitando "um ponto por linha" e sem regra própria. O re-export do `go_router` no barril é mantido como contrato para quem preferir o acesso cru.

### Decisão 5: Implementação como métodos estáticos finos, testados por widget tests

Cada método novo é coberto por testes que montam um `GoRouter` real e verificam o valor lido (sucesso) e o comportamento em ausência de parâmetro (`null`), atingindo 100% de cobertura.

## Risks / Trade-offs

- **[Avisos de depreciação podem incomodar consumidores existentes]** → As mensagens `@Deprecated` indicam o substituto exato; documentar a migração no README/site e manter os símbolos por toda a série atual.
- **[Duplicação aparente entre wrappers da fachada e o re-export do go_router]** → É intencional: a fachada dá descoberta por um ponto; o re-export atende quem prefere o `GoRouterState` cru. Os wrappers não contêm lógica, apenas delegação.
- **[Risco de divergência entre símbolo legado e novo]** → Mitigado fazendo o legado delegar ao novo (sem reimplementar), garantido por teste de equivalência.

## Migration Plan

1. Adicionar os métodos novos em `Modular` (`routerStateOf`, `currentPathOf`, `pathParamOf` + wrappers `go_router`).
2. Fazer `getCurrentPathOf`/`stateOf` delegarem aos novos e marcá-los `@Deprecated`.
3. Depreciar `getPathParam`/`getPath`/`state` na extension, delegando aos novos.
4. Confirmar/ajustar o re-export do `go_router` no barril principal.
5. Atualizar testes e documentação.
6. **Rollback**: como nada é removido e os legados delegam, reverter é apenas remover os métodos novos e as anotações — sem impacto em quem migrou ou não.

## Open Questions

- Nenhuma pendência bloqueante. A remoção definitiva dos símbolos depreciados será tratada por uma proposta de major futura.
