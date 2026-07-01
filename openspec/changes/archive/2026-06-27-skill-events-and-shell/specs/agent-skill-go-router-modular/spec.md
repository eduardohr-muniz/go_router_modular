## ADDED Requirements

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
