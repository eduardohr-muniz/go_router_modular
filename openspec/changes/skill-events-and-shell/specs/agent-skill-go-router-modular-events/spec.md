## ADDED Requirements

### Requirement: Skill separada de eventos versionada e instalável à parte

O sistema SHALL fornecer uma Agent Skill **separada** em `skills/go-router-modular-events/SKILL.md`, versionada no repositório e instalável independentemente da skill principal (ex.: `npx skills add <repo> --skill go-router-modular-events`). O `SKILL.md` MUST ter frontmatter YAML válido com `name: go-router-modular-events` e uma `description` que dispare em tarefas de eventos (comunicação entre módulos, emitir/ouvir eventos) com `go_router_modular`. A skill MUST assumir as convenções da skill principal `go-router-modular` referenciando-a, sem duplicar seu conteúdo.

Arquivos de referência: `skills/go-router-modular-events/SKILL.md`.

#### Scenario: Frontmatter próprio e gatilho de eventos

- **WHEN** `skills/go-router-modular-events/SKILL.md` é inspecionado
- **THEN** tem `name: go-router-modular-events` e uma `description` mencionando eventos/comunicação entre módulos com `go_router_modular`

#### Scenario: Instalável de forma independente

- **WHEN** o repositório é inspecionado sob `skills/`
- **THEN** existe `skills/go-router-modular-events/` como skill própria, separada de `skills/go-router-modular/`

### Requirement: Skill de eventos cobre os três caminhos do subsistema

A skill de eventos SHALL cobrir os três caminhos do subsistema com peso semelhante, deixando o agente escolher pelo contexto: (a) `EventModule` com `listen()` registrando `on<T>((event, context) {...})` para ouvintes no nível de módulo (cancelados no `dispose`), incluindo composição via `OutroEventModule().listen()` dentro do `listen()`; (b) `ModularEvent.fire<T>(event)` para emitir e `ModularEvent.instance.on<T>(...)` para ouvir imperativamente; e (c) `ModularEventMixin` para ouvir em um `State<StatefulWidget>` com auto-dispose. A skill MUST indicar que eventos são classes pequenas e imutáveis, que a emissão usa `ModularEvent.fire`, e que o `BuildContext` do callback pode ser nulo. A skill MUST usar apenas símbolos da superfície pública (`ModularEvent`, `EventModule`, `ModularEventMixin`).

Arquivos de referência: `skills/go-router-modular-events/SKILL.md`.

#### Scenario: Os três caminhos com exemplos

- **WHEN** a skill de eventos é lida
- **THEN** ela apresenta `EventModule.listen()` + `on<T>`, `ModularEvent.fire`/`on`, e `ModularEventMixin`, cada um com um exemplo coerente

#### Scenario: Emissão e composição documentadas

- **WHEN** a skill exemplifica disparo e composição
- **THEN** mostra `ModularEvent.fire<T>(event)` para emitir e a composição via `OutroEventModule().listen()` dentro de `listen()`

#### Scenario: Contexto possivelmente nulo é tratado

- **WHEN** a skill mostra um callback `on<T>`/`on<E>`
- **THEN** o callback recebe `(event, context)` e a skill alerta que `context` pode ser nulo

### Requirement: Evals próprios da skill de eventos

A skill de eventos SHALL ter sua própria suíte de evals em `skills/go-router-modular-events/evals/`, com ao menos um caso que verifique que a saída usa a API modular de eventos (`EventModule`/`ModularEvent`/`ModularEventMixin`) em vez de callbacks acoplados ou `Navigator`/streams manuais.

Arquivos de referência: `skills/go-router-modular-events/evals/`.

#### Scenario: Eval de comunicação por eventos

- **WHEN** a suíte de evals da skill de eventos é inspecionada
- **THEN** há um caso de comunicação entre módulos com asserção de que a saída usa `EventModule`/`ModularEvent`/`ModularEventMixin`
