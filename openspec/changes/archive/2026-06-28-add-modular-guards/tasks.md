## 1. Núcleo dos guards

- [x] 1.1 Criar `lib/src/routing/guards/modular_guard.dart` com a classe abstrata `ModularGuard` e o método `FutureOr<String?> redirect(BuildContext context, GoRouterState state)`, documentado com `///` (retornar `null` libera, retornar rota redireciona; o guard recebe `context` e `state` para ler DI via `Modular.get` e dados da navegação via `state.uri`/`state.pathParameters`/`state.extra`).
- [x] 1.2 Criar `lib/src/routing/guards/guard_fn.dart` com `GuardFn`, subclasse concreta de `ModularGuard` que recebe `FutureOr<String?> Function(BuildContext context, GoRouterState state)` e delega no `redirect`.
- [x] 1.3 Criar `lib/src/routing/guards/guard_resolver.dart` com a função que reduz uma `List<ModularGuard>` a uma única função de redirect com curto-circuito ("primeiro não-nulo vence"), incluindo o caso de lista vazia (retorna `null`) e a composição `[...guards, GuardFn(redirect)]` quando há um `redirect` legado.
- [x] 1.4 Escrever testes de `ModularGuard`, `GuardFn` e do resolver cobrindo: guard libera (`null`), guard barra (rota), curto-circuito interrompe os seguintes, lista vazia, guard assíncrono aguardado, composição com `redirect` legado em ambas as ordens (guard barra antes / legado roda quando guards liberam), e preservação do comportamento com apenas `redirect`.

## 2. Campo `guards` e deprecação do `redirect` nas rotas

- [x] 2.1 Adicionar `final List<ModularGuard> guards` (default `const []`) a `ChildRoute` e marcar o parâmetro `redirect` com `@Deprecated('Use guards: [GuardFn(...)]. Será removido na v6.0.0')`.
- [x] 2.2 Adicionar `final List<ModularGuard> guards` (default `const []`) a `ModuleRoute` (que hoje não possui redirect).
- [x] 2.3 Adicionar `final List<ModularGuard> guards` (default `const []`) a `ShellModularRoute` e marcar `redirect` com `@Deprecated`.
- [x] 2.4 Adicionar `final List<ModularGuard> guards` (default `const []`) a `StatefulShellModularRoute` e marcar `redirect` com `@Deprecated`.
- [x] 2.5 Escrever testes verificando que os quatro tipos aceitam `guards`, têm default `const []`, e que o `redirect` continua aceito (compatibilidade) nos três tipos que já o possuíam.

## 3. Integração nos builders

- [x] 3.1 Em `child_route_builder.dart`, substituir o repasse de `redirect` pela função composta do resolver `[...childRoute.guards, GuardFn(childRoute.redirect)]` no slot `redirect` do `GoRoute` (cobrindo os ramos com e sem transition).
- [x] 3.2 Em `module_route_builder.dart`, plugar a função composta dos `guards` do `ModuleRoute` no parâmetro `redirect` de `redirectAndInjectBinds` nos três ramos (módulo regular, shell, stateful shell), garantindo a avaliação após o registro de binds.
- [x] 3.3 No ramo stateful shell do `module_route_builder.dart`, garantir que a função composta dos guards seja avaliada e possa retornar uma rota **antes** do redirect interno de seleção da primeira branch.
- [x] 3.4 Em `shell_route_builder.dart`, plugar a função composta dos `guards` nos slots `redirect` do `ShellRoute` e do `StatefulShellRoute`.
- [x] 3.5 Escrever testes de integração dos builders: guard no `ChildRoute` redireciona; guard no `ModuleRoute` protege rotas internas e resolve `Modular.get` (binds registrados antes); guard no shell redireciona; guard no stateful shell barra antes da seleção da primeira branch; coexistência `guards` + `redirect` legado respeita a ordem.

## 4. Superfície pública e documentação

- [x] 4.1 Exportar `ModularGuard` e `GuardFn` no barril `lib/go_router_modular.dart` na área de roteamento.
- [x] 4.2 Escrever teste confirmando que `ModularGuard` e `GuardFn` são acessíveis apenas com o import do barril, sem imports de `src/`.
- [x] 4.3 Atualizar a skill `go-router-modular` e o site de documentação registrando `guards: []` como forma recomendada de proteção de rota e o `redirect` como deprecado, com exemplo de `class AuthGuard extends ModularGuard` lendo serviço via `Modular.get` e usando `state`.

## 6. Guards globais no `configure`

- [x] 6.1 Adicionar `guards: List<ModularGuard>` (default `const []`) ao `Modular.configure` e marcar o parâmetro `redirect` global com `@Deprecated`, resolvendo `[...guards, GuardFn(redirect)]` no `redirect` entregue ao `GoRouter` via `resolveGuards`.
- [x] 6.2 Escrever testes de integração do guard global: desvia a rota inicial, bloqueia navegação para rota protegida, libera rota isenta, e coexistência `guards` + `redirect` legado (guards liberam → legado decide).

## 5. Verificação final

- [x] 5.1 Rodar `flutter analyze` e garantir zero issues (avisos de `@Deprecated` apenas nos pontos de teste de compatibilidade, isolados).
- [x] 5.2 Rodar `flutter test --coverage` e confirmar 100% de cobertura (linhas e branches) dos novos arquivos de guards e dos ramos alterados nos builders via `coverage/lcov.info`.
