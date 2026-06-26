## 1. Validação dos artefatos de documentação

- [ ] 1.1 Rodar `openspec validate documentar-module-detalhado` e corrigir qualquer erro de estrutura nas specs
- [ ] 1.2 Conferir que cada requisito das três specs cita o(s) arquivo(s) de referência em `lib/` e que os caminhos existem
- [ ] 1.3 Revisar nomes usados nos cenários para garantir ausência de abreviações (nomes dizem o que a coisa é)
- [ ] 1.4 Conferir a fronteira: `module-kinds` e `module-lifecycle-order` referenciam, e não duplicam, `documentar-sistema-di` e `documentar-sistema-roteamento`

## 2. Verificação da capability module-contract contra o código

- [ ] 2.1 Confirmar implementações padrão neutras de `imports`, `binds`, `routes`, `initState`, `dispose` (`module.dart`)
- [ ] 2.2 Confirmar typedefs `FutureBinds`/`FutureModules` e suporte a `binds`/`imports` síncronos e assíncronos (`module.dart`, `injection_manager.dart`)
- [ ] 2.3 Confirmar que `binds` recebe `Injector` (escrita) e a coleta via `startRegistering`/`finishRegistering` (`injector.dart`, `injection_manager.dart`)
- [ ] 2.4 Confirmar que `initState` recebe `InjectorReader` (somente leitura) e não expõe métodos de registro (`module.dart`, `injector.dart`)
- [ ] 2.5 Confirmar consumo de `routes` pelo `ModularRouteBuilder` e os tipos suportados (`route_builder.dart`)
- [ ] 2.6 Confirmar `configureRoutes` registrando o `AppModule` (idempotente) e construindo rotas, com efeito de `topLevel` (`module.dart`, `route_builder.dart`, `injection_manager.dart`)
- [ ] 2.7 Confirmar as asserções `ChildRoute('/')` obrigatória em módulo não-shell e proibida em shell (`module_assert.dart`, `route_builder.dart`)

## 3. Verificação da capability module-lifecycle-order contra o código

- [ ] 3.1 Confirmar a ordem de registro: binds → imports recursivos → registerBatch/commitBatch → mapeamento → initState → validação agendada (`injection_manager.dart`)
- [ ] 3.2 Confirmar que `initState` ocorre após o commit e que binds já são resolvíveis nele (`injection_manager.dart`)
- [ ] 3.3 Confirmar a coleta recursiva de imports e a proteção contra ciclos via conjunto de visitados (`injection_manager.dart`)
- [ ] 3.4 Confirmar a ordem de descarte: `dispose` antes da remoção de binds e limpeza de rastreamento (`injection_manager.dart`, `module.dart`)
- [ ] 3.5 Confirmar a proteção contra descarte prematuro (`didChangeGoingReference` + microtask) e o consumo em `_disposeModule` (`module.dart`, `route_builder.dart`)
- [ ] 3.6 Confirmar que falha na validação agendada não interrompe o ciclo de vida (`injection_manager.dart`)

## 4. Verificação da capability module-kinds contra o código

- [ ] 4.1 Confirmar `registerAppModule` idempotente e o AppModule nunca descartado (`injection_manager.dart`, `bind_context_tracker.dart`)
- [ ] 4.2 Confirmar registro sob demanda e `initState`/`dispose` por ciclo de carga/descarga em módulos de feature (`injection_manager.dart`, `route_builder.dart`)
- [ ] 4.3 Confirmar que bind compartilhado só é descartado pelo último consumidor (`bind_context_tracker.dart`, `injection_manager.dart`)
- [ ] 4.4 Confirmar `EventModule` ativando listeners em `initState` (`event_module.dart`)
- [ ] 4.5 Conferir as formas idiomáticas contra os exemplos reais em `example/` (AppModule, feature, shell, stateful shell, EventModule)

## 5. Cobertura de testes (mapear cenários ↔ testes existentes)

- [ ] 5.1 Mapear cada `#### Scenario` das três specs para o(s) teste(s) que já o cobrem em `test/`
- [ ] 5.2 Identificar cenários sem teste correspondente e adicionar testes (caminho de sucesso e de erro), incluindo ordem de ciclo de vida e proteção de transição
- [ ] 5.3 Garantir cobertura de branches dos mecanismos críticos (imports recursivos com ciclo, proteção de descarte prematuro, idempotência do AppModule, asserções de configuração)

## 6. Verificação final

- [ ] 6.1 Rodar `flutter analyze` sem warnings
- [ ] 6.2 Rodar `flutter test --coverage` com a suíte passando
- [ ] 6.3 Conferir `coverage/lcov.info` atingindo 100% de cobertura (linhas e branches) nos arquivos relacionados ao `Module`
- [ ] 6.4 Revisar consistência final entre proposal, specs, design e tasks, e a fronteira com as specs de DI e de roteamento
