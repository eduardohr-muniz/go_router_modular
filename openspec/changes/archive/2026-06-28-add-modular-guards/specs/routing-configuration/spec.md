## MODIFIED Requirements

### Requirement: Configuração e construção do GoRouter

O sistema SHALL expor `GoRouterModular.configure` como ponto único de inicialização do roteamento, recebendo o `appModule` e a `initialRoute` obrigatórios, além de parâmetros opcionais repassados ao `GoRouter` (`guards`, `errorBuilder`, `observers`, `navigatorKey`, `debugLogDiagnostics`, entre outros). O `configure` MUST aceitar `guards` (lista de `ModularGuard`, default `const []`) como forma de proteção global, e MUST aceitar `redirect` (`@Deprecated`, mantido por compatibilidade). A função efetiva de redirecionamento global entregue ao `GoRouter` MUST ser a composição `[...guards, GuardFn(redirect)]` resolvida em curto-circuito (ver capability `routing-guards`). A configuração MUST construir as rotas a partir do `appModule` no nível top-level e MUST retornar uma instância única de `GoRouter` (chamadas subsequentes retornam a mesma instância).

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/routing/guards/guard_resolver.dart`, `lib/src/module/module.dart`.

#### Scenario: configure constrói o router a partir do appModule

- **WHEN** `configure(appModule: AppModule(), initialRoute: '/')` é chamado
- **THEN** as rotas top-level são construídas a partir do `AppModule`
- **AND** um `GoRouter` é criado com a `initialLocation` igual à `initialRoute`

#### Scenario: configure é idempotente

- **WHEN** `configure` é chamado uma segunda vez após o router já existir
- **THEN** a mesma instância de `GoRouter` é retornada sem reconstruir as rotas

#### Scenario: guards globais protegem toda navegação

- **WHEN** `configure(..., guards: [AuthGuard()])` é chamado e `AuthGuard` retorna uma rota para a localização atual
- **THEN** o `GoRouter` recebe um `redirect` global que avalia os guards em curto-circuito
- **AND** a navegação para qualquer rota não isenta é desviada para a rota retornada pelo guard

#### Scenario: guards globais e redirect legado coexistem na ordem correta

- **WHEN** `configure` recebe `guards` e também o `redirect` legado, e todos os guards liberam (`null`)
- **THEN** o `redirect` legado é avaliado por último e decide o destino
