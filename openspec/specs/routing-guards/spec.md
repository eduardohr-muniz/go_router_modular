# Guards de Rota

## Purpose

Define o contrato de guards de rota modular: `RouteGuard` como redirect nomeado e reutilizável, o adaptador `GuardFn`, a resolução em curto-circuito de uma lista de guards, a composição do `redirect` legado como último elo da cadeia e o acesso a dependências do DI a partir de um guard.

## Requirements

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

### Requirement: redirect legado compõe como último elo da cadeia de guards

O sistema SHALL, quando uma rota declara `guards` e também o `redirect` (legado, `@Deprecated`), compor a função efetiva como `[...guards, GuardFn(redirect)]` — os guards rodam primeiro, e o `redirect` legado é avaliado por último apenas se todos os guards liberarem. Quando apenas `redirect` é declarado (sem `guards`), o comportamento MUST permanecer idêntico ao atual.

Arquivos de referência: `lib/src/routing/guards/guard_resolver.dart`, `lib/src/routing/builders/`.

#### Scenario: Guards têm prioridade sobre o redirect legado

- **WHEN** uma rota declara `guards: [AuthGuard()]` e `redirect: legacyFn`, e `AuthGuard` retorna `'/login'`
- **THEN** a função efetiva retorna `'/login'`
- **AND** `legacyFn` não é avaliado

#### Scenario: redirect legado roda quando os guards liberam

- **WHEN** todos os guards retornam `null` e há um `redirect` legado que retorna `'/home'`
- **THEN** a função efetiva retorna `'/home'`

#### Scenario: Apenas redirect legado preserva comportamento atual

- **WHEN** uma rota declara somente `redirect` e nenhum guard
- **THEN** o comportamento é idêntico ao de passar `redirect` diretamente ao `GoRoute`

### Requirement: Guard pode resolver dependências via Modular.get

O sistema SHALL avaliar os guards de uma rota depois do registro dos binds do módulo correspondente, de modo que `Modular.get` dentro de um guard resolva as dependências do módulo. Um guard MUST NOT depender de binds de um módulo cuja rota ainda não foi ativada.

Arquivos de referência: `lib/src/routing/redirect/module_route_lifecycle.dart`, `lib/src/di/injector.dart`.

#### Scenario: Guard lê serviço injetado do módulo ativado

- **WHEN** a rota de um módulo é ativada e seu guard chama `Modular.get<AuthService>()`
- **THEN** a dependência é resolvida porque os binds do módulo já foram registrados antes do guard rodar
