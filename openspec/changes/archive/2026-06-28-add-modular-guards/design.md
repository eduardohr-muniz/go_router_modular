## Context

O go_router_modular protege rotas hoje através de um parâmetro `redirect` cru — `FutureOr<String?> Function(BuildContext, GoRouterState)` — presente em `ChildRoute`, `ShellModularRoute` e `StatefulShellModularRoute` (o `ModuleRoute` não tem redirect próprio). Internamente, os builders (`module_route_builder.dart`, `child_route_builder.dart`, `shell_route_builder.dart`) já compõem esse redirect com a infraestrutura de DI: o `ModuleRouteLifecycle.redirectAndInjectBinds` registra os binds do módulo, mostra/esconde o `ModularLoader`, e **só então** chama o `redirect` do usuário. Ou seja, a composição de redirects já existe; ela só não está exposta como um conceito de primeira classe.

Esta mudança adiciona uma camada declarativa **por cima** desse mecanismo: `ModularGuard`. Um guard é o redirect encapsulado e nomeado. Uma lista `guards: []` colapsa numa única função `redirect` entregue no mesmo slot que os builders já preenchem. O go_router continua sendo o motor — ele resolve a ordem na árvore de rotas, o `redirectLimit` e o re-trigger.

## Goals / Non-Goals

**Goals:**
- Tornar a proteção de rota uma unidade reutilizável e componível (`class XGuard extends ModularGuard`).
- Resolver uma lista de guards em curto-circuito ("primeiro não-nulo vence") numa única função redirect.
- Disponibilizar `guards` nos quatro tipos de rota sem quebrar código existente (campo opcional `const []`).
- Manter o `redirect` legado funcional, porém `@Deprecated`, com ordem de composição previsível.
- Permitir `Modular.get` dentro de um guard (binds já registrados antes do guard rodar).

**Non-Goals:**
- Remover o `redirect` (fica para a v6.0.0).
- Dar ao guard semântica além de redirecionar (`canActivate -> bool`, dialogs, efeitos colaterais).
- Alterar o motor de navegação, o ciclo de binds ou a resolução hierárquica (delegada ao go_router).

## Decisions

### Decisão 1: `ModularGuard` como abstração de uma única responsabilidade
`ModularGuard` é uma classe abstrata com um único método `redirect(BuildContext, GoRouterState) -> FutureOr<String?>`. Retornar `null` libera; retornar uma rota redireciona.

- **Por que** uma classe e não um typedef? Para dar nome, reuso e testabilidade isolada a cada regra de acesso (um `AuthGuard` testado uma vez, usado em N rotas).
- **SRP**: cada subclasse tem um único motivo para mudar — uma regra. A função-canivete por rota deixa de existir.
- **Dependency Inversion**: os builders dependem da abstração `ModularGuard`, não de implementações concretas. Guards concretos são injetados pela lista declarada na rota.
- **Alternativa considerada**: manter apenas funções nomeadas (`Redirect authGuard(...)`). Rejeitada: funções soltas não comunicam intenção de "isto é um guard", não compõem por tipo e poluem o namespace.

### Decisão 2: `GuardFn` como adapter função → guard (Liskov)
`GuardFn` é uma subclasse concreta de `ModularGuard` que embrulha uma função `redirect`. Serve a dois propósitos:
1. Escape hatch para quem não quer criar uma classe: `guards: [GuardFn((ctx, s) => logged ? null : '/login')]`.
2. Ponte do `redirect` legado para o fold (ver Decisão 4).

- **Liskov**: `GuardFn` é substituível por qualquer `ModularGuard` — o fold não sabe nem precisa saber se é uma classe nomeada ou um adapter de função.

### Decisão 3: O fold "primeiro não-nulo vence" como ponto único de composição
A lista de guards é reduzida a uma função `String? Function(BuildContext, GoRouterState)` por um único helper de fold com curto-circuito: percorre os guards em ordem, retorna a primeira rota não-nula, ou `null` se todos liberarem.

- **Coleção de primeira classe (Object Calisthenics)**: a lógica de varredura vive em um lugar só, não espalhada por `if`-chains em cada builder.
- **Um nível de indentação**: o fold encapsula o laço; os builders apenas chamam o helper.
- **Open/Closed**: adicionar uma regra é adicionar um item à lista; o fold não muda.

### Decisão 4: `redirect` deprecado vira o último elo do fold
Quando uma rota declara `guards` e `redirect` simultaneamente, a função efetiva é `fold([...guards, GuardFn(redirect)])`. O legado é tratado como o último guard implícito.

- **Por que essa ordem?** Garante migração incremental previsível: guards novos rodam primeiro, o comportamento antigo permanece como fallback final. Regra única ("primeiro não-nulo vence") cobre os dois casos sem código especial.
- **Compatibilidade**: `guards` default `const []` torna a adição não-breaking; `@Deprecated` no `redirect` sinaliza a migração sem quebrar build.
- **Alternativa considerada**: `redirect` rodar antes dos guards. Rejeitada: faria o legado ter prioridade sobre a regra nova, o que é contraintuitivo durante a migração.

### Decisão 5: Guards rodam DEPOIS do registro de binds
A ordem em `redirectAndInjectBinds` permanece: registra binds do módulo → roda a função composta (fold dos guards). Assim `Modular.get<AuthService>()` dentro de um guard resolve normalmente.

