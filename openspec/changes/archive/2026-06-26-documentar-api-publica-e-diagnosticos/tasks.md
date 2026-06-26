## 1. Auditoria de cobertura e leitura de referência

- [ ] 1.1 Reexecutar a auditoria de cobertura (basename de cada arquivo de `lib/` cruzado com todas as specs) e confirmar que os cinco arquivos-alvo continuam sendo os únicos não referenciados.
- [ ] 1.2 Ler os barris `lib/go_router_modular.dart` e `lib/testing.dart`, registrando exports por área e a política de `hide`/`show`.
- [ ] 1.3 Ler `go_router_modular_configure_assert.dart`, `internal_logs.dart` e `dependency_analyzer.dart` e mapear seus pontos de uso em `lib/` (`go_router_modular_configure.dart`, `modular_test_scope.dart`, `bind_search_protection.dart`).

## 2. Documentar capability public-api-surface

- [ ] 2.1 Revisar o requisito do barril principal confirmando os exports por área e que widgets internos (`once_builder.dart`, `parent_widget_observer.dart`) não são exportados.
- [ ] 2.2 Revisar o requisito de re-export de pacotes externos confirmando `hide GoRouter, ShellRoute`, `hide GoTransition`, o export completo de `event_bus` e o `show` seletivo do sistema de eventos.
- [ ] 2.3 Revisar o requisito do barril de testes confirmando os exports (`ModularTestScope`, `EventRecorder`, `RecordedEventList`, `FakeInjector`, `ModularEventBus`) e os re-exports de conveniência.
- [ ] 2.4 Garantir um teste/checagem que importe apenas `package:go_router_modular/go_router_modular.dart` e use a API pública sem imports de `src/`, e outro que importe `package:go_router_modular/testing.dart` e use os utilitários de teste.

## 3. Documentar capability internal-diagnostics

- [ ] 3.1 Revisar o requisito do assert de configuração confirmando a mensagem-guia e os dois acessos protegidos em `go_router_modular_configure.dart`.
- [ ] 3.2 Garantir teste cobrindo o `assert` disparando antes de `configure` e não disparando após `configure`.
- [ ] 3.3 Revisar o requisito de `iLog`/`kInternalLogs` confirmando o respeito à flag e o estado dormente (nenhuma chamada em `lib/`).
- [ ] 3.4 Garantir uma checagem de regressão que falhe se `iLog(` passar a ser chamado em `lib/` sem atualizar a spec (detecta saída do estado dormente).
- [ ] 3.5 Revisar o requisito do `DependencyAnalyzer` confirmando janela de histórico (`_historyWindow = 10`), `successRate` padrão `1.0`, `clearAll`/`clearTypeHistory` e que produção só usa `clearAll()`.
- [ ] 3.6 Garantir teste cobrindo: janela máxima de histórico, taxa de sucesso `1.0` sem histórico, e `clearAll()` zerando histórico/buscas/grafo.
- [ ] 3.7 Garantir uma checagem que confirme que as APIs de rastreamento do `DependencyAnalyzer` continuam sem chamadas em `lib/` (apenas `clearAll`), detectando mudança de estado dormente.

## 4. Validação final

- [ ] 4.1 Verificar que nenhum arquivo em `lib/` foi alterado (mudança puramente documental).
- [ ] 4.2 Rodar `flutter analyze` e garantir ausência de avisos novos.
- [ ] 4.3 Rodar `flutter test --coverage` e confirmar a suíte verde e a cobertura dos arquivos-alvo (`go_router_modular_configure_assert.dart`, `dependency_analyzer.dart`, barris).
- [ ] 4.4 Conferir consistência final entre cada requisito da spec e os barris/pontos de uso; registrar divergências como tarefas adicionais.
