## Why

`Module` é o coração do `go_router_modular`: é a abstração que o usuário do pacote realmente escreve. Apesar de a classe ter poucas linhas (`lib/src/core/module/module.dart`), cada um dos seus membros (`imports`, `binds`, `routes`, `initState`, `dispose`, `didChangeGoingReference`/`onDidChangeGoingReference`, `configureRoutes`) é consumido em momentos precisos do ciclo de vida e tem regras sutis — a ordem de execução, a diferença entre `Injector` (escrita) e `InjectorReader` (leitura), por que `imports` é coletado recursivamente com proteção contra ciclos, e por que `AppModule` é especial. Esse contrato não está documentado, o que faz o usuário aprender por tentativa e erro (asserts em runtime) e facilita regressões. Esta mudança documenta o contrato e o ciclo de vida do `Module` em detalhe, como especificação executável, sem alterar comportamento. Complementa as specs `documentar-sistema-di` e `documentar-sistema-roteamento`.

## What Changes

- Documentar o contrato público do `Module`: os tipos de retorno (`FutureBinds = FutureOr<void>`, `FutureModules = FutureOr<List<Module>>`), cada membro e seu propósito.
- Documentar a ordem exata do ciclo de vida no registro: `binds` → coleta recursiva de `imports` → registro/commit em batch → mapeamento de binds ao módulo → `initState` → agendamento de validação.
- Documentar a coleta recursiva de `imports` com proteção contra ciclos (conjunto de visitados) e a ordem em que os binds importados são acumulados.
- Documentar a separação `Injector` (recebido em `binds`, permite registrar) vs `InjectorReader` (recebido em `initState`, somente leitura) como aplicação de Interface Segregation.
- Documentar o ciclo de vida no descarte: `dispose` do módulo antes do descarte dos binds, e a proteção contra descarte prematuro via `didChangeGoingReference`/`onDidChangeGoingReference` (janela de microtask).
- Documentar `configureRoutes({modulePath, topLevel})`: o registro do `AppModule` (idempotente) e a construção das rotas, e o efeito de `topLevel` na normalização de paths.
- Documentar a distinção `AppModule` (registrado uma vez, nunca descartado) vs módulos de feature (registrados sob demanda, descartados ao sair).
- Documentar `EventModule` como extensão do `Module` (hook `initState` que inicia listeners, `eventImports`/`listen`).
- Documentar as asserções de validação de módulo (`ChildRoute('/')` obrigatória em módulo não-shell; proibida diretamente em shell).
- Documentar a forma idiomática de declarar `AppModule`, módulo de feature, módulo com shell, com stateful shell e `EventModule`.
- Mapear onde SOLID aparece (hooks extensíveis, `InjectorReader` segregado, polimorfismo de `Module`) e onde é fraco (`configureRoutes` faz duas coisas; `didChangeGoingReference` é estado mutável público).
- **Sem mudança de comportamento**: nenhuma API é alterada, adicionada ou removida. Mudança puramente documental.

## Capabilities

### New Capabilities
- `module-contract`: O contrato público do `Module` — `imports`, `binds`, `routes`, `initState`, `dispose`, `configureRoutes`, os typedefs `FutureBinds`/`FutureModules`, a separação `Injector` vs `InjectorReader` e as asserções de validação de configuração.
- `module-lifecycle-order`: A ordem determinística do ciclo de vida de um módulo — sequência de registro (binds → imports recursivos → commit → initState), sequência de descarte (dispose → remoção de binds) e a proteção contra descarte prematuro em transição.
- `module-kinds`: As variedades de módulo e seus papéis — `AppModule` (raiz, registrado uma vez via `registerAppModule`, nunca descartado) vs módulos de feature (sob demanda), composição por `imports` com proteção contra ciclos, e `EventModule` como extensão orientada a eventos.

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — esta mudança é puramente documental e não altera as specs de DI e roteamento já propostas. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` é modificado.
- **Artefatos OpenSpec**: novos arquivos de spec em `openspec/specs/module-contract/`, `openspec/specs/module-lifecycle-order/` e `openspec/specs/module-kinds/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `lib/src/core/module/module.dart`, `lib/src/core/manager/injection_manager.dart`, `lib/src/core/manager/bind_context_tracker.dart`, `lib/src/di/injector.dart`, `lib/src/routing/route_builder.dart`, `lib/src/events/event_module.dart`, `lib/src/internal/asserts/module_assert.dart`, e os exemplos em `example/`.
- **Relação com specs existentes**: referencia, mas não duplica, `documentar-sistema-di` (mecânica interna do container) e `documentar-sistema-roteamento` (conversão de rotas e gatilhos de navegação). Aqui o foco é o `Module` como contrato do usuário.
- **Riscos**: baixos — risco principal é divergência entre a spec e o código se o comportamento evoluir sem atualizar a spec.

## Não-objetivos

- Não alterar, refatorar ou corrigir qualquer comportamento do `Module` ou do registro de módulos.
- Não corrigir os pontos fracos de SOLID identificados (dupla responsabilidade de `configureRoutes`, estado mutável público `didChangeGoingReference`). Apenas registrados como contexto.
- Não redocumentar a mecânica interna do container de DI (tipos de bind, resolução, proteções) — escopo de `documentar-sistema-di`; nem a conversão de rotas em si — escopo de `documentar-sistema-roteamento`.
- Não documentar o sistema de eventos em profundidade (barramento, disparo de eventos) — apenas a parte em que `EventModule` estende o ciclo de vida do `Module`.
- Não criar API nova de módulo nem alterar assinaturas existentes.
