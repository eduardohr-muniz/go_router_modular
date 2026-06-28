## Context

A skill `go-router-modular` (fonte única em `skills/go-router-modular/SKILL.md`, com symlink local gitignored em `.claude/skills/`) cobre estrutura de projeto, rotas, módulos, DI e navegação nomeada. Duas áreas ficam de fora:

- **Shell** (`lib/src/routing/`): `ShellModularRoute({required builder, required routes, ...})` para chrome persistente; `StatefulShellModularRoute({required branches, builder, transition, ...})` com `ModularBranch`/`ModuleBranch` e `StatefulShellBranchTransitions` para bottom-nav/abas com estado por branch. É roteamento → cabe na skill principal.
- **Eventos** (`lib/src/events/`): `EventModule` (`listen()` + `on<T>((event, context) {...}, {autoDispose, exclusive})` e composição via `OutroEventModule().listen()`), `ModularEvent.fire<T>` / `ModularEvent.instance.on<T>`, e `ModularEventMixin<T extends StatefulWidget>` (auto-dispose). Exportados pelo barril. É **opcional** → vira skill separada.

Restrições: pt-BR nos artefatos; skills são tooling (não mudam `lib/`); referenciar doc Nextra (`event-module/*`, `routes/shell-route.mdx`) e specs `events-*`/`routing-*` em vez de duplicar; manter o estilo da skill (regras com "porquê", exemplos canônicos, checklist); usar `skill-creator` para evals; publicar skills em `skills/` (instaláveis por `npx skills add`).

## Goals / Non-Goals

**Goals:**
- Adicionar guia de shell (caso específico) à skill principal.
- Criar uma skill de eventos **separada e opcional**, instalável à parte.
- Validar ambas com evals (bottom-nav; comunicação por eventos).

**Non-Goals:**
- Mudar API/runtime do pacote.
- Tornar shell padrão ou embutir eventos na skill principal.
- Duplicar documentação de eventos/shell.

## Decisions

### Decisão 1: Eventos como skill separada (`go-router-modular-events`)
Nem todo app usa eventos; embuti-los na skill principal pesaria para a maioria. Uma skill própria em `skills/go-router-modular-events/` é instalável sob demanda (`npx skills add … --skill go-router-modular-events`) e referencia a principal para as convenções base, sem duplicar.
- **Alternativa rejeitada**: uma seção de eventos dentro da skill principal — descartada pelo pedido do autor (opcional, nem todos usarão).

### Decisão 2: Shell permanece na skill principal
Shell é roteamento, área já coberta pela skill principal. Entra como seção de **caso específico**, guiada por intenção (abas com estado → `StatefulShellModularRoute`; moldura persistente → `ShellModularRoute`; senão, rotas/módulos comuns), com regra de altitude explícita.

### Decisão 3: Cobrir os três caminhos de eventos com peso semelhante
Na skill de eventos, apresentar `EventModule`, `ModularEvent` e `ModularEventMixin` lado a lado com um "quando usar cada um" (módulo vivo ↔ `EventModule`; emitir/ouvir avulso ↔ `ModularEvent`; estado de widget ↔ `ModularEventMixin`).

### Decisão 4: Mesma mecânica de publicação das duas skills
Ambas vivem em `skills/<name>/` (publicadas, instaláveis), com symlink local gitignored em `.claude/skills/<name>` para uso no próprio repo — espelhando o que já foi feito com a principal. O README ganha o comando da skill de eventos ao lado da principal.

### Decisão 5: Eventos como classes pequenas/imutáveis; `context` nulo
Padronizar `class XEvent { const XEvent(this.payload); ... }` e lembrar que o `BuildContext` do callback pode ser nulo (web/refresh), conforme a API.

### Decisão 6: Evals via skill-creator, baseline limpo
Skill principal: eval de bottom-nav (espera `StatefulShellModularRoute`). Skill de eventos: eval de comunicação entre dois módulos (espera `EventModule`/`ModularEvent`/`ModularEventMixin`). Baseline em worktree sem as skills, como na iteração anterior, para medir ganho real.

## Risks / Trade-offs

- **[Duas skills divergirem]** → A de eventos referencia a principal e usa só símbolos do barril; manter o mesmo tom/estilo.
- **[Agente usar shell por padrão]** → Reforçar a regra de altitude e cobrir com eval (caso simples não deve gerar shell).
- **[Usuário não saber que eventos é skill à parte]** → README deixa explícito os dois comandos de instalação.

## Migration Plan

1. Adicionar a seção "Shell routes (casos específicos)" à skill principal + ampliar `description`.
2. Criar `skills/go-router-modular-events/SKILL.md` (frontmatter próprio + os três caminhos + boas práticas), referenciando a principal.
3. Symlink local gitignored em `.claude/skills/go-router-modular-events`; atualizar README com o comando de instalação.
4. Acrescentar evals (bottom-nav na principal; eventos na de eventos); rodar com baseline limpo; ajustar.
5. **Rollback**: remover `skills/go-router-modular-events/`, a seção de shell e o trecho do README — sem efeito no pacote.

## Open Questions

- Nenhuma bloqueante. Profundidade do exemplo de `StatefulShellBranchTransitions` (mencionar vs exemplificar) pode ser ajustada no apply.
