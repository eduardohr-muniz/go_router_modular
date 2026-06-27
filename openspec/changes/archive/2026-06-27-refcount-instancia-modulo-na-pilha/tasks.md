## 1. Reproduzir o bug

- [x] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [x] 1.2 Adicionar um widget test do cenário `A → B → A` que hoje FALHA: após pop da entrada de cima de A, `ServiceA` deve continuar resolvível (documenta o bug)
- [x] 1.3 Adicionar o caso `A → A` (push do mesmo módulo sobre si)

## 2. Refcount no registro

- [x] 2.1 Adicionar `Map<Module, int> _referenceCount` (identidade) ao `InjectionManager`
- [x] 2.2 `registerBindsModule(M)`: incrementar o contador; executar o trabalho real de registro apenas na transição 0→1 (substituindo a checagem idempotente `moduleBindTypes.containsKey`)
- [x] 2.3 Garantir que o incremento/decisão ocorra dentro da operação enfileirada (serialização preservada)
- [x] 2.4 `flutter analyze`

## 3. Refcount no descarte

- [x] 3.1 `unregisterModule(M)`: manter a guarda do AppModule; decrementar o contador; só executar o descarte real na transição 1→0
- [x] 3.2 Em referência remanescente (count > 0), retornar sem descartar (binds permanecem)
- [x] 3.3 Confirmar que a cascata de shell stateful (`disposeStatefulShellModule`) decrementa cada módulo corretamente
- [x] 3.4 `flutter analyze`

## 4. Invariantes preservadas

- [x] 4.1 `resetForTesting` limpa `_referenceCount`
- [x] 4.2 Conferir interação com a proteção `didChangeGoingReference`: dispose pulado não decrementa indevidamente (sem drift)
- [x] 4.3 AppModule permanece nunca descartado

## 5. Verificação

- [x] 5.1 O teste do bug (1.2) agora passa: pop da entrada de cima de A mantém `ServiceA`; só o último pop descarta
- [x] 5.2 Caso `A → A` correto; descarte ocorre uma única vez ao sair
- [x] 5.3 Caso comum (módulo aparece uma vez) inalterado
- [x] 5.4 Teste de transição rápida em instância repetida — contador estável (sem vazamento nem use-after-dispose)
- [x] 5.5 `flutter analyze` (lib + test) sem warnings
- [x] 5.6 `flutter test` com a suíte completa passando (incluindo guardas de arquitetura)
- [x] 5.7 Revisar consistência entre proposal, specs, design e tasks
