## 1. Validação dos artefatos de documentação

- [ ] 1.1 Rodar `openspec validate documentar-sistema-di` e corrigir qualquer erro de estrutura nas specs
- [ ] 1.2 Conferir que cada requisito das três specs cita o(s) arquivo(s) de referência em `lib/` e que os caminhos existem
- [ ] 1.3 Revisar nomes usados nos cenários para garantir ausência de abreviações (nomes dizem o que a coisa é)

## 2. Verificação da capability dependency-injection contra o código

- [ ] 2.1 Confirmar no código que singleton eager instancia uma vez no commit e preserva identidade (`bind.dart`, `bind_registry.dart`)
- [ ] 2.2 Confirmar que singleton lazy só instancia na primeira resolução e cacheia (`bind.dart`, `bind_locator.dart`)
- [ ] 2.3 Confirmar que factory cria nova instância a cada resolução (`bind.dart`, `bind_locator.dart`)
- [ ] 2.4 Confirmar armazenamento dual: bind sem chave em `bindsMap`, bind com chave em `bindsMapByKey`, sem sobreposição (`bind_storage.dart`, `bind_registry.dart`)
- [ ] 2.5 Confirmar fast-path de resolução de singleton cacheado e o comportamento de `tryGet`/`isRegistered` sem instanciar (`bind_locator.dart`)
- [ ] 2.6 Confirmar cache negativo: memoriza tipo ausente e é invalidado ao registrar/remover bind (`bind_locator.dart`, `bind_registry.dart`, `bind_disposer.dart`)
- [ ] 2.7 Confirmar descarte polimórfico `dispose`→`close`→`cancel` ignorando `NoSuchMethodError` e zerando o cache (`clean_bind.dart`, `bind_disposer.dart`)

## 3. Verificação da capability dependency-injection-protection contra o código

- [ ] 3.1 Confirmar detecção de ciclo real A→B→A com `GoRouterModularException` e mensagem de cadeia (`bind_locator.dart`, `bind_search_protection.dart`)
- [ ] 3.2 Confirmar bypass de self-reference legítima restrito à invocação mais recente (`bind_locator.dart`, `bind_search_protection.dart`)
- [ ] 3.3 Confirmar limite de tentativas de busca como salvaguarda e limpeza de estado ao exceder (`bind_search_protection.dart`)
- [ ] 3.4 Confirmar bloqueio de factory por identidade com contador aninhado (`bind_search_protection.dart`, `bind_locator.dart`)
- [ ] 3.5 Confirmar propagação de cache entre binds duplicados de módulos importados (singleton instanciado uma vez) (`bind_registry.dart`, `injection_manager.dart`)

## 4. Verificação da capability module-lifecycle contra o código

- [ ] 4.1 Confirmar contrato do `Module` (`imports`, `binds`, `routes`, `initState`, `dispose`) (`module.dart`)
- [ ] 4.2 Confirmar registro em batch com coleta recursiva de imports antes do `initState` (`injection_manager.dart`)
- [ ] 4.3 Confirmar rastreamento bidirecional módulo↔bind via `BindIdentifier` (`bind_context_tracker.dart`, `bind_identifier.dart`)
- [ ] 4.4 Confirmar descarte de bind apenas quando o último módulo o libera e proteção do AppModule (`injection_manager.dart`, `bind_context_tracker.dart`)
- [ ] 4.5 Confirmar serialização de registro/descarte pela `OperationQueue` e propagação de `GoRouterModularException` (`operation_queue.dart`, `injection_manager.dart`)
- [ ] 4.6 Confirmar reset de testes e o comportamento de `FakeInjector`/`BindTemplate` (`injection_manager.dart`, `fake_injector.dart`, `bind_template.dart`)

## 5. Cobertura de testes (mapear cenários ↔ testes existentes)

- [ ] 5.1 Mapear cada `#### Scenario` das três specs para o(s) teste(s) que já o cobrem em `test/`
- [ ] 5.2 Identificar cenários sem teste correspondente e adicionar testes cobrindo caminho de sucesso e de erro
- [ ] 5.3 Garantir cobertura de branches dos mecanismos de proteção (ciclo, self-reference, limite de tentativas, bloqueio aninhado)

## 6. Verificação final

- [ ] 6.1 Rodar `flutter analyze` sem warnings
- [ ] 6.2 Rodar `flutter test --coverage` com a suíte passando
- [ ] 6.3 Conferir `coverage/lcov.info` atingindo 100% de cobertura (linhas e branches) nos arquivos de DI documentados
- [ ] 6.4 Revisar consistência final entre proposal, specs, design e tasks
