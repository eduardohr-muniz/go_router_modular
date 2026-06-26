# Tipos de Rota e Construção

## Purpose

Define os tipos de rota modular e sua conversão para o go_router (ChildRoute, ModuleRoute, ShellModularRoute, StatefulShellModularRoute e branches), a construção pelo ModularRouteBuilder e a normalização de paths.

## Requirements

### Requirement: Abstração de rota modular como marcador polimórfico

O sistema SHALL definir `ModularRoute` como tipo base abstrato de todos os tipos de rota modular, permitindo que o construtor de rotas selecione cada tipo por polimorfismo (`whereType<ChildRoute>()`, `whereType<ModuleRoute>()`, etc.). Adicionar um novo tipo de rota MUST ser possível criando uma nova subclasse e seu método de construção, sem alterar o tratamento dos tipos existentes.

Arquivos de referência: `lib/src/routing/i_modular_route.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Construtor seleciona rotas por tipo

- **WHEN** um módulo expõe uma lista heterogênea de `ModularRoute`
- **THEN** o construtor de rotas processa cada tipo (`ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `StatefulShellModularRoute`) pelo seu próprio caminho de conversão

### Requirement: ChildRoute mapeia para GoRoute folha

O sistema SHALL converter cada `ChildRoute` em um `GoRoute` que renderiza um widget. O `ChildRoute` MUST aceitar `path`, `child` (builder de widget), `name` opcional, `pageBuilder` opcional, `parentNavigatorKey`, `redirect`, `onExit`, `transition` e `transitionDuration`. Um `ChildRoute` cujo path normaliza para `/` MUST NOT ser registrado como rota folha top-level — ele representa o índice do módulo.

Arquivos de referência: `lib/src/routing/child_route.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: ChildRoute simples vira GoRoute com builder

- **WHEN** um módulo declara `ChildRoute('/home', child: ...)` sem `pageBuilder` nem `transition`
- **THEN** o sistema cria um `GoRoute` cujo `builder` renderiza o widget do `ChildRoute`

#### Scenario: ChildRoute com pageBuilder usa o pageBuilder fornecido

- **WHEN** um `ChildRoute` define `pageBuilder`
- **THEN** o `GoRoute` resultante usa esse `pageBuilder` diretamente

#### Scenario: ChildRoute índice é excluído das rotas folha

- **WHEN** um módulo declara `ChildRoute('/', child: ...)`
- **THEN** ele não é emitido como rota folha separada; serve como conteúdo padrão do módulo

### Requirement: ModuleRoute monta um módulo aninhado com ciclo de vida

O sistema SHALL converter `ModuleRoute` em um `GoRoute` cujo path é o segmento do módulo e cujas rotas filhas são as rotas do módulo (construídas com `topLevel = false`). O `ModuleRoute` MUST aceitar `path`, `module` e `name` opcional, e o `GoRoute` resultante MUST acoplar o registro dos binds do módulo no `redirect` (ver capability `routing-lifecycle`).

Arquivos de referência: `lib/src/routing/module_route.dart`, `lib/src/routing/route_builder.dart`, `lib/src/core/module/module.dart`.

#### Scenario: ModuleRoute compõe path do módulo com a rota índice

- **WHEN** um `ModuleRoute('/auth', module: AuthModule)` cujo `AuthModule` tem `ChildRoute('/', ...)` é construído
- **THEN** a rota efetiva do índice do módulo é `/auth`
- **AND** uma `ChildRoute('/login')` do mesmo módulo resolve para `/auth/login`

### Requirement: ShellModularRoute mapeia para ShellRoute com layout compartilhado

O sistema SHALL converter `ShellModularRoute` em um `ShellRoute` cujo `builder` envolve o navigator filho com um layout comum. O `ShellModularRoute` MUST aceitar `builder` (que recebe o `child`), `routes` filhas, `redirect`, `pageBuilder`, `observers`, `navigatorKey`, `parentNavigatorKey` e `restorationScopeId`. Uma `ChildRoute` cujo path normaliza para `/` MUST NOT ser filha direta de um shell (deve ser rejeitada por asserção em desenvolvimento).

Arquivos de referência: `lib/src/routing/shell_modular_route.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Shell envolve filhas com layout comum

