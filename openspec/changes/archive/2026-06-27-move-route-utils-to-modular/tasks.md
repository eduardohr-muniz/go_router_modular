## 1. Fachada: novos métodos de leitura de estado

- [x] 1.1 Em `lib/src/bootstrap/go_router_modular_configure.dart`, adicionar `static GoRouterState routerStateOf(BuildContext context)` delegando a `GoRouterState.of(context)`, com doc `///`.
- [x] 1.2 Adicionar `static String? currentPathOf(BuildContext context)` delegando a `GoRouterState.of(context).path`, com doc `///`.
- [x] 1.3 Adicionar `static String? pathParamOf(BuildContext context, String name)` delegando a `GoRouterState.of(context).pathParameters[name]`, com doc `///`.

## 2. Fachada: wrappers dos utilitários do go_router

- [x] 2.1 Adicionar `static Map<String, String> pathParamsOf(BuildContext context)`.
- [x] 2.2 Adicionar `static Map<String, String> queryParamsOf(BuildContext context)` e `static String? queryParamOf(BuildContext context, String name)`.
- [x] 2.3 Adicionar `static Uri currentUriOf(BuildContext context)` e `static String currentLocationOf(BuildContext context)` (a partir de `matchedLocation`).
- [x] 2.4 Adicionar `static T? extraOf<T>(BuildContext context)` lendo `GoRouterState.of(context).extra` com cast tipado, com doc `///`.

## 3. Depreciação dos símbolos legados

- [x] 3.1 Marcar `getCurrentPathOf` como `@Deprecated('Use Modular.currentPathOf')` e fazê-lo delegar a `currentPathOf`.
- [x] 3.2 Marcar `stateOf` como `@Deprecated('Use Modular.routerStateOf')` e fazê-lo delegar a `routerStateOf`.
- [x] 3.3 Em `lib/src/ui/route_extension.dart`, marcar `getPathParam`, `getPath` e `state` como `@Deprecated(...)` apontando para a fachada, fazendo cada um delegar ao método novo (sem reimplementar a lógica).

## 4. Superfície pública (re-export do go_router)

- [x] 4.1 Confirmar em `lib/go_router_modular.dart` o re-export `package:go_router/go_router.dart` com `hide GoRouter, ShellRoute`; ajustar se necessário para manter `GoRouterState` e `GoRouterHelper` acessíveis.

## 5. Testes

- [x] 5.1 Testar `routerStateOf`, `currentPathOf` e `pathParamOf` (sucesso e `null`/ausente) com um `GoRouter` real.
- [x] 5.2 Testar `pathParamsOf`, `queryParamsOf`, `queryParamOf`, `currentUriOf`, `currentLocationOf` e `extraOf<T>` (sucesso e casos vazios/ausentes).
- [x] 5.3 Testar equivalência: cada símbolo `@Deprecated` retorna o mesmo resultado do método novo.
- [x] 5.4 Testar a superfície pública: `GoRouterState` e `GoRouterHelper` acessíveis pelo barril, sem `GoRouter`/`ShellRoute` vazando.
- [x] 5.5 Rodar `flutter test --coverage` e verificar 100% de cobertura no `coverage/lcov.info` para os arquivos tocados.

## 6. Documentação

- [x] 6.1 Atualizar README/site indicando a forma preferida de ler estado da rota (`Modular.*Of`) e os avisos de depreciação.
- [x] 6.2 Rodar `dart analyze`/`flutter analyze` e garantir ausência de warnings (exceto os `@Deprecated` esperados em testes de equivalência, se houver).
