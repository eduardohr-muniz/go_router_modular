## MODIFIED Requirements

### Requirement: ChildRoute mapeia para GoRoute folha

O sistema SHALL converter cada `ChildRoute` em um `GoRoute` que renderiza um widget. O `ChildRoute` MUST aceitar `path`, `child` (builder de widget), `name` opcional, `pageBuilder` opcional, `parentNavigatorKey`, `guards` (lista de `ModularGuard`, default `const []`), `redirect` (`@Deprecated`, mantido por compatibilidade), `onExit`, `transition` e `transitionDuration`. Quando `guards` e/ou `redirect` são fornecidos, o `GoRoute` resultante MUST receber, no seu slot `redirect`, a função composta `[...guards, GuardFn(redirect)]` (ver capability `routing-guards`). Um `ChildRoute` cujo path normaliza para `/` MUST NOT ser registrado como rota folha top-level — ele representa o índice do módulo.

Arquivos de referência: `lib/src/routing/child_route.dart`, `lib/src/routing/builders/child_route_builder.dart`.

#### Scenario: ChildRoute simples vira GoRoute com builder

- **WHEN** um módulo declara `ChildRoute('/home', child: ...)` sem `pageBuilder` nem `transition`
- **THEN** o sistema cria um `GoRoute` cujo `builder` renderiza o widget do `ChildRoute`

#### Scenario: ChildRoute com pageBuilder usa o pageBuilder fornecido

- **WHEN** um `ChildRoute` define `pageBuilder`
- **THEN** o `GoRoute` resultante usa esse `pageBuilder` diretamente

#### Scenario: ChildRoute índice é excluído das rotas folha

- **WHEN** um módulo declara `ChildRoute('/', child: ...)`
- **THEN** ele não é emitido como rota folha separada; serve como conteúdo padrão do módulo

#### Scenario: ChildRoute com guards compõe o redirect do GoRoute

- **WHEN** um `ChildRoute('/admin', guards: [AuthGuard()], child: ...)` é construído
- **THEN** o `GoRoute` resultante recebe no slot `redirect` a função composta que avalia `AuthGuard` em curto-circuito

#### Scenario: ChildRoute sem guards nem redirect não tem redirect

- **WHEN** um `ChildRoute` declara `guards: const []` e nenhum `redirect`
- **THEN** a função composta retorna `null` e a rota não redireciona

### Requirement: ModuleRoute monta um módulo aninhado com ciclo de vida

O sistema SHALL converter `ModuleRoute` em um `GoRoute` cujo path é o segmento do módulo e cujas rotas filhas são as rotas do módulo (construídas com `topLevel = false`). O `ModuleRoute` MUST aceitar `path`, `module`, `name` opcional e `guards` (lista de `ModularGuard`, default `const []`). O `GoRoute` resultante MUST acoplar o registro dos binds do módulo no `redirect` (ver capability `routing-lifecycle`) e, em seguida, avaliar a função composta dos `guards` do `ModuleRoute`. Os `guards` MUST ser aplicados nos três ramos de construção do módulo: módulo regular, shell de módulo e stateful shell de módulo.

Arquivos de referência: `lib/src/routing/module_route.dart`, `lib/src/routing/builders/module_route_builder.dart`, `lib/src/module/module.dart`.

#### Scenario: ModuleRoute compõe path do módulo com a rota índice

- **WHEN** um `ModuleRoute('/auth', module: AuthModule)` cujo `AuthModule` tem `ChildRoute('/', ...)` é construído
- **THEN** a rota efetiva do índice do módulo é `/auth`
- **AND** uma `ChildRoute('/login')` do mesmo módulo resolve para `/auth/login`

#### Scenario: guards do ModuleRoute protegem todas as rotas do módulo

- **WHEN** um `ModuleRoute('/admin', module: AdminModule, guards: [AuthGuard()])` é navegado para qualquer rota interna
- **THEN** o `AuthGuard` é avaliado após o registro dos binds e pode redirecionar antes de a tela montar

#### Scenario: guards do ModuleRoute aplicam-se ao ramo stateful shell

