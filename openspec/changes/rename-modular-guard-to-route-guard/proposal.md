## Why

A classe abstrata que representa a proteção de rota chama-se hoje `ModularGuard`. O prefixo `Modular` é redundante dentro de um pacote cujo domínio já é "modular" e não comunica o que o tipo realmente é: um guard de **rota**. O nome `RouteGuard` revela melhor a intenção (Clean Code — nomes revelam intenção) e alinha a nomenclatura ao vocabulário já consolidado de roteamento (`ChildRoute`, `ModuleRoute`, `ShellModularRoute`). Como a API de guards foi introduzida muito recentemente e ainda não tem base de consumidores publicada, este é o momento de menor custo para corrigir o nome.

## What Changes

- **BREAKING** Renomear a classe abstrata pública `ModularGuard` para `RouteGuard` (mesmo contrato, mesmo método `redirect`).
- Renomear o arquivo `lib/src/routing/guards/modular_guard.dart` para `lib/src/routing/guards/route_guard.dart` e atualizar o `export` no barril `lib/go_router_modular.dart`.
- Atualizar todas as referências internas de tipo: `GuardFn extends ModularGuard`, `List<ModularGuard> guards` em `ChildRoute`, `ModuleRoute`, `ShellModularRoute`, `StatefulShellModularRoute` e `Modular.configure`, além do `guard_resolver`.
- Atualizar a mensagem de depreciação compartilhada (`guardsRedirectDeprecation`) e toda a documentação `///` que cita `ModularGuard`.
- Atualizar os testes que referenciam `ModularGuard` e a documentação da skill `go-router-modular`.

## Capabilities

### New Capabilities

<!-- Nenhuma capability nova: esta mudança apenas renomeia um símbolo público existente. -->

### Modified Capabilities

- `routing-guards`: o tipo central do contrato passa a se chamar `RouteGuard` em vez de `ModularGuard` (requisitos e cenários reescritos com o novo nome).
- `public-api-surface`: o barril principal passa a exportar `RouteGuard` (não mais `ModularGuard`); a subclasse de exemplo passa a ser `class XGuard extends RouteGuard`.
- `routing-configuration`: o parâmetro `guards` de `Modular.configure` passa a ser `List<RouteGuard>`.
- `routing-routes`: o parâmetro `guards` de `ChildRoute`, `ModuleRoute`, `ShellModularRoute` e `StatefulShellModularRoute` passa a ser `List<RouteGuard>`.

## Impact

- **Código (lib)**: `lib/src/routing/guards/route_guard.dart` (arquivo renomeado), `lib/go_router_modular.dart`, `guard_fn.dart`, `guard_resolver.dart`, `child_route.dart`, `module_route.dart`, `shell_modular_route.dart`, `stateful_shell_modular_route.dart`, `go_router_modular_configure.dart`.
- **API pública**: símbolo exportado renomeado — **breaking change** para qualquer consumidor que já tenha declarado `extends ModularGuard` ou tipado `List<ModularGuard>`. Como a API é nova e ainda não publicada, não será mantido alias deprecado.
- **Testes**: `guards_core_test.dart`, `guards_public_api_test.dart`, `guards_route_fields_test.dart`, `guards_builders_integration_test.dart`, `guards_global_configure_test.dart`.
- **Documentação**: `skills/go-router-modular/SKILL.md` e os specs ativos das capabilities modificadas.

## Não-objetivos

- Não alterar o comportamento, a assinatura do método `redirect`, a ordem de resolução em curto-circuito nem qualquer regra de domínio dos guards — é uma renomeação pura.
- Não renomear `GuardFn`, `guardsRedirectDeprecation` (somente o texto interno que cita o nome antigo) nem qualquer outro símbolo do sistema de guards.
- Não manter um alias deprecado `typedef ModularGuard = RouteGuard;` — a renomeação é direta, pois a API ainda não tem consumidores publicados.
- Não reescrever as mudanças já arquivadas em `openspec/changes/archive/` (registro histórico imutável).
