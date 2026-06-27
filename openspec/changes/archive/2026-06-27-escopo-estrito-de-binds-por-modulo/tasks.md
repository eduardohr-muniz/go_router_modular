## 1. Linha de base e cenário

- [x] 1.1 Rodar `flutter analyze` e `flutter test` e registrar a linha de base verde
- [x] 1.2 Escrever o teste do cenário: `ModuleB` cujo bind depende de `ServiceB` (não declarado nem importado) — hoje registra sem erro; alvo: lançar no push

## 2. Visibilidade

- [x] 2.1 Adicionar `BindContextTracker.isVisible(BindIdentifier bindId, Module scope)` (próprios ∪ AppModule)
- [x] 2.2 (Revisado) Gravar dependências durante o commit em vez de taguear o `Bind`: o `Injector` ganhou `beginScopeRecording`/`endScopeRecording` e grava cada `get` quando ativo — não re-executa factory (preserva a invariante "construir 1×")
- [x] 2.3 `flutter analyze` e suíte verdes (sem enforcement ainda)

## 3. Validação de escopo no registro

- [x] 3.1 (Revisado) Em vez de um injector que re-roda factories, a gravação ocorre no `_injector` compartilhado DURANTE o commit (execução única legítima) — o recorder que re-executava quebrava a contagem de construtor, então foi descartado
- [x] 3.2 Criar `_validateModuleScope(module, recordedDependencies)`: checa cada dependência gravada no commit contra `isVisible`
- [x] 3.3 Envolver `Bind.commitBatch` com `beginScopeRecording`/`endScopeRecording` em `_registerBindsModuleInternal` e validar de forma **eager** (síncrona)
- [x] 3.4 Lançar `GoRouterModularException` acionável na violação (módulo, tipo, correção)
- [x] 3.5 `flutter analyze`

## 4. Verificação e ajustes

- [x] 4.1 O teste do cenário (1.2) agora lança no push de `ModuleB`
- [x] 4.2 Casos positivos: dependência de bind próprio, importado e do AppModule registram sem erro
- [x] 4.3 Confirmar que erros legítimos de "bind não encontrado" continuam fluindo normalmente (não confundidos com violação de escopo)
- [x] 4.4 Rodar a suíte; mapear e corrigir testes/exemplos que dependiam de resolução cross-module sem import (declarar import)
- [x] 4.5 `flutter analyze` (lib + test) sem warnings
- [x] 4.6 `flutter test` com a suíte passando (incluindo guardas de arquitetura)
- [x] 4.7 Revisar consistência entre proposal, specs, design e tasks