- **WHEN** um `ShellModularRoute` declara `builder` e rotas filhas `ChildRoute`/`ModuleRoute`
- **THEN** o `ShellRoute` resultante renderiza o `builder` com o navigator das filhas como `child`

#### Scenario: ChildRoute índice direta no shell é rejeitada em desenvolvimento

- **WHEN** um `ShellModularRoute` declara uma `ChildRoute('/')` como filha direta
- **THEN** uma asserção falha em modo de desenvolvimento indicando a configuração inválida

### Requirement: StatefulShellModularRoute mapeia para StatefulShellRoute com branches

O sistema SHALL converter `StatefulShellModularRoute` em um `StatefulShellRoute`, com uma `StatefulShellBranch` por branch declarada, preservando o estado de cada branch. O tipo MUST aceitar `branches`, `builder` (recebe a `StatefulNavigationShell`), `transition`/`transitionDuration`/`reverseTransitionDuration`, `navigatorContainerBuilder`, `redirect` e `shellKey`. Uma branch MUST poder ser declarada por rotas (`ModularBranch`) ou diretamente por um módulo (`ModuleBranch`), e os paths das branches MUST ser únicos dentro do mesmo shell.

Arquivos de referência: `lib/src/routing/stateful_shell_modular_route.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Cada branch vira uma StatefulShellBranch com rotas próprias

- **WHEN** um `StatefulShellModularRoute` declara duas branches com rotas distintas
- **THEN** o `StatefulShellRoute` resultante contém uma branch por declaração, cada uma com suas rotas construídas recursivamente

#### Scenario: ModuleBranch é atalho para uma branch com ModuleRoute

- **WHEN** uma branch é declarada como `ModuleBranch('/home', module: HomeModule)`
- **THEN** ela equivale a uma branch contendo `ModuleRoute('/home', module: HomeModule)`

### Requirement: Construção de rotas pelo ModularRouteBuilder

O sistema SHALL construir todas as rotas de um módulo via `ModularRouteBuilder.buildRoutes`, agregando, nesta ordem, as `ChildRoute`, as `ModuleRoute`, as `ShellModularRoute` e as `StatefulShellModularRoute` do módulo. O builder MUST ser o único ponto que traduz tipos modulares em `RouteBase` do `go_router`.

Arquivos de referência: `lib/src/routing/route_builder.dart`, `lib/src/core/module/module.dart`.

#### Scenario: buildRoutes agrega todos os tipos de rota do módulo

- **WHEN** um módulo declara rotas de tipos variados e `buildRoutes` é chamado
- **THEN** o resultado é uma lista de `RouteBase` contendo a conversão de cada tipo de rota declarado

### Requirement: Normalização de paths entre top-level e aninhado

O sistema SHALL normalizar os paths das rotas de forma consistente: no nível top-level o path mantém a barra inicial; em rotas aninhadas a barra inicial é removida (exceto para parâmetros iniciados por `/:`). Barras duplicadas MUST ser compactadas e a barra final removida, exceto para a raiz `/`.

Arquivos de referência: `lib/src/routing/route_builder.dart`.

#### Scenario: Path aninhado perde a barra inicial

- **WHEN** uma rota aninhada declara o path `/home`
- **THEN** o path normalizado usado no `GoRoute` filho é `home`

#### Scenario: Path top-level mantém a barra inicial

- **WHEN** uma rota top-level declara o path `/home`
- **THEN** o path normalizado permanece `/home`

#### Scenario: Barras duplicadas são compactadas

- **WHEN** a composição de paths gera `//home///sub`
- **THEN** o path normalizado compacta as barras repetidas em uma única
