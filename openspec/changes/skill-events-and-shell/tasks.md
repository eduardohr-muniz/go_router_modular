## 1. Skill principal: seção de Shell

- [ ] 1.1 Invocar a skill `skill-creator` para conduzir as edições e os evals.
- [ ] 1.2 Confirmar no código os fatos de shell: `ShellModularRoute({required builder, required routes})`, `StatefulShellModularRoute({required branches, ...})`, `ModularBranch`/`ModuleBranch`, `StatefulShellBranchTransitions` (exportados pelo barril).
- [ ] 1.3 Em `skills/go-router-modular/SKILL.md`, adicionar a seção "Shell routes (casos específicos)": guiada por intenção (abas com estado → `StatefulShellModularRoute`; chrome persistente → `ShellModularRoute`; senão, rotas/módulos comuns), com um exemplo mínimo de cada e a regra de altitude ("shell não é o padrão").
- [ ] 1.4 Ampliar a `description` do frontmatter da skill principal para disparar em bottom-nav/abas/shell (sem incluir eventos).
- [ ] 1.5 Referenciar `nextra_docs/content/en/routes/shell-route.mdx` como detalhe, sem duplicar.

## 2. Skill separada de eventos

- [ ] 2.1 Confirmar no código os fatos de eventos: `EventModule` (`listen()`, `on<T>((event, context){...}, {autoDispose, exclusive})`, composição `OutroEventModule().listen()`), `ModularEvent.fire<T>`/`ModularEvent.instance.on<T>`, `ModularEventMixin` — todos exportados pelo barril.
- [ ] 2.2 Criar `skills/go-router-modular-events/SKILL.md` com frontmatter (`name: go-router-modular-events`, `description` disparando em eventos/comunicação entre módulos) que assume as convenções da skill principal (referencia, não duplica).
- [ ] 2.3 Documentar os três caminhos com peso semelhante e "quando usar cada um": `EventModule.listen()` + `on<T>`; `ModularEvent.fire`/`on`; `ModularEventMixin`. Incluir composição via `OutroEventModule().listen()` e `autoDispose`/`exclusive`.
- [ ] 2.4 Boas práticas: eventos como classes pequenas/imutáveis; emitir com `ModularEvent.fire`; preferir o ouvinte de menor escopo; tratar `context` possivelmente nulo. Referenciar `event-module/*` da doc.
- [ ] 2.5 Criar o symlink local gitignored `.claude/skills/go-router-modular-events → ../../skills/go-router-modular-events` e adicioná-lo ao `.gitignore` (como a skill principal).

## 3. README

- [ ] 3.1 Adicionar ao README o comando de instalação da skill de eventos (`npx skills add https://github.com/eduardohr-muniz/go_router_modular --skill go-router-modular-events`), deixando claro que é opcional/separada.

## 4. Evals (skill-creator)

- [ ] 4.1 Skill principal: adicionar um eval de **bottom-nav** com asserção de uso de `StatefulShellModularRoute` (não `go_router` cru / `Navigator` manual).
- [ ] 4.2 Skill de eventos: criar `skills/go-router-modular-events/evals/` com um eval de **comunicação entre módulos**, asserção de uso de `EventModule`/`ModularEvent`/`ModularEventMixin`.
- [ ] 4.3 Rodar as execuções com baseline limpo (worktree sem as skills), gradear e revisar o delta.
- [ ] 4.4 Ajustar `SKILL.md`/`description` conforme os resultados.

## 5. Verificação

- [ ] 5.1 Validar frontmatter das duas skills (YAML; `name` + `description`).
- [ ] 5.2 Conferir que os exemplos usam apenas símbolos da superfície pública (`ShellModularRoute`, `StatefulShellModularRoute`, `ModularBranch`/`ModuleBranch`, `EventModule`, `ModularEvent`, `ModularEventMixin`).
- [ ] 5.3 Conferir que `skills/` publica as duas skills (`go-router-modular` e `go-router-modular-events`) e que nada de openspec/symlink vaza; nenhuma mudança em `lib/`.
