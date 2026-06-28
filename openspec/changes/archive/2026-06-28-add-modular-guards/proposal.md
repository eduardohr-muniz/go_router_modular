## Why

Hoje a única forma de proteger uma rota é passar uma função `redirect` crua (a mesma assinatura do go_router) em cada rota. Isso resulta em funções monolíticas, não reutilizáveis e cheias de `if`-chains manuais — uma checagem de autenticação repetida em dezenas de rotas vira copy-paste. Queremos uma unidade de proteção **reutilizável e componível**: `class XGuard extends ModularGuard`, declarada como uma lista `guards: [AuthGuard(), RoleGuard('admin')]` na rota, resolvendo em curto-circuito ("primeiro que barrar vence"). O guard não é mecanismo novo — é o `redirect` encapsulado e nomeado; por baixo dos panos continua sendo o go_router que gerencia a navegação.

## What Changes

- Introduz `ModularGuard`, classe abstrata com um único método `redirect(BuildContext, GoRouterState) -> FutureOr<String?>`. Retornar `null` = libera; retornar uma rota = redireciona.
- Introduz `GuardFn`, adapter que embrulha uma função `redirect` em um `ModularGuard` (escape hatch para quem não quer criar classe, e ponte do `redirect` legado).
- Adiciona o campo `guards: List<ModularGuard>` (default `const []`, portanto **não-breaking**) em `ChildRoute`, `ModuleRoute`, `ShellModularRoute` e `StatefulShellModularRoute`.
- Adiciona o parâmetro `guards: List<ModularGuard>` (default `const []`) ao `GoRouterModular.configure`, como proteção **global** aplicada a toda navegação; o `redirect` global do `configure` vira `@Deprecated` e compõe como `[...guards, GuardFn(redirect)]`.
- A lista de guards **colapsa numa única função `redirect`** (fold "primeiro não-nulo vence") entregue no mesmo slot `redirect:` do `GoRoute` que os builders já preenchem hoje. Nenhuma mudança no motor de navegação nem no ciclo de binds.
- Marca o parâmetro `redirect` atual das rotas como **`@Deprecated`** (continua funcionando até a v6.0.0). Quando `guards` e `redirect` coexistem, a ordem efetiva é `[...guards, GuardFn(redirect)]` — o legado vira o último elo do fold.
- Guards acessam o DI via `Modular.get` normalmente, pois os binds do módulo já estão registrados antes do guard rodar (a ordem `registra binds -> roda guard` já é a que existe hoje no `redirect`).

Justificativa de engenharia:
- **SRP / Single Responsibility**: cada guard tem um único motivo para mudar (uma regra de acesso), em vez de uma função-canivete por rota.
- **Open/Closed**: novas regras de acesso entram como novas subclasses de `ModularGuard`, sem alterar os builders nem as rotas existentes.
- **DRY / Clean Code**: um `AuthGuard` é declarado uma vez e reutilizado em todas as rotas, eliminando a duplicação de `if`-chains de redirect.
- **Coleção de primeira classe (Object Calisthenics)**: a lista de guards é resolvida por um único ponto de fold com curto-circuito, sem indentação aninhada espalhada pelos builders.

## Capabilities

### New Capabilities
- `routing-guards`: define o contrato de `ModularGuard` e `GuardFn`, a resolução em curto-circuito de uma lista de guards numa única função redirect, a ordem de composição com o `redirect` legado e o acesso ao DI a partir de um guard.

### Modified Capabilities
- `routing-routes`: os quatro tipos de rota (`ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `StatefulShellModularRoute`) passam a aceitar `guards: List<ModularGuard>`; `ChildRoute`/`ShellModularRoute`/`StatefulShellModularRoute` têm seu `redirect` marcado como `@Deprecated`; `ModuleRoute` — que hoje não tem redirect — ganha `guards` plugado nos três ramos de construção (regular, shell e stateful shell).
- `routing-lifecycle`: formaliza que os guards rodam **depois** do registro de binds do módulo (para que `Modular.get` funcione dentro do guard) e **antes** do redirect de "ir para a primeira branch" do stateful shell.
- `routing-configuration`: `GoRouterModular.configure` passa a aceitar `guards` (proteção global); seu `redirect` vira `@Deprecated` e a função global entregue ao `GoRouter` é a composição `[...guards, GuardFn(redirect)]`.
- `public-api-surface`: o barril principal passa a exportar `ModularGuard` e `GuardFn`.

## Impact

- **APIs públicas**: `lib/src/routing/child_route.dart`, `module_route.dart`, `shell_modular_route.dart`, `stateful_shell_modular_route.dart` (novo campo `guards`, deprecação de `redirect`); novo arquivo de guards em `lib/src/routing/guards/`; export em `lib/go_router_modular.dart`.
- **Builders**: `lib/src/routing/builders/child_route_builder.dart`, `module_route_builder.dart`, `shell_route_builder.dart` passam a montar a função via fold de guards em vez de repassar `redirect` diretamente; `module_route_lifecycle.dart` continua recebendo a função composta no parâmetro `redirect` que já possui.
- **Compatibilidade**: aditivo e não-breaking na v1.x (campo opcional com default vazio + `redirect` deprecado mas funcional). Remoção do `redirect` fica planejada para a v6.0.0 (**BREAKING** futuro, fora do escopo desta mudança).
- **Documentação**: skill `go-router-modular` e site de docs precisam registrar o novo padrão `guards: []` como forma recomendada de proteção de rota.

## Non-goals

- **Não** remover o parâmetro `redirect` nesta mudança — apenas deprecá-lo. A remoção é um breaking change reservado para a v6.0.0.
- **Não** dar ao guard poderes além de redirecionar (sem `canActivate -> bool`, sem disparar dialog/snackbar/efeito colateral a partir do guard). O contrato é estritamente `redirect`; efeitos colaterais continuam responsabilidade da tela.
- **Não** alterar o motor de navegação, o `redirectLimit`, a ordem de resolução na árvore de rotas nem o ciclo de registro/descarte de binds. O aninhamento ao longo da hierarquia continua sendo resolvido pelo próprio go_router.
- **Não** introduzir guards assíncronos com semântica nova de loading além do `ModularLoader` que o ciclo de binds já exibe.
