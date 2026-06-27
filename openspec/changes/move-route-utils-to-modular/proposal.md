## Why

Hoje os utilitários de **leitura** da rota atual (`getPathParam`, `getPath`, `state`) vivem na `GoRouterExtension` sobre `BuildContext`, misturados com a navegação assíncrona (`goAsync`, `pushAsync`, etc.) e com os utilitários de pop. Isso sobrecarrega a extension (viola Single Responsibility: a extension passa a ter dois motivos para mudar — navegação e leitura de estado), polui o autocomplete de **todo** `BuildContext` do app e duplica conceito com `GoRouterModular.getCurrentPathOf`/`stateOf`, que já existem na fachada. Além disso, os utilitários úteis do `go_router` (leitura de estado, parâmetros de path e query, location/uri) não têm um ponto de acesso explícito e descoberto pela fachada `GoRouterModular`, deixando o consumidor entre "usar a extension modular" ou "cavar o `GoRouterState` cru".

Consolidar a leitura na fachada `GoRouterModular` (com nomes melhores e consistentes) e expor wrappers explícitos para os utilitários do `go_router` deixa a API mais coesa, descoberta por um único ponto e alinhada a SOLID/Clean Code, sem quebrar quem já usa a extension.

## What Changes

- **Mover a leitura de estado para a fachada `GoRouterModular`** com nomes melhores e consistentes com os já existentes (`stateOf`, `getCurrentPathOf`), padrão `...Of(context)`:
  - `GoRouterModular.routerStateOf(context)` → o `GoRouterState` corrente.
  - `GoRouterModular.currentPathOf(context)` → o path corrente (`String?`).
  - `GoRouterModular.pathParamOf(context, name)` → um parâmetro de path por nome (`String?`).
- **Adicionar wrappers explícitos na fachada `GoRouterModular`** para os utilitários mais úteis do `go_router`, dando um ponto único de descoberta:
  - `GoRouterModular.pathParamsOf(context)` → todos os `pathParameters`.
  - `GoRouterModular.queryParamsOf(context)` → todos os `queryParameters`.
  - `GoRouterModular.queryParamOf(context, name)` → um query parameter por nome.
  - `GoRouterModular.currentUriOf(context)` → o `Uri` corrente.
  - `GoRouterModular.currentLocationOf(context)` → a location corrente (`matchedLocation`).
  - `GoRouterModular.extraOf<T>(context)` → o `extra` tipado da rota.
- **Reconciliar os nomes legados na fachada**: `getCurrentPathOf` e `stateOf` passam a ser `@Deprecated` apontando para `currentPathOf` e `routerStateOf`, mantendo uma convenção de nomes única.
- **Depreciar (sem remover) a leitura na `GoRouterExtension`**: `getPathParam`, `getPath` e `state` recebem `@Deprecated` apontando para os equivalentes em `GoRouterModular`. A navegação assíncrona (`*Async`) e os utilitários de pop (`popUntil`, `popUntilNamed`) **permanecem** na extension.
- **Garantir/registrar a re-exportação** dos utilitários do `go_router` (ex.: `GoRouterState`) pelo barril principal, para que o consumidor possa usá-los diretamente caso prefira.
- Nenhuma mudança **BREAKING** nesta release: tudo que sai da extension continua acessível via `@Deprecated`; a remoção fica para uma major futura.

## Capabilities

### New Capabilities
<!-- Nenhuma capability nova: a mudança reorganiza e amplia comportamento já coberto. -->

### Modified Capabilities
- `routing-navigation`: a "Leitura de estado e parâmetros da rota atual" deixa de ser oferecida **apenas** por extension de `BuildContext` e passa a ser oferecida pela fachada `GoRouterModular` com nomes consistentes (`routerStateOf`, `currentPathOf`, `pathParamOf`) e novos acessos (path params, query params, uri, location, extra). As entradas correspondentes na extension passam a ser `@Deprecated`.
- `public-api-surface`: registra explicitamente que os utilitários úteis do `go_router` re-exportados (ex.: `GoRouterState`) compõem a superfície pública e ficam acessíveis ao consumidor por um único import, sem vazar os tipos substituídos (`GoRouter`, `ShellRoute`).

## Impact

- Código afetado:
  - `lib/src/ui/route_extension.dart` — depreciar `getPathParam`, `getPath`, `state` (sem remover); manter navegação e pop.
  - `lib/src/bootstrap/go_router_modular_configure.dart` — adicionar `routerStateOf`, `currentPathOf`, `pathParamOf` e os wrappers de `go_router` (`pathParamsOf`, `queryParamsOf`, `queryParamOf`, `currentUriOf`, `currentLocationOf`, `extraOf`); depreciar `getCurrentPathOf`/`stateOf`.
  - `lib/go_router_modular.dart` — confirmar/ajustar a re-exportação dos utilitários do `go_router`.
- API pública: ampliada (novos métodos estáticos) e com símbolos depreciados; sem remoção nesta release.
- Documentação: README/site precisam apontar a nova forma preferida de ler estado da rota.
- Testes: novos testes para os métodos da fachada e para a presença dos avisos de depreciação; meta de cobertura 100% mantida.

## Non-goals (Não-objetivos)

- Não remover nesta release `getPathParam`/`getPath`/`state` da extension nem `getCurrentPathOf`/`stateOf` da fachada — apenas depreciar; a remoção é uma mudança major separada.
- Não alterar a navegação assíncrona (`*Async`) nem os utilitários de pop (`popUntil`, `popUntilNamed`), que continuam na extension.
- Não reescrever ou encapsular o `go_router`: os wrappers apenas delegam ao `GoRouterState`/`GoRouter`, sem mudar semântica.
- Não introduzir novos pacotes nem mudar a estratégia de injeção de dependências.