- **Trade-off consciente**: um `ModuleRoute` cujo acesso é negado ainda paga o registro de binds antes do guard barrar. Como binds são factory/lazy e o descarte vem pela navegação, o custo é desprezível. Esta é a mesma ordem que o `ChildRoute` já usa hoje, então é consistente.
- **StatefulShell**: os guards devem rodar **antes** do redirect interno de "ir para a primeira branch". Caso contrário, redirecionaríamos para uma branch que o guard barraria. O fold é avaliado primeiro; se retornar rota, retorna-se imediatamente, sem aplicar a lógica de primeira branch.

### Decisão 6: `ModuleRoute` ganha `guards` plugado nos três ramos
O `ModuleRoute` hoje não tem redirect, mas seu builder constrói três formas (módulo regular, shell, stateful shell), cada uma passando `redirect: null` ou `redirect: childRoute.redirect` ao `redirectAndInjectBinds`. O campo `guards` do `ModuleRoute` é foldado e injetado nesse mesmo parâmetro nos três ramos.

## Exemplo de uso

### Definindo um guard reutilizável

O guard recebe `context` e `state` — o `context` dá acesso ao DI (binds já registrados antes do guard rodar) e o `state` dá acesso aos dados da navegação (`state.uri`, `state.pathParameters`, `state.extra`).

```dart
class AuthGuard extends ModularGuard {
  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final authService = Modular.get<AuthService>();
    if (authService.isLogged) return null; // libera
    // guarda o destino para voltar após o login
    return '/login?from=${state.uri.path}';
  }
}

class RoleGuard extends ModularGuard {
  RoleGuard(this.requiredRole);
  final String requiredRole;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final user = Modular.get<UserService>().current;
    if (user.hasRole(requiredRole)) return null;
    return '/home';
  }
}
```

### Usando no `ChildRoute`

A lista resolve em curto-circuito: `AuthGuard` roda primeiro; só se ele liberar (`null`) o `RoleGuard` é avaliado.

```dart
class AdminModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      '/admin',
      name: 'admin',
      guards: [AuthGuard(), RoleGuard('admin')],
      child: (context, state) => const AdminPage(),
    ),
  ];
}
```

### Guard inline com `GuardFn` (sem criar classe)

```dart
ChildRoute(
  '/beta',
  name: 'beta',
  guards: [
    GuardFn((context, state) {
      final flags = Modular.get<FeatureFlags>();
      return flags.betaEnabled ? null : '/home';
    }),
  ],
  child: (context, state) => const BetaPage(),
);
```

### Comparação com o `redirect` deprecado

```dart
// ANTES (@Deprecated) — função monolítica, não reutilizável
ChildRoute(
  '/admin',
  redirect: (context, state) async {
    final auth = Modular.get<AuthService>();
    if (!auth.isLogged) return '/login';
    final user = Modular.get<UserService>().current;
    if (!user.hasRole('admin')) return '/home';
    return null;
  },
  child: (context, state) => const AdminPage(),
);

// DEPOIS — guards reutilizáveis e componíveis
ChildRoute(
  '/admin',
  guards: [AuthGuard(), RoleGuard('admin')],
  child: (context, state) => const AdminPage(),
);
```

> Durante a migração, declarar `guards` e o `redirect` legado juntos é válido: a ordem efetiva é `[...guards, GuardFn(redirect)]` (ver Decisão 4).

## Risks / Trade-offs

- **[Binds registrados antes de um guard negar acesso no ModuleRoute]** → Mitigação: binds são lazy/factory; o ciclo de descarte da navegação recolhe o módulo. Documentar como comportamento esperado, não bug.
- **[Guards assíncronos lentos piscam o ModularLoader]** → Mitigação: o loader já é exibido durante o registro de binds; documentar que checagens longas (ex.: validar token no servidor) exibem o loader. Não introduzir novo mecanismo de loading.
- **[Coexistência redirect + guards confunde]** → Mitigação: ordem documentada e única (`[...guards, GuardFn(redirect)]`); `@Deprecated` orienta a migração; deprecação sinaliza remoção na v6.0.0.
- **[Stateful shell: ordem guard vs. primeira branch]** → Mitigação: cobertura de teste explícita do cenário "guard barra antes de redirecionar para a primeira branch".

## Migration Plan

- **v1.x (sem aviso)**: `redirect` funciona como hoje.
- **Esta mudança (v1.y)**: `guards: []` disponível nos quatro tipos; `redirect` marcado `@Deprecated` mas funcional; ambos compõem como `[...guards, GuardFn(redirect)]`. Aditivo e não-breaking.
- **v6.0.0 (futuro, fora do escopo)**: remoção do `redirect` (**BREAKING**); `guards` passa a ser a única forma.
- **Rollback**: como a adição é puramente aditiva (campo opcional + helper de fold + export), reverter é remover os campos/exports sem impacto em código que usa `redirect`.

## Open Questions

- O barril deve exportar um alias/`typedef` para a assinatura de função usada por `GuardFn`, ou basta documentar o uso inline? (Tendência: documentar inline, sem novo typedef público, para manter a superfície mínima.)
- Conveniência futura (fora do escopo): um `GuardFn` que receba o módulo/escopo para `Modular.get` tipado — avaliar somente após uso real.
