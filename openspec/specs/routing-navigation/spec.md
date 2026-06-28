# Navegação

## Purpose

Define a navegação ergonômica sobre o go_router: extensions de BuildContext com navegação assíncrona via completers, utilitários de pop e leitura de estado/parâmetros, e o açúcar de injeção de dependências por contexto.

## Requirements

### Requirement: Navegação assíncrona que aguarda a construção da tela

O sistema SHALL oferecer, via extensions de `BuildContext`, variantes assíncronas de navegação (`goAsync`, `goNamedAsync`, `pushAsync`, `pushNamedAsync`, `pushReplacementAsync`, `pushReplacementNamedAsync`, `replaceAsync`, `replaceNamedAsync`) que registram um completer antes de navegar e completam o `Future` quando a navegação conclui, incluindo o registro de binds da rota de destino. Um callback `onComplete` opcional MUST ser invocado ao concluir.

Arquivos de referência: `lib/src/extensions/route_extension.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: goNamedAsync conclui após a navegação e registro

- **WHEN** `context.goNamedAsync('perfil')` é aguardado
- **THEN** o `Future` completa após a navegação e o registro de binds da rota de destino
- **AND** o `onComplete`, se fornecido, é invocado

### Requirement: Utilitários de pop por localização e por nome

O sistema SHALL oferecer `popUntil(location)` e `popUntilNamed(routeName)` como utilitários síncronos sobre o `go_router` que removem rotas da pilha até alcançar a localização ou o nome de rota indicado.

Arquivos de referência: `lib/src/extensions/route_extension.dart`.

#### Scenario: popUntil remove rotas até a localização alvo

- **WHEN** a pilha contém várias rotas e `context.popUntil('/home')` é chamado
- **THEN** as rotas são removidas até que a localização atual corresponda a `/home`

### Requirement: Leitura de estado e parâmetros da rota atual

O sistema SHALL oferecer, pela fachada `Modular`, acesso à leitura do estado da rota atual a partir de um `BuildContext`: o `GoRouterState` corrente, o path corrente e a leitura de um parâmetro de path por nome. Os métodos MUST seguir a convenção de nomes `...Of(context)`, consistente entre si: `routerStateOf(context)`, `currentPathOf(context)` e `pathParamOf(context, name)`.

O sistema SHALL continuar oferecendo, via extensions de `BuildContext`, os mesmos acessos por compatibilidade (`state`, `getPath`, `getPathParam`), porém marcados como `@Deprecated` apontando para os equivalentes da fachada. Os nomes legados na própria fachada (`stateOf`, `getCurrentPathOf`) MUST também ser marcados como `@Deprecated` apontando para `routerStateOf` e `currentPathOf`. Nenhum desses símbolos é removido nesta release.

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/ui/route_extension.dart`.

#### Scenario: Leitura de parâmetro de path por nome pela fachada

- **WHEN** a rota atual é `/usuario/:id` resolvida com `id = "42"` e `Modular.pathParamOf(context, 'id')` é chamado
- **THEN** o sistema retorna `"42"`

#### Scenario: Leitura do path e do estado correntes pela fachada

- **WHEN** `Modular.currentPathOf(context)` e `Modular.routerStateOf(context)` são chamados na rota atual
- **THEN** `currentPathOf` retorna o path corrente e `routerStateOf` retorna o `GoRouterState` corrente

#### Scenario: Acessos legados continuam funcionando como depreciados

- **WHEN** o consumidor chama `context.getPathParam('id')`, `context.getPath`, `context.state`, `Modular.getCurrentPathOf(context)` ou `Modular.stateOf(context)`
- **THEN** o sistema retorna o mesmo resultado dos métodos novos
- **AND** cada símbolo está anotado com `@Deprecated` indicando o substituto recomendado

### Requirement: Acesso explícito aos utilitários do go_router pela fachada

O sistema SHALL oferecer, pela fachada `Modular`, wrappers explícitos que delegam aos utilitários do `go_router` (`GoRouterState`/`GoRouter`) a partir de um `BuildContext`, sem alterar a semântica do `go_router`. Os wrappers MUST incluir, no mínimo: `pathParamsOf(context)` (todos os path parameters), `queryParamsOf(context)` (todos os query parameters), `queryParamOf(context, name)` (um query parameter por nome), `currentUriOf(context)` (o `Uri` corrente), `currentLocationOf(context)` (a location corrente) e `extraOf<T>(context)` (o `extra` tipado da rota). Cada wrapper MUST seguir a convenção `...Of(context)`.

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`.

#### Scenario: Leitura de query parameter por nome

- **WHEN** a location atual é `/busca?termo=flutter` e `Modular.queryParamOf(context, 'termo')` é chamado
- **THEN** o sistema retorna `"flutter"`

#### Scenario: Leitura de uri, location e coleções de parâmetros

- **WHEN** os métodos `currentUriOf`, `currentLocationOf`, `pathParamsOf` e `queryParamsOf` são chamados na rota atual
- **THEN** cada um retorna, respectivamente, o `Uri` corrente, a location corrente, o mapa de path parameters e o mapa de query parameters do `GoRouterState` corrente

#### Scenario: Leitura do extra tipado

- **WHEN** a rota foi navegada com `extra` do tipo `Map<String, Object?>` e `Modular.extraOf<Map<String, Object?>>(context)` é chamado
- **THEN** o sistema retorna o `extra` com o tipo solicitado

### Requirement: Açúcar de injeção de dependências por contexto

O sistema SHALL oferecer `context.read<T>()` como atalho de resolução de dependências, delegando à resolução do container de DI (equivalente a `Bind.get<T>()`). Quando o tipo não está registrado, a resolução MUST falhar da mesma forma que a resolução direta do container.

Arquivos de referência: `lib/src/extensions/context_extension.dart`, `lib/src/core/bind/bind.dart`.

#### Scenario: context.read resolve a dependência registrada

- **WHEN** um bind de `MeuServico` está registrado e `context.read<MeuServico>()` é chamado
- **THEN** o sistema retorna a instância resolvida pelo container

#### Scenario: context.read de tipo não registrado falha

- **WHEN** `context.read<TipoInexistente>()` é chamado sem o tipo registrado
- **THEN** a resolução falha com a mesma exceção da resolução direta do container
