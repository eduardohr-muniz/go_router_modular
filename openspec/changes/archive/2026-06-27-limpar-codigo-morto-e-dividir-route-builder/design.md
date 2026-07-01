## Context

Code review pós-C/B/A, com dois agentes de investigação (caça a código morto + análise de arquivos grandes). Achados verificados por grep (céticos):

**Código morto confirmado:**
- `lib/src/shared/internal_logs.dart` (`iLog`, `kInternalLogs`) — apenas auto-referências; não exportado. Deleção segura.
- `lib/src/routing/route_model.dart` (`RouteModularModel`) — 0 usos em lib/test/example; porém **exportado** (barril:15). Remoção é breaking de API (decisão do usuário: remover).
- `lib/src/di/dependency_analyzer.dart` (`DependencyAnalyzer`) — tem teste dedicado (`test/dependency_analyzer_test.dart`), mas a resolução de binds em produção (`BindLocator`) nunca o invoca; só `clearAll()` é chamado por utilitário de teste. Telemetria não conectada (decisão: remover). Toca `modular_test_scope.dart` e ~5 testes que chamam `DependencyAnalyzer.clearAll()`.
- Triviais não lidos (`SetupModular.debugLogGoRouter` getter, `_TypeHistory.successRate`): o segundo sai junto com o analyzer; o primeiro fica fora de escopo (plumbing de configure usado por testes).

**Arquivos grandes (SRP) — escopo desta mudança: os 2 maiores ofensores:**
- `route_builder.dart` (576 linhas) — 8 responsabilidades; `_createModule` com 132 linhas; duplicação 3–4× de redirect+binds e de `ParentWidgetObserver`.
- `route_extension.dart` (360 linhas) — mesmo boilerplate de completer repetido em 8 métodos async.

Fora de escopo (roadmap): `injection_manager.dart`, `stateful_shell_branch_transitions.dart`, `go_router_modular_configure.dart` (façade).

Restrições: pt-BR; comportamento preservado (salvo remoção de `RouteModularModel`); sem abreviações.

## Goals / Non-Goals

**Goals:**

- Remover os 3 componentes mortos e suas referências/testes.
- Decompor `route_builder.dart` em componentes coesos, mantendo `ModularRouteBuilder` como orquestrador e o comportamento idêntico.
- Eliminar a duplicação de navegação async em `route_extension.dart` via um helper.
- Preservar a superfície pública (exceto `RouteModularModel`).

**Non-Goals:**

- Não dividir os outros 3 arquivos grandes (roadmap).
- Não mudar comportamento de roteamento/navegação/DI/eventos.
- Não manter compatibilidade de `RouteModularModel`.

## Decisions

### Decisão 1: Componentes extraídos do route_builder

```
lib/src/routing/
  route_builder.dart                  ← orquestrador enxuto (~120 linhas)
  builders/
    child_route_builder.dart          ← ChildRoute → GoRoute
    module_route_builder.dart         ← ModuleRoute → GoRoute (detecta shell/stateful/regular)
    shell_route_builder.dart          ← ShellModularRoute + StatefulShellModularRoute
  transitions/
    transition_resolver.dart          ← resolve/aplica transição (+ GoTransition.defaultDuration)
  path/
    route_path_normalizer.dart        ← normalização pura de path (funções estáticas)
  redirect/
    route_redirect_binds.dart         ← helper de redirect com injeção de binds + criação de ParentWidgetObserver
```

- **Por quê:** cada tipo de rota e cada concern transversal (path, transição, redirect/observer) ganha um lar testável; o orquestrador só decide e delega (Single Responsibility + Open/Closed). Os builders são **internos** (não exportados).
- **Compartilhamento de estado:** os builders precisam do `module` (parent) e de callbacks de dispose/transition. Passar via construtor (injeção), não estado global. O orquestrador instancia e injeta.
- **Alternativa considerada:** split completo em 8 classes (recomendação do agente) — reduzida para ~6 para equilibrar coesão e custo; o helper de redirect+observer já mata a maior duplicação.

### Decisão 2: AsyncNavigationHelper para a navegação assíncrona

Um helper centraliza: `RouteWithCompleterService.setCompleteRoute` → operação de navegação (closure) → `getLastCompleteRoute().future.then(onComplete)`. Cada método async vira ~3 linhas delegando, variando só a operação de navegação.

- **Por quê:** elimina repetição 8× (DRY); novas variantes futuras herdam o padrão sem copiar boilerplate. Risco baixo (mudança estrutural, API das extensions inalterada).

### Decisão 3: Remoção de DependencyAnalyzer toca testes

Remover o analyzer exige: deletar `dependency_analyzer.dart` + `dependency_analyzer_test.dart`; remover `DependencyAnalyzer.clearAll()` de `modular_test_scope.dart` e dos ~5 testes que a chamam diretamente. `flutter analyze` + suíte garantem que nada ficou pendente.

- **Por quê:** o analyzer é telemetria sem consumidor em produção; mantê-lo só por ter teste é manter peso morto. O usuário optou por remover.

### Decisão 4: Verificação de comportamento por suíte + paridade de símbolos

Comportamento preservado é verificado por `flutter analyze` + a suíte completa. A paridade de símbolos públicos é comparada com a baseline **descontando `RouteModularModel`** (única remoção intencional).

## Risks / Trade-offs

- **[Split de route_builder altera lógica central de rotas]** → Fases pequenas (path normalizer puro → helper redirect/observer → builders por tipo → transition resolver → orquestrador), `flutter analyze` + suíte após cada fase. A suíte de roteamento é densa e cobre os cenários.
- **[Remoção de RouteModularModel quebra consumidor externo]** → Intencional; é vestigial. Documentar na nota de versão (breaking). Improvável haver consumidor.
- **[Remoção de DependencyAnalyzer deixar referência pendente em teste]** → Mapear todas as chamadas antes; `flutter analyze` pega qualquer sobra.
- **[Builders com dependência circular acidental]** → Builders dependem de tipos de rota (routing) e do orquestrador injeta callbacks; manter direção orquestrador → builders. A guarda de ciclos (passo B) protege.

## Migration Plan

1. Linha de base verde + captura de símbolos exportados.
2. Remover `internal_logs.dart`.
3. Remover `RouteModularModel` (+ export do barril).
4. Remover `DependencyAnalyzer` (+ teste + `clearAll` em modular_test_scope e nos testes).
5. `route_extension.dart`: extrair `AsyncNavigationHelper`, reescrever as 8 variantes.
6. `route_builder.dart`: extrair em fases (path normalizer → redirect/observer helper → child/module/shell builders → transition resolver → orquestrador).
7. Verificação final: `analyze` + suíte + paridade de símbolos (descontando `RouteModularModel`).
8. Rollback por fase via git.

## Open Questions

- Manter o `SetupModular.debugLogGoRouter` (escrito por `configure`, lido por nada em produção, mas usado como parâmetro em testes) ou remover o plumbing inteiro? (Recomendação: manter por ora — fora do escopo, baixo valor.)
- Os builders devem virar `part of` do route_builder (uma biblioteca) ou arquivos independentes com imports? (Recomendação: arquivos independentes internos, consistente com o resto do pacote.)
- Roadmap futuro (propostas separadas): dividir `injection_manager` (collector/mapper/validator/diagnostics), `stateful_shell_branch_transitions` (animation state/controller/UI builder) e o façade `go_router_modular_configure` (configuration/derived-router/DI/navigation pass-throughs).
