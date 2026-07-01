# Guards de Rota

## RENAMED Requirements

- FROM: `### Requirement: ModularGuard encapsula um redirect nomeado e reutilizável`
- TO: `### Requirement: RouteGuard encapsula um redirect nomeado e reutilizável`

- FROM: `### Requirement: GuardFn adapta uma função para ModularGuard`
- TO: `### Requirement: GuardFn adapta uma função para RouteGuard`

## MODIFIED Requirements

### Requirement: RouteGuard encapsula um redirect nomeado e reutilizável

O sistema SHALL definir `RouteGuard` como classe abstrata com um único método `redirect(BuildContext context, GoRouterState state)` que retorna `FutureOr<String?>`. Retornar `null` MUST liberar a navegação; retornar uma rota (String não-nula) MUST redirecionar para essa rota. Uma subclasse de `RouteGuard` MUST poder ser reutilizada em múltiplas rotas sem reescrever a regra.

Arquivos de referência: `lib/src/routing/guards/route_guard.dart`.

#### Scenario: Guard que libera retorna null

- **WHEN** um `RouteGuard` avalia uma condição satisfeita e retorna `null`
- **THEN** a navegação prossegue para a rota de destino sem redirecionamento

#### Scenario: Guard que barra retorna a rota de destino

- **WHEN** um `RouteGuard` avalia uma condição não satisfeita e retorna `'/login'`
- **THEN** a navegação é redirecionada para `/login`

#### Scenario: Mesmo guard reutilizado em rotas diferentes

- **WHEN** uma mesma instância/classe de `RouteGuard` é declarada em duas rotas distintas
- **THEN** ambas as rotas aplicam a mesma regra de proteção sem duplicação de lógica

### Requirement: GuardFn adapta uma função para RouteGuard

O sistema SHALL fornecer `GuardFn`, uma subclasse concreta de `RouteGuard` que recebe uma função `FutureOr<String?> Function(BuildContext, GoRouterState)` e a expõe pelo método `redirect`. `GuardFn` MUST ser substituível por qualquer `RouteGuard` (Liskov), de modo que a resolução de uma lista não distinga entre um guard de classe nomeada e um `GuardFn`.

Arquivos de referência: `lib/src/routing/guards/guard_fn.dart`.

#### Scenario: GuardFn delega para a função fornecida

- **WHEN** um `GuardFn((context, state) => '/login')` é avaliado
- **THEN** o resultado do `redirect` é exatamente o retorno da função fornecida (`'/login'`)

#### Scenario: GuardFn convive na mesma lista que guards de classe

- **WHEN** uma lista contém `[AuthGuard(), GuardFn((c, s) => null)]`
- **THEN** a resolução trata ambos uniformemente como `RouteGuard`

### Requirement: Lista de guards resolve em curto-circuito numa única função

O sistema SHALL reduzir uma `List<RouteGuard>` a uma única função `FutureOr<String?> Function(BuildContext, GoRouterState)` que percorre os guards na ordem declarada e retorna a primeira rota não-nula encontrada (curto-circuito "primeiro que barrar vence"). Se todos os guards retornarem `null`, a função composta MUST retornar `null`. Uma lista vazia MUST resultar em `null` (nenhum redirecionamento).

Arquivos de referência: `lib/src/routing/guards/guard_resolver.dart`.

#### Scenario: Primeiro guard que barra interrompe a cadeia

- **WHEN** a lista `[A, B, C]` é avaliada e `A` retorna `null`, `B` retorna `'/home'`
- **THEN** a função composta retorna `'/home'`
- **AND** `C` não é avaliado

#### Scenario: Todos os guards liberam

- **WHEN** todos os guards da lista retornam `null`
- **THEN** a função composta retorna `null` e a navegação prossegue

#### Scenario: Lista vazia não redireciona

- **WHEN** a lista de guards é `const []`
- **THEN** a função composta retorna `null`

#### Scenario: Guard assíncrono é aguardado antes do próximo

- **WHEN** um guard retorna um `Future<String?>` que resolve para `'/login'`
- **THEN** a função composta aguarda a resolução e retorna `'/login'` sem avaliar os guards seguintes
