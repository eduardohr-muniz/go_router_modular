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

### Requirement: Skill de eventos cobre emissão e os dois caminhos de escuta auto-dispostos

A skill de eventos SHALL cobrir a emissão e os dois caminhos de escuta com **disposal automático**, deixando o agente escolher pelo contexto: emitir com `ModularEvent.fire<T>(event)` (estático); e ouvir por (a) `EventModule` com `listen()` registrando `on<T>((event, context) {...})` no nível de módulo (cancelado no `dispose`), incluindo composição via `OutroEventModule().listen()` dentro do `listen()`; ou (b) `ModularEventMixin` em um `State<StatefulWidget>` (cancelado no `dispose` do widget). A skill MUST indicar que eventos são classes pequenas e imutáveis, que a emissão usa `ModularEvent.fire`, e que o `BuildContext` do callback pode ser nulo. A skill MUST NOT recomendar a escuta imperativa por `ModularEvent.instance.on<T>` (sem dono/disposal automático, propensa a memory leak); quem precisar desse caminho que investigue por conta. A skill MUST usar apenas símbolos da superfície pública (`ModularEvent`, `EventModule`, `ModularEventMixin`).

Arquivos de referência: `skills/go-router-modular-events/SKILL.md`.

#### Scenario: Emissão e os dois caminhos de escuta com exemplos

- **WHEN** a skill de eventos é lida
- **THEN** ela apresenta `ModularEvent.fire` para emitir e, para ouvir, `EventModule.listen()` + `on<T>` e `ModularEventMixin`, cada um com um exemplo coerente

#### Scenario: Não recomenda escuta imperativa propensa a leak

- **WHEN** a skill é inspecionada
- **THEN** ela não apresenta `ModularEvent.instance.on<T>` como caminho de escuta recomendado

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
