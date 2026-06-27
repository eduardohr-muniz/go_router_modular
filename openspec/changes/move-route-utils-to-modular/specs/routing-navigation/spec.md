## MODIFIED Requirements

### Requirement: Leitura de estado e parâmetros da rota atual

O sistema SHALL oferecer, pela fachada `GoRouterModular`, acesso à leitura do estado da rota atual a partir de um `BuildContext`: o `GoRouterState` corrente, o path corrente e a leitura de um parâmetro de path por nome. Os métodos MUST seguir a convenção de nomes `...Of(context)`, consistente entre si: `routerStateOf(context)`, `currentPathOf(context)` e `pathParamOf(context, name)`.

O sistema SHALL continuar oferecendo, via extensions de `BuildContext`, os mesmos acessos por compatibilidade (`state`, `getPath`, `getPathParam`), porém marcados como `@Deprecated` apontando para os equivalentes da fachada. Os nomes legados na própria fachada (`stateOf`, `getCurrentPathOf`) MUST também ser marcados como `@Deprecated` apontando para `routerStateOf` e `currentPathOf`. Nenhum desses símbolos é removido nesta release.

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/ui/route_extension.dart`.

#### Scenario: Leitura de parâmetro de path por nome pela fachada

- **WHEN** a rota atual é `/usuario/:id` resolvida com `id = "42"` e `GoRouterModular.pathParamOf(context, 'id')` é chamado
- **THEN** o sistema retorna `"42"`

#### Scenario: Leitura do path e do estado correntes pela fachada

- **WHEN** `GoRouterModular.currentPathOf(context)` e `GoRouterModular.routerStateOf(context)` são chamados na rota atual
- **THEN** `currentPathOf` retorna o path corrente e `routerStateOf` retorna o `GoRouterState` corrente

#### Scenario: Acessos legados continuam funcionando como depreciados

- **WHEN** o consumidor chama `context.getPathParam('id')`, `context.getPath`, `context.state`, `GoRouterModular.getCurrentPathOf(context)` ou `GoRouterModular.stateOf(context)`
- **THEN** o sistema retorna o mesmo resultado dos métodos novos
- **AND** cada símbolo está anotado com `@Deprecated` indicando o substituto recomendado

## ADDED Requirements

### Requirement: Acesso explícito aos utilitários do go_router pela fachada

O sistema SHALL oferecer, pela fachada `GoRouterModular`, wrappers explícitos que delegam aos utilitários do `go_router` (`GoRouterState`/`GoRouter`) a partir de um `BuildContext`, sem alterar a semântica do `go_router`. Os wrappers MUST incluir, no mínimo: `pathParamsOf(context)` (todos os path parameters), `queryParamsOf(context)` (todos os query parameters), `queryParamOf(context, name)` (um query parameter por nome), `currentUriOf(context)` (o `Uri` corrente), `currentLocationOf(context)` (a location corrente) e `extraOf<T>(context)` (o `extra` tipado da rota). Cada wrapper MUST seguir a convenção `...Of(context)`.

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`.

#### Scenario: Leitura de query parameter por nome

- **WHEN** a location atual é `/busca?termo=flutter` e `GoRouterModular.queryParamOf(context, 'termo')` é chamado
- **THEN** o sistema retorna `"flutter"`

#### Scenario: Leitura de uri, location e coleções de parâmetros

- **WHEN** os métodos `currentUriOf`, `currentLocationOf`, `pathParamsOf` e `queryParamsOf` são chamados na rota atual
- **THEN** cada um retorna, respectivamente, o `Uri` corrente, a location corrente, o mapa de path parameters e o mapa de query parameters do `GoRouterState` corrente

#### Scenario: Leitura do extra tipado

- **WHEN** a rota foi navegada com `extra` do tipo `Map<String, Object?>` e `GoRouterModular.extraOf<Map<String, Object?>>(context)` é chamado
- **THEN** o sistema retorna o `extra` com o tipo solicitado
