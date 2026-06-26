## Why

As specs já propostas cobrem DI, roteamento, módulos, eventos e dependências, mas uma auditoria de cobertura (basename de cada arquivo de `lib/` cruzado com todas as specs) mostra que **cinco arquivos não estão documentados em nenhuma spec**: os dois barris de API pública (`lib/go_router_modular.dart`, `lib/testing.dart`), o helper de assert de configuração (`lib/src/internal/asserts/go_router_modular_configure_assert.dart`), o sistema de logs internos (`lib/src/internal/internal_logs.dart`) e o analisador de dependências (`lib/src/core/dependency_analyzer/dependency_analyzer.dart`). Dois deles têm comportamento surpreendente que precisa ser registrado: `internal_logs.dart` (`iLog`/`kInternalLogs`) **não é chamado em lugar nenhum** do `lib/`, e o `DependencyAnalyzer` tem suas APIs de rastreamento (`recordSearchAttempt`, `startSearch`, `endSearch`, `recordDependency`, `successRate`) exercitadas **apenas pelo próprio teste** — em produção só `clearAll()` é invocado, e a proteção real contra ciclos vive em `BindSearchProtection`. Documentar isso fecha a cobertura da superfície pública e torna visível o código dormente (Clean Code: sem código morto escondido), dando aos mantenedores um inventário confiável e candidatos a limpeza.

## What Changes

- Documentar a **superfície de API pública** em `lib/go_router_modular.dart`: o que é exportado por área (core, DI, routing, exceptions, widgets, eventos) e a política deliberada de re-export de pacotes externos com ocultação — `go_router` com `hide GoRouter, ShellRoute`, `go_transitions` com `hide GoTransition`, `event_bus` completo — para que os tipos modulares (`GoRouterModular`, `ShellModularRoute`, `GoTransition` modular) substituam os originais sem colisão.
- Documentar o **barril de testes** `lib/testing.dart`: o que `import 'package:go_router_modular/testing.dart'` expõe (`ModularTestScope`, `EventRecorder`, `RecordedEventList`, `FakeInjector`, `ModularEventBus`) e os re-exports de conveniência (`clearEventModuleState`, `defaultModularEventBus`).
- Documentar o **assert de configuração** `GoRouterModularConfigureAssert.goRouterModularConfigureAssert()`: a mensagem-guia exibida quando `routerConfig`/`params` são acessados antes de `GoRouterModular.configure`, e onde é aplicada (`go_router_modular_configure.dart`).
- Documentar o **log interno** `iLog`/`kInternalLogs` e registrar honestamente que está **dormente** (definido, mas não chamado em `lib/`) — candidato a remoção ou a passar a ser usado.
- Documentar o **`DependencyAnalyzer`** (histórico de tentativas por tipo com janela fixa, taxa de sucesso, grafo de dependências, `clearAll`/`clearTypeHistory`) e registrar que, em produção, **apenas `clearAll()` é usado** (limpeza em `ModularTestScope`); o restante é infraestrutura dormente, sendo a proteção contra ciclos efetiva feita por `BindSearchProtection`.
- **Sem mudança de comportamento e sem alterar `lib/`**: mudança puramente documental.

## Capabilities

### New Capabilities
- `public-api-surface`: A superfície pública exportada pelos barris `lib/go_router_modular.dart` e `lib/testing.dart` — o que é público por área, a política de `hide`/`show` nos re-exports de pacotes externos e o conjunto público de utilitários de teste.
- `internal-diagnostics`: Os helpers internos de diagnóstico e guarda — o assert-guia de configuração (ativo), o log interno `iLog`/`kInternalLogs` (dormente) e o `DependencyAnalyzer` (rastreamento dormente; só `clearAll` em produção).

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — esta mudança é puramente documental e não altera as specs já propostas. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` é modificado.
- **Artefatos OpenSpec**: novos arquivos de spec em `openspec/specs/public-api-surface/` e `openspec/specs/internal-diagnostics/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `lib/go_router_modular.dart`, `lib/testing.dart`, `lib/src/internal/asserts/go_router_modular_configure_assert.dart`, `lib/src/internal/internal_logs.dart`, `lib/src/core/dependency_analyzer/dependency_analyzer.dart`, e os pontos de uso em `lib/src/core/config/go_router_modular_configure.dart` e `lib/src/testing/modular_test_scope.dart`.
- **Relação com outras specs**: fecha a cobertura documental do `lib/`; referencia, mas não duplica, `documentar-sistema-di`, `documentar-sistema-roteamento`, `documentar-event-module`, `documentar-module-detalhado` e `documentar-dependencias-packages`.
- **Achados acionáveis**: `internal_logs.dart` (`iLog`) e a maior parte do `DependencyAnalyzer` são candidatos a remoção ou ativação — decisão futura, fora deste escopo documental.
- **Riscos**: baixos — risco principal é divergência entre a spec e o código se a superfície pública ou os helpers evoluírem sem atualizar a spec.

## Não-objetivos

- Não remover, ativar ou alterar `iLog`/`kInternalLogs` nem o `DependencyAnalyzer` — apenas registrá-los como dormentes; a limpeza/ativação é decisão futura.
- Não alterar a política de exports dos barris (nada é exposto, ocultado ou re-exportado de forma diferente).
- Não redocumentar o comportamento interno de DI, roteamento, módulos ou eventos — isso é escopo das specs próprias; aqui descreve-se a superfície pública e os helpers de diagnóstico.
- Não criar abstração, wrapper ou API nova.
- Não documentar arquivos já referenciados por outras specs (cobertura já existente).
