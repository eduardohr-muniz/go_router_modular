## Context

Após B e C, as responsabilidades estão desacopladas, mas a estrutura de pastas ainda mistura subsistemas. O motor de DI está em 4 diretórios (`core/bind/` 6 arquivos, `core/manager/` 3, `core/dependency_analyzer/` 1, `di/` 3) e `core/` agrega DI + módulo + config + telemetria sem coesão. Esta mudança reorganiza `lib/src/` por subsistema, sem alterar comportamento.

Mapa de movimentação (origem → destino):

```
core/bind/*                                   → di/
core/manager/*                                → di/
core/dependency_analyzer/dependency_analyzer.dart → di/dependency_analyzer.dart
di/*                                          → di/ (permanece)
core/module/module.dart                       → module/module.dart
routing/*                                     → routing/ (permanece)
core/config/modular_router_runtime.dart       → routing/modular_router_runtime.dart
core/config/modular_router_params.dart        → routing/modular_router_params.dart
core/config/route_with_completer_service.dart → routing/route_with_completer_service.dart
core/config/go_router_modular_configure.dart  → bootstrap/go_router_modular_configure.dart
internal/setup.dart                           → shared/setup.dart  (corrigido na implementação: setup é consumido pelo DI; em bootstrap criaria di → bootstrap)
widgets/*                                      → ui/
extensions/*                                   → ui/
exceptions/exception.dart                     → shared/exception.dart
internal/asserts/*                            → shared/asserts/
internal/internal_logs.dart                   → shared/internal_logs.dart
testing/*                                      → testing/ (permanece)
```

Restrições: pt-BR; sem mudança de comportamento; superfície pública preservada; sem abreviações.

## Goals / Non-Goals

**Goals:**

- Reorganizar `lib/src/` em `di/`, `module/`, `routing/`, `bootstrap/`, `events/`, `ui/`, `shared/`, `testing/`, eliminando `core/`.
- Consolidar todo o motor de DI em `di/`.
- Preservar comportamento, símbolos públicos e guardas (B e C) atualizadas para os novos caminhos.

**Non-Goals:**

- Não mudar lógica nem assinaturas.
- Não criar barris internos por subsistema (foco é pasta).
- Não extrair o micropackage de DI.

## Decisions

### Decisão 1: `git mv` + reescrita mecânica de imports

Mover com `git mv` (preserva histórico) e reescrever os `import`/`export` por mapeamento de prefixo de caminho. A maioria dos imports internos já usa o caminho absoluto `package:go_router_modular/src/<área>/...` (decisão do passo C), então a reescrita é um mapa de prefixos:

```
src/core/bind/                → src/di/
src/core/manager/             → src/di/
src/core/dependency_analyzer/dependency_analyzer.dart → src/di/dependency_analyzer.dart
src/core/module/              → src/module/
src/core/config/go_router_modular_configure.dart → src/bootstrap/go_router_modular_configure.dart
src/core/config/modular_router_runtime.dart      → src/routing/modular_router_runtime.dart
src/core/config/modular_router_params.dart       → src/routing/modular_router_params.dart
src/core/config/route_with_completer_service.dart → src/routing/route_with_completer_service.dart
src/internal/setup.dart       → src/bootstrap/setup.dart
src/widgets/                  → src/ui/
src/extensions/               → src/ui/
src/exceptions/               → src/shared/
src/internal/asserts/         → src/shared/asserts/
src/internal/internal_logs.dart → src/shared/internal_logs.dart
```

- **Por quê:** mecânico, auditável e reversível; o passo C já padronizou os imports absolutos, reduzindo casos especiais.
- **Cuidado:** `core/config/` tem destino dividido (bootstrap vs routing) — o mapa trata por arquivo, não só por prefixo de pasta. Ordenar as regras de reescrita do caminho mais específico para o mais genérico evita reescrita incorreta.

### Decisão 2: Converter imports relativos remanescentes para absolutos

Os poucos imports relativos (`../../...`, ex.: em `module.dart`) são convertidos para `package:go_router_modular/src/...` durante o move.

- **Por quê:** imports relativos quebram ao mover pastas; absolutos são estáveis e consistentes com o restante (Clean Code: um estilo só).

### Decisão 3: Atualizar as guardas dos passos B e C para os novos caminhos

A guarda de ciclos (`package_layering_test.dart`) referencia caminhos fixos (`core/module/module.dart`, `core/config/go_router_modular_configure.dart`) que mudam. Atualizá-los para `module/module.dart` e `bootstrap/go_router_modular_configure.dart`. A guarda de import de barril varre `lib/src/` e independe da estrutura — segue válida.

- **Por quê:** as guardas são o contrato executável das fronteiras; precisam acompanhar os caminhos.

### Decisão 4: Fases por subsistema com `flutter analyze` entre elas

Mover um subsistema por vez, reescrevendo imports e rodando `flutter analyze` antes de seguir. Reduz a janela de erro e isola eventuais colisões.

- **Por quê:** muita movimentação; verificação incremental é mais segura que um big-bang único.

## Risks / Trade-offs

- **[Reescrita de import incorreta por prefixo ambíguo]** (`core/config/` divide destino) → Regras ordenadas do mais específico ao mais genérico; `flutter analyze` após cada fase captura referências quebradas.
- **[Colisão de nomes de arquivo ao consolidar DI]** → Verificada: `core/bind/*`, `core/manager/*`, `core/dependency_analyzer/*` e `di/*` têm nomes distintos; sem colisão.
- **[Quebra de consumidores externos por caminho `src/`]** → Consumidores externos usam o barril público, não caminhos `src/` diretos; a superfície de símbolos é preservada. Imports diretos de `src/` por terceiros não são suportados.
- **[Histórico de git perdido nos moves]** → `git mv` preserva; evitar deletar+criar.
- **[Guardas desatualizadas passarem falsamente]** → Atualizar caminhos e validar que a guarda de ciclos ainda falha ao reintroduzir um ciclo (teste do teste) após o ajuste de caminhos.

## Migration Plan

1. Linha de base verde + captura de símbolos exportados.
2. Fase DI: mover `core/bind`, `core/manager`, `core/dependency_analyzer` → `di/`; reescrever imports; `analyze`.
3. Fase module: `core/module/module.dart` → `module/`; `analyze`.
4. Fase routing-runtime: `core/config/modular_router_*` + `route_with_completer_service.dart` → `routing/`; `analyze`.
5. Fase bootstrap: `core/config/go_router_modular_configure.dart` + `internal/setup.dart` → `bootstrap/`; `analyze`.
6. Fase ui: `widgets/` + `extensions/` → `ui/`; `analyze`.
7. Fase shared: `exceptions/`, `internal/asserts/`, `internal/internal_logs.dart` → `shared/`; `analyze`.
8. Atualizar barris (`lib/go_router_modular.dart`, `lib/testing.dart`).
9. Atualizar guardas (caminhos) e validar teste-do-teste.
10. Verificação final: `analyze` + suíte + paridade de símbolos.
11. Rollback: `git` reverte os moves por fase.

## Open Questions

- `bootstrap/` é o melhor nome para o composition root, ou `app/`/`config/` comunicam melhor? (Recomendação: `bootstrap/`.)
- `ui/` deve subdividir em `ui/widgets/` e `ui/extensions/`, ou manter plano? (Recomendação: plano, poucos arquivos.)
- Vale criar barris internos por subsistema (`di.dart` etc.) nesta mudança para simplificar imports, ou deixar para um passo posterior? (Recomendação: posterior, manter foco em pastas.)
