## Why

A Agent Skill `go-router-modular` cobre roteamento, módulos, DI e navegação nomeada — mas ignora dois recursos poderosos do pacote. As **rotas de shell** (`ShellModularRoute`, `StatefulShellModularRoute`) são roteamento e cabem na skill principal como caso específico. Já o **sistema de eventos** (`EventModule`, `ModularEvent`, `ModularEventMixin`) é opcional: nem todo app usa comunicação por eventos, então embuti-lo na skill principal sobrecarrega quem nunca vai usá-lo. Separar os eventos em uma **skill própria, instalável à parte**, mantém a principal enxuta e dá a quem precisa um guia dedicado.

## What Changes

- **Skill principal `go-router-modular` ganha uma seção "Shell routes (casos específicos)"**:
  - `StatefulShellModularRoute` (+ `ModularBranch`/`ModuleBranch`, `StatefulShellBranchTransitions`) — para **bottom navigation / abas** com pilha e estado preservados por branch.
  - `ShellModularRoute` — para **chrome persistente** (app bar, nav rail, layout) ao redor de rotas filhas.
  - Regra de altitude: shell é **caso específico** — não usar por padrão.
  - `description` ampliada para disparar também em bottom-nav/abas/shell.
- **Nova skill separada `go-router-modular-events`** em `skills/go-router-modular-events/SKILL.md`, instalável à parte (`npx skills add … --skill go-router-modular-events`), cobrindo os três caminhos do subsistema de eventos com peso parecido:
  - `EventModule` — `listen()` + `on<T>((event, context) {...})` (cancelado no `dispose`), composição via `OutroEventModule().listen()`, `autoDispose`/`exclusive`.
  - `ModularEvent` — `ModularEvent.fire<T>(event)` para emitir e `ModularEvent.instance.on<T>(...)` para ouvir imperativamente.
  - `ModularEventMixin` — `on<E>(...)` em um `State<StatefulWidget>` com auto-dispose.
  - Boas práticas: eventos como classes pequenas e imutáveis; emitir com `ModularEvent.fire`; preferir o ouvinte de menor escopo; tratar `context` possivelmente nulo. A skill de eventos assume as convenções da `go-router-modular` (referencia, não duplica).
- **README** ganha o comando de instalação da skill de eventos, ao lado da principal.
- **Evals** (via `skill-creator`): um caso de bottom-nav para a skill principal (valida `StatefulShellModularRoute`) e um conjunto próprio de evals para a skill de eventos (valida `EventModule`/`ModularEvent`/`ModularEventMixin`).

## Capabilities

### New Capabilities
- `agent-skill-go-router-modular-events`: define os requisitos da skill **separada** de eventos — conteúdo (os três caminhos), gatilho próprio e suíte de evals — instalável de forma independente da skill principal.

### Modified Capabilities
- `agent-skill-go-router-modular`: a skill principal passa a orientar as **rotas de shell** (`StatefulShellModularRoute` para bottom-nav, `ShellModularRoute` para chrome) como caso específico, com gatilho ampliado e cobertura por eval; os eventos saem de escopo desta skill (vão para a skill separada).

## Impact

- Editado: `skills/go-router-modular/SKILL.md` (seção Shell + `description`).
- Novo: `skills/go-router-modular-events/SKILL.md` (+ `evals/`), publicado em `skills/` e instalável por `npx skills add`; symlink local em `.claude/skills/` (gitignored) para parity, como a principal.
- Editado: `README.md` (comando de instalação da skill de eventos).
- Evals: caso de bottom-nav na skill principal; evals próprios na skill de eventos.
- Doc/specs do pacote: referência apenas (`nextra_docs/content/{en,pt}/event-module/*`, `routes/shell-route.mdx`; specs `events-*`/`routing-*`); sem duplicação.
- Código do pacote (`lib/`): **sem mudança**.

## Non-goals (Não-objetivos)

- Não alterar a API nem o comportamento de eventos/shell do pacote.
- Não tornar shell o padrão — segue como recurso de caso específico.
- Não embutir eventos na skill principal — eventos são uma skill opcional separada.
- Não duplicar a documentação de eventos/shell; as skills referenciam as páginas existentes.
