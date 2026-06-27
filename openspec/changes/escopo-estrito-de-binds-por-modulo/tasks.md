## 1. Linha de base

- [ ] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [ ] 1.2 Escrever um teste do cenário do usuário (push A→B; B resolve bind não declarado) documentando o comportamento atual (resolve) — vira a verificação alvo

## 2. Visibilidade (sem mudança de comportamento)

- [ ] 2.1 Computar e cachear `visibleSet(M) = moduleBindTypes[M] ∪ moduleBindTypes[AppModule]` no `BindContextTracker`
- [ ] 2.2 Taguear cada `Bind` canônico com seu módulo declarante no registro (`InjectionManager`)
- [ ] 2.3 Expor consultas: `isVisible(BindIdentifier, Module scope)` e `declaringModuleOf(BindIdentifier)`
- [ ] 2.4 `flutter analyze` e suíte verdes (ainda sem enforcement)

## 3. Threading do escopo na resolução

- [ ] 3.1 Adicionar parâmetro `Module? scope` a `BindLocator.get`/`tryGet` e a `Bind.get`/`tryGet` (default = AppModule)
- [ ] 3.2 Adicionar campo `Module? scopeModule` ao `Injector`; `binds(M)` recebe injector escopado a M
- [ ] 3.3 `BindLocator._createInstance`/`Bind.instance` invocam a factory com `Injector` escopado ao módulo declarante do bind
- [ ] 3.4 `flutter analyze`; suíte verde (escopo propagado, checagem ainda desligada)

## 4. Enforcement — checagem + exceção

- [ ] 4.1 Em `BindLocator.get` (inclusive fast-path) e `_find`, checar pertencimento ao `visibleSet(scope)` antes de retornar
- [ ] 4.2 Lançar `GoRouterModularException` acionável na violação (solicitante, tipo, dono, correção sugerida)
- [ ] 4.3 `tryGet` fora do escopo retorna `null` (captura a violação)
- [ ] 4.4 `flutter analyze`

## 5. Enforcement por contexto de widget

- [ ] 5.1 `ParentWidgetObserver` provê um `InheritedWidget` (`ModuleScope`) com o módulo da subárvore
- [ ] 5.2 `context.read<T>()` resolve no escopo do `ModuleScope` mais próximo (fallback AppModule se ausente)
- [ ] 5.3 `flutter analyze`

## 6. Enforcement estático (AppModule)

- [ ] 6.1 `Modular.get`/`tryGet`/`isRegistered` e `Bind.get` estáticos resolvem no escopo do AppModule
- [ ] 6.2 `flutter analyze`

## 7. Corrigir testes e exemplos

- [ ] 7.1 Mapear e corrigir testes que resolvem binds cross-module sem import (declarar import ou injetar)
- [ ] 7.2 Corrigir o `example/` onde houver resolução fora de escopo
- [ ] 7.3 Atualizar o teste do cenário do usuário (1.2) para esperar a exceção

## 8. Verificação final

- [ ] 8.1 Cenário do usuário: push A→B; B resolve `ServiceB` não declarado → `GoRouterModularException` com mensagem acionável
- [ ] 8.2 Casos positivos: bind próprio, bind importado e bind do AppModule resolvem normalmente
- [ ] 8.3 `context.read` escopado e `Modular.get` (AppModule) conforme a spec
- [ ] 8.4 `flutter analyze` (lib + test) sem warnings
- [ ] 8.5 `flutter test` com a suíte (corrigida) passando, incluindo as guardas de arquitetura
- [ ] 8.6 Revisar consistência entre proposal, specs, design e tasks
