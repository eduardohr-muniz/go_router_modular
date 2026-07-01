# Agent Skill go-router-modular

## Purpose

Define a Agent Skill versionada `go-router-modular` que orienta o agente no uso do pacote `go_router_modular`, fixando o padrão de feature com `feature_route.dart`, navegação exclusivamente nomeada, `name` obrigatório no `ChildRoute`, composição no `Module`/`ModuleRoute`, preferência por módulos síncronos, convenções de nomenclatura e a suíte de evals que valida gatilho e qualidade da skill.

## Requirements

### Requirement: Agent Skill versionada no repositório

O sistema SHALL fornecer uma Agent Skill em `.claude/skills/go-router-modular/SKILL.md`, versionada no repositório, com frontmatter YAML válido contendo `name` e `description`. A `description` MUST descrever que a skill orienta o uso de `go_router_modular` e listar os gatilhos (criar/editar rotas, módulos ou navegação com o pacote), de modo que o agente a acione nesses contextos. A skill MUST referenciar a documentação Nextra (`nextra_docs/content/{en,pt}/routes/*`) e as specs (`openspec/specs/routing-*`) como fonte da verdade, sem duplicar conteúdo normativo.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: Frontmatter válido com gatilho descrito

- **WHEN** o arquivo `.claude/skills/go-router-modular/SKILL.md` é inspecionado
- **THEN** ele possui frontmatter com `name: go-router-modular` e uma `description` que menciona `go_router_modular` e os contextos de uso (rotas, módulos, navegação)

#### Scenario: Skill referencia a fonte da verdade

- **WHEN** o conteúdo da skill é lido
- **THEN** ele aponta para a doc Nextra e para as specs de roteamento como referência, em vez de redefinir o comportamento normativo do pacote

### Requirement: Padrão de feature com feature_route.dart

A skill SHALL instruir o agente a criar, para cada feature, um arquivo `feature_route.dart` ao lado de `feature_module.dart`, contendo duas classes: `<Feature>RouteRelative` (somente constantes de path/nome e chaves de parâmetro) e `<Feature>Route` (navegação construída a partir de um `BuildContext` via `.of(context)`, além dos leitores estáticos de parâmetro). A classe de constantes MUST conter a constante de path relativo montado como `ChildRoute` (tipicamente `'/'`), a constante `*Module` (path de montagem do módulo no pai), a constante `*Named` (string do nome da rota), as chaves de parâmetro com prefixo `param$` (ex.: `param$id`) e os paths com parâmetro com sufixo `*$<param>` (ex.: `myDetail$id`). Os leitores de parâmetro (ex.: `getMyIdParam(GoRouterState state)`) MUST viver na classe `<Feature>Route` (não na de constantes) e extrair de `state.pathParameters`.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: Skill descreve as duas classes e as constantes

- **WHEN** a skill é lida
- **THEN** ela define `<Feature>RouteRelative` com as constantes de path/nome, `*Module`, chaves `param$` e paths `*$<param>`, e `<Feature>Route` para navegação e leitura, com um exemplo de código coerente

#### Scenario: Leitura de parâmetro via leitor na classe de navegação

- **WHEN** uma rota com parâmetro de path é exemplificada
- **THEN** a skill mostra uma chave de parâmetro (ex.: `param$id`) na classe de constantes e um leitor estático `get<...>Param(state)` na classe `<Feature>Route` lendo de `state.pathParameters`

### Requirement: Navegação exclusivamente nomeada

A skill SHALL estabelecer como regra forte que toda navegação ocorra por rota nomeada, encapsulada em `<Feature>Route` e delegando a `context.goNamed`/`context.pushNamed`. A skill MUST instruir explicitamente a NÃO usar navegação por string de path crua (ex.: `context.go('/my')`). Argumentos de navegação (`pathParameters`, `extra`) MUST ser passados pelos métodos de `<Feature>Route`.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: Regra de navegação nomeada com contraexemplo

- **WHEN** a skill é lida
- **THEN** ela mostra o padrão correto (`MyRoute.of(context).go()`) e marca como incorreto o uso de string de path crua (`context.go('/my')`)

#### Scenario: Parâmetros via método nomeado

- **WHEN** a skill exemplifica navegação com parâmetro
- **THEN** o parâmetro é passado por um método de `<Feature>Route` (ex.: `pushMyDetail(id: ...)`) que repassa `pathParameters`

### Requirement: name obrigatório no ChildRoute e composição no Module

A skill SHALL instruir que toda `ChildRoute` declare `name: <Feature>RouteRelative.<...>Named`, e que `Module.routes` referencie as constantes de path relativo de `<Feature>RouteRelative` no `path` da `ChildRoute`, usando o `*Module` para definir onde o módulo é montado no pai. A skill MUST cobrir que `ModuleRoute` também aceita `name`.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: ChildRoute com name e path por constante

- **WHEN** a skill exemplifica `Module.routes`
- **THEN** cada `ChildRoute` usa uma constante de path relativo de `<Feature>RouteRelative` no `path` e `name:` com a constante `*Named` correspondente

