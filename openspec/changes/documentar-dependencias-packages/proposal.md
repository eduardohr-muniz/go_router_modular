## Why

O `go_router_modular` declara seis dependências de runtime no `pubspec.yaml` (`event_bus`, `go_router`, `go_transitions`, `web`, `flutter_web_plugins`, `flutter`), mas o papel de cada uma e — principalmente — quais ainda são realmente usadas no código não está documentado em lugar nenhum. Uma auditoria do `lib/` mostra que `event_bus`, `go_router` e `go_transitions` são consumidas diretamente e são pilares da arquitetura, enquanto `web` e `flutter_web_plugins` ficaram **órfãs** após a remoção do `BrowserReplaceObserver`/`web_channel.dart` (commit `d6626c6`) e hoje não têm nenhum import em `lib/`. Documentar isso como especificação executável dá aos mantenedores um mapa confiável do propósito de cada dependência e sinaliza candidatos a limpeza, evitando que dependências mortas se acumulem (Clean Code: sem código/dependência morta). Complementa as specs `documentar-sistema-di`, `documentar-sistema-roteamento` e `documentar-event-module`.

## What Changes

- Documentar `event_bus`: o que é consumido (`EventBus`, `bus.on<T>()`, `bus.fire`, `asBroadcastStream`), onde (`lib/src/events/*`, `lib/src/testing/*`) e por que é a espinha dorsal do sistema de eventos.
- Documentar `go_router`: símbolos consumidos (`GoRouter`, `GoRoute`, `ShellRoute`, `StatefulShellRoute`, `StatefulShellBranch`, `StatefulNavigationShell`, `GoRouterState`, `RouteBase`, `NavigatorObserver`), onde (`lib/src/core/config/*`, `lib/src/routing/*`, `lib/src/extensions/*`, `lib/src/core/module/module.dart`) e por que é o motor de roteamento sobre o qual o pacote adiciona a camada modular.
- Documentar `go_transitions`: símbolos consumidos (`GoTransition`, `GoTransition.defaultDuration`/`defaultReverseDuration`, presets `GoTransitions.*`, `build`/`copyWith`), onde (`lib/src/routing/*`, `lib/src/core/config/*`) e por que provê as transições de página e de branches de shell.
- Documentar `flutter`/`flutter_test`/`flutter_lints`: papel de framework e ferramentas de desenvolvimento (sem detalhar API), apenas para completude.
- Documentar o estado **órfão** de `web` e `flutter_web_plugins`: declaradas no `pubspec.yaml` mas sem nenhum import em `lib/`; foram introduzidas para `web_channel.dart`/`BrowserReplaceObserver` (commit `2dec3f5`) e ficaram sem uso após a remoção desse recurso (commit `d6626c6`). Registrar como candidatas a remoção/verificação, sem removê-las nesta mudança.
- Mapear, para cada dependência usada, o que quebraria sem ela (impacto), reforçando a relação entre a dependência e a capability correspondente do pacote.
- **Sem mudança de comportamento e sem alterar o `pubspec.yaml`**: mudança puramente documental.

## Capabilities

### New Capabilities
- `package-dependencies`: Catálogo das dependências externas do `go_router_modular` — para cada package, o que é consumido, onde é consumido no `lib/`, o papel arquitetural, o impacto de sua ausência e o estado de uso atual (ativa ou órfã).

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — esta mudança é puramente documental e não altera as specs de DI, roteamento ou eventos já propostas. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` e nenhum `pubspec.yaml` é modificado.
- **Artefatos OpenSpec**: novo arquivo de spec em `openspec/specs/package-dependencies/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `pubspec.yaml`, `lib/src/events/*`, `lib/src/testing/*`, `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/routing/*`, `lib/src/extensions/route_extension.dart`, `lib/src/core/module/module.dart`.
- **Relação com outras specs**: referencia, mas não duplica, `documentar-sistema-di`, `documentar-sistema-roteamento` e `documentar-event-module`; cada dependência usada é ligada à capability que a consome.
- **Achado acionável**: `web` e `flutter_web_plugins` são candidatas a remoção do `pubspec.yaml` (a ser tratado em mudança separada, fora deste escopo documental).
- **Riscos**: baixos — risco principal é divergência entre a spec e o `pubspec.yaml`/código se as dependências evoluírem sem atualizar a spec.

## Não-objetivos

- Não remover, atualizar versão, adicionar ou alterar qualquer dependência no `pubspec.yaml`.
- Não remover as dependências órfãs (`web`, `flutter_web_plugins`) — apenas registrá-las como tal; a limpeza é uma decisão futura.
- Não documentar dependências transitivas (apenas as declaradas diretamente em `dependencies`/`dev_dependencies`).
- Não redocumentar o comportamento interno de eventos, roteamento ou DI — isso é escopo das specs próprias; aqui descreve-se apenas qual API externa cada um consome e por quê.
- Não criar abstração nem wrapper novo sobre nenhuma dependência.
