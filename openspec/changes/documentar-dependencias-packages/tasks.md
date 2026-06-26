## 1. Auditoria das dependências declaradas

- [ ] 1.1 Listar todas as dependências de `dependencies` e `dev_dependencies` no `pubspec.yaml` com suas versões declaradas.
- [ ] 1.2 Para cada dependência de runtime, rodar `grep -rn "package:<nome>" lib/` e registrar os arquivos e linhas de import.
- [ ] 1.3 Registrar os símbolos consumidos de cada dependência ativa (`event_bus`, `go_router`, `go_transitions`) a partir dos pontos de uso encontrados.

## 2. Documentar dependências ativas e estruturais

- [ ] 2.1 Revisar o requisito de `event_bus` em `specs/package-dependencies/spec.md` confirmando os símbolos (`EventBus`, `on<T>`, `fire`, `asBroadcastStream`) e os arquivos de `lib/src/events/` e `lib/src/testing/`.
- [ ] 2.2 Revisar o requisito de `go_router` confirmando os símbolos (`GoRouter`, `GoRoute`, `ShellRoute`, `StatefulShellRoute`, `StatefulShellBranch`, `StatefulNavigationShell`, `GoRouterState`, `RouteBase`, `NavigatorObserver`) e os arquivos de `lib/src/routing/`, `lib/src/core/config/` e `lib/src/extensions/`.
- [ ] 2.3 Revisar o requisito de `go_transitions` confirmando os símbolos (`GoTransition`, `defaultDuration`, `defaultReverseDuration`, presets `GoTransitions.*`, `build`/`copyWith`) e a configuração da transição padrão via `configure`.

## 3. Documentar framework, ferramentas e dependências órfãs

- [ ] 3.1 Revisar o requisito de `flutter`/`flutter_test`/`flutter_lints` confirmando a declaração no `pubspec.yaml` e a referência a `analysis_options.yaml`.
- [ ] 3.2 Confirmar, por `grep -rn "package:web\|package:flutter_web_plugins" lib/`, que `web` e `flutter_web_plugins` não têm nenhum import em `lib/`.
- [ ] 3.3 Confirmar no histórico Git a origem das dependências órfãs (introdução em `2dec3f5`, remoção do recurso em `d6626c6`) e registrar como candidatas a remoção.

## 4. Verificação de cenários (testes de documentação)

- [ ] 4.1 Para cada requisito, conferir que cada cenário é verificável por inspeção objetiva (presença no `pubspec.yaml`, import/símbolo no arquivo nomeado, ausência de import para as órfãs).
- [ ] 4.2 Garantir um teste de regressão de documentação cobrindo o estado órfão: um teste/checagem que falha se `web` ou `flutter_web_plugins` passarem a ser importados ou forem removidos sem atualizar a spec.
- [ ] 4.3 Garantir uma checagem que confirme os imports esperados de `event_bus`, `go_router` e `go_transitions` ainda existem nos arquivos de referência (detecta divergência spec ↔ código).

## 5. Validação final

- [ ] 5.1 Verificar que nenhum arquivo em `lib/` e que o `pubspec.yaml` não foram alterados (mudança puramente documental).
- [ ] 5.2 Rodar `flutter analyze` e garantir ausência de avisos novos.
- [ ] 5.3 Rodar `flutter test --coverage` e confirmar que a suíte permanece verde.
- [ ] 5.4 Conferir consistência final entre cada requisito da spec e o `pubspec.yaml`/imports de `lib/`; registrar eventuais divergências como tarefas adicionais.
