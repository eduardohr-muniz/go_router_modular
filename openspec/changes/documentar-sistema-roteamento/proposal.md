## Why

O roteamento do `go_router_modular` é uma camada modular sobre o `go_router` que entrelaça navegação e ciclo de vida da injeção de dependências: ao entrar numa rota de módulo os binds são registrados, ao sair são descartados. Esse acoplamento intencional, somado a tipos de rota polimórficos (`ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `StatefulShellModularRoute`), normalização de paths, transições de página e widgets observadores de ciclo de vida (`ParentWidgetObserver`, `OnceBuilder`, `ModularLoader`), torna o comportamento difícil de entender e fácil de quebrar sem documentação. Esta mudança documenta o roteamento atual como especificação executável e auditável, sem alterar comportamento. Complementa a spec de DI existente (`documentar-sistema-di`).

## What Changes

- Documentar os tipos de rota modular e seu mapeamento para o `go_router`: `ChildRoute` → `GoRoute`, `ModuleRoute` → `GoRoute` aninhado com redirect, `ShellModularRoute` → `ShellRoute`, `StatefulShellModularRoute` → `StatefulShellRoute`/`indexedStack` com branches.
- Documentar a conversão de rotas pelo `ModularRouteBuilder` (`buildRoutes`) e a montagem/normalização de paths (top-level vs. aninhado, segmento índice `/`, parâmetros).
- Documentar a ligação roteamento↔ciclo de vida do DI: registro de binds no `redirect` ao entrar na rota e descarte via `ParentWidgetObserver` ao sair, incluindo a proteção contra descarte prematuro em transições rápidas (`onDidChangeGoingReference`) e o descarte em cascata de branches de shells stateful.
- Documentar transições de página: transição por rota, transição padrão global (`Modular.getDefaultTransition` / `GoTransition.defaultDuration`), animação entre branches do shell stateful e o `ModularLoader` durante o registro de binds.
- Documentar a configuração global via `configure`: montagem do `GoRouter` (rotas top-level, `initialLocation`, `redirect`, `errorBuilder`, `navigatorKey`, observers), o snapshot imutável de parâmetros e `copyWith`/`copyRouterConfig`.
- Documentar as extensions de `BuildContext`: navegação assíncrona com completers (`goAsync`, `pushAsync`, etc.), utilitários (`popUntil`, leitura de parâmetros/estado) e o açúcar de DI (`context.read<T>()`).
- Documentar os widgets de suporte: `OnceBuilder` (evita reinstanciar factory no rebuild), `ParentWidgetObserver` (dispara o descarte do módulo) e `ModularApp.router` (injeta o router e o overlay do loader).
- Mapear onde os princípios SOLID aparecem (polimorfismo de rotas, inversão por callbacks) e onde são fracos (acoplamento a `go_transitions`, estado global mutável).
- **Sem mudança de comportamento**: nenhuma API é alterada, adicionada ou removida. Mudança puramente documental.

## Capabilities

### New Capabilities
- `routing-routes`: Tipos de rota modular e sua conversão para o `go_router` — `ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `StatefulShellModularRoute` e branches, a construção pelo `ModularRouteBuilder` e a normalização de paths.
- `routing-lifecycle`: Ligação entre navegação e ciclo de vida do DI — registro de binds no redirect ao entrar, descarte ao sair via `ParentWidgetObserver`, proteção contra descarte prematuro em transição, descarte em cascata de branches e o `ModularLoader` durante o registro.
- `routing-configuration`: Configuração global do router — `configure`, montagem do `GoRouter`, snapshot imutável de parâmetros com `copyWith`/`copyRouterConfig`, transições padrão e `ModularApp.router`.
- `routing-navigation`: Navegação ergonômica sobre o `go_router` — extensions de `BuildContext` com navegação assíncrona via completers, utilitários de pop e leitura de estado/parâmetros, e açúcar de DI por contexto.

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — esta mudança é puramente documental e não altera as specs de DI já propostas. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` é modificado.
- **Artefatos OpenSpec**: novos arquivos de spec em `openspec/specs/routing-routes/`, `openspec/specs/routing-lifecycle/`, `openspec/specs/routing-configuration/` e `openspec/specs/routing-navigation/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `lib/src/routing/*` (`i_modular_route.dart`, `child_route.dart`, `module_route.dart`, `shell_modular_route.dart`, `stateful_shell_modular_route.dart`, `stateful_shell_branch_transitions.dart`, `route_builder.dart`, `route_model.dart`), `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/core/module/module.dart`, `lib/src/widgets/*` (`material_app_router.dart`, `modular_loader.dart`, `parent_widget_observer.dart`, `once_builder.dart`), `lib/src/extensions/*`.
- **Relação com DI**: referencia, mas não duplica, a spec `documentar-sistema-di`; o registro/descarte de binds é descrito do ponto de vista do roteamento (quando e onde é disparado).
- **Riscos**: baixos — risco principal é divergência entre a spec e o código se o comportamento evoluir sem atualizar a spec.

## Não-objetivos

- Não alterar, refatorar ou corrigir qualquer comportamento do roteamento ou das transições.
- Não remover os pontos fracos de SOLID identificados (acoplamento a `go_transitions`, mutação de `GoTransition.defaultDuration` global, muitos campos em `StatefulShellModularRoute`). Eles são apenas registrados como contexto para decisões futuras.
- Não redocumentar o container de DI em si (tipos de bind, resolução, proteções) — isso é escopo da spec `documentar-sistema-di`; aqui descreve-se apenas o gatilho de registro/descarte a partir da navegação.
- Não documentar o sistema de eventos (`event_module`, `modular_event`) — fora do escopo de roteamento.
- Não criar API nova de navegação nem alterar assinaturas existentes.