#### Scenario: ModuleRoute nomeado é coberto

- **WHEN** a skill trata de rotas aninhadas
- **THEN** ela menciona que `ModuleRoute` aceita `name` e como o `*Module` define o ponto de montagem no pai

### Requirement: Evitar módulos assíncronos

A skill SHALL orientar o agente a preferir `binds(Injector i)` e `imports()` síncronos, evitando ao máximo a forma assíncrona (retornar `Future`). Quando a assincronicidade for inevitável, a skill MUST instruir que isso seja justificado e mantido no menor escopo possível.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: Preferência por binds/imports síncronos

- **WHEN** a skill trata de definição de módulo
- **THEN** ela recomenda `binds`/`imports` síncronos e desaconselha módulos assíncronos, indicando justificar quando inevitável

### Requirement: Convenção de nomenclatura das classes e nomes de rota

A skill SHALL fixar a nomenclatura: a classe de constantes usa o sufixo `*RouteRelative`; a classe de navegação/leitura usa o sufixo `*Route` (construída via `.of(context)`); as chaves de parâmetro usam o prefixo `param$`; os paths com parâmetro usam o sufixo `*$<param>`; e os nomes de rota são escritos em kebab-case.

Arquivos de referência: `.claude/skills/go-router-modular/SKILL.md`.

#### Scenario: Sufixos e caixa corretos

- **WHEN** a skill define os nomes das classes e rotas
- **THEN** a classe de constantes termina em `RouteRelative`, a de navegação em `Route`, as chaves de parâmetro usam `param$` (ex.: `param$id`), e os nomes de rota estão em kebab-case (ex.: `my-feature`, `detail`)

### Requirement: Suíte de evals valida a skill

O sistema SHALL fornecer uma suíte de evals (montada com o `skill-creator`) que valide a skill em dois eixos: (a) gatilho — a skill é acionada em tarefas de rota/módulo/navegação com `go_router_modular`; e (b) qualidade — o código orientado usa navegação nomeada, `name` no `ChildRoute` e módulos síncronos. A suíte MUST conter ao menos um caso positivo de gatilho e ao menos um caso que verifique a ausência de navegação por string crua na saída orientada.

Arquivos de referência: artefatos de eval do `skill-creator`.

#### Scenario: Eval de gatilho positivo

- **WHEN** um prompt de teste pede para criar uma rota/feature com `go_router_modular`
- **THEN** o eval verifica que a skill é acionada

#### Scenario: Eval de qualidade rejeita path cru

- **WHEN** a saída orientada pela skill é avaliada
- **THEN** o eval verifica que ela usa navegação nomeada e não contém `context.go('/...')` com string de path crua

### Requirement: Skill orienta rotas de shell como caso específico

A skill principal SHALL orientar o uso de rotas de shell como **caso específico** (não padrão), distinguindo: `StatefulShellModularRoute` (com `ModularBranch`/`ModuleBranch` e, quando útil, `StatefulShellBranchTransitions`) para **bottom navigation / abas** com pilha e estado preservados por branch; e `ShellModularRoute` para **chrome persistente** (app bar, nav rail, layout) ao redor de rotas filhas. A skill MUST deixar claro que rotas/módulos comuns resolvem a maioria dos casos e que shell só entra quando há navegação por abas com estado ou um invólucro de UI persistente.

Arquivos de referência: `skills/go-router-modular/SKILL.md`.

#### Scenario: Distinção stateful vs shell

- **WHEN** a seção de shell da skill principal é lida
- **THEN** ela recomenda `StatefulShellModularRoute` para bottom-nav/abas com estado por branch e `ShellModularRoute` para chrome persistente, com um exemplo de cada

#### Scenario: Shell como caso específico (regra de altitude)

- **WHEN** a skill trata de quando usar shell
- **THEN** ela afirma que shell não é o padrão e que rotas/módulos comuns cobrem a maioria dos casos

### Requirement: Gatilho e eval de shell na skill principal

A skill principal SHALL ter sua `description` (frontmatter) ampliada para disparar também em tarefas de bottom navigation/abas/shell. A suíte de evals da skill principal MUST incluir ao menos um caso de bottom-nav verificando que a saída usa `StatefulShellModularRoute` (não `go_router` cru nem `Navigator` manual). Eventos NÃO fazem parte desta skill.

Arquivos de referência: `skills/go-router-modular/SKILL.md`, `skills/go-router-modular/evals/`.

#### Scenario: Description dispara em shell, não em eventos

- **WHEN** a `description` do frontmatter da skill principal é inspecionada
- **THEN** ela menciona bottom navigation/abas/shell como contexto de uso
- **AND** não passa a tratar o subsistema de eventos como escopo desta skill

#### Scenario: Eval de bottom-nav

- **WHEN** a suíte de evals da skill principal é inspecionada
- **THEN** há um caso de bottom-nav com asserção de que a saída usa `StatefulShellModularRoute`