- **WHEN** um `ModuleRoute` cujo módulo é um stateful shell declara `guards` e um guard retorna uma rota
- **THEN** o redirecionamento do guard ocorre antes do redirect interno de "ir para a primeira branch"

### Requirement: ShellModularRoute mapeia para ShellRoute com layout compartilhado

O sistema SHALL converter `ShellModularRoute` em um `ShellRoute` cujo `builder` envolve o navigator filho com um layout comum. O `ShellModularRoute` MUST aceitar `builder` (que recebe o `child`), `routes` filhas, `guards` (lista de `ModularGuard`, default `const []`), `redirect` (`@Deprecated`, mantido por compatibilidade), `pageBuilder`, `observers`, `navigatorKey`, `parentNavigatorKey` e `restorationScopeId`. Quando `guards` e/ou `redirect` são fornecidos, o `ShellRoute` MUST receber no seu slot `redirect` a função composta `[...guards, GuardFn(redirect)]`. Uma `ChildRoute` cujo path normaliza para `/` MUST NOT ser filha direta de um shell (deve ser rejeitada por asserção em desenvolvimento).

Arquivos de referência: `lib/src/routing/shell_modular_route.dart`, `lib/src/routing/builders/shell_route_builder.dart`.

#### Scenario: Shell envolve filhas com layout comum

- **WHEN** um `ShellModularRoute` declara `builder` e rotas filhas `ChildRoute`/`ModuleRoute`
- **THEN** o `ShellRoute` resultante renderiza o `builder` com o navigator das filhas como `child`

#### Scenario: ChildRoute índice direta no shell é rejeitada em desenvolvimento

- **WHEN** um `ShellModularRoute` declara uma `ChildRoute('/')` como filha direta
- **THEN** uma asserção falha em modo de desenvolvimento indicando a configuração inválida

#### Scenario: guards do shell compõem o redirect do ShellRoute

- **WHEN** um `ShellModularRoute` declara `guards: [AuthGuard()]`
- **THEN** o `ShellRoute` recebe no slot `redirect` a função composta que avalia os guards em curto-circuito

### Requirement: StatefulShellModularRoute mapeia para StatefulShellRoute com branches

O sistema SHALL converter `StatefulShellModularRoute` em um `StatefulShellRoute`, com uma `StatefulShellBranch` por branch declarada, preservando o estado de cada branch. O tipo MUST aceitar `branches`, `builder` (recebe a `StatefulNavigationShell`), `transition`/`transitionDuration`/`reverseTransitionDuration`, `navigatorContainerBuilder`, `guards` (lista de `ModularGuard`, default `const []`), `redirect` (`@Deprecated`, mantido por compatibilidade) e `shellKey`. A função composta `[...guards, GuardFn(redirect)]` MUST ser avaliada antes de qualquer redirect interno de seleção de branch. Uma branch MUST poder ser declarada por rotas (`ModularBranch`) ou diretamente por um módulo (`ModuleBranch`), e os paths das branches MUST ser únicos dentro do mesmo shell.

Arquivos de referência: `lib/src/routing/stateful_shell_modular_route.dart`, `lib/src/routing/builders/shell_route_builder.dart`.

#### Scenario: Cada branch vira uma StatefulShellBranch com rotas próprias

- **WHEN** um `StatefulShellModularRoute` declara duas branches com rotas distintas
- **THEN** o `StatefulShellRoute` resultante contém uma branch por declaração, cada uma com suas rotas construídas recursivamente

#### Scenario: ModuleBranch é atalho para uma branch com ModuleRoute

- **WHEN** uma branch é declarada como `ModuleBranch('/home', module: HomeModule)`
- **THEN** ela equivale a uma branch contendo `ModuleRoute('/home', module: HomeModule)`

#### Scenario: guard do stateful shell barra antes da seleção de branch

- **WHEN** um `StatefulShellModularRoute` declara `guards: [AuthGuard()]` e `AuthGuard` retorna `'/login'`
- **THEN** a navegação é redirecionada para `'/login'` sem aplicar o redirect interno de "ir para a primeira branch"
