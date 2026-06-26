## 1. Validação dos artefatos de documentação

- [ ] 1.1 Rodar `openspec validate documentar-sistema-roteamento` e corrigir qualquer erro de estrutura nas specs
- [ ] 1.2 Conferir que cada requisito das quatro specs cita o(s) arquivo(s) de referência em `lib/` e que os caminhos existem
- [ ] 1.3 Revisar nomes usados nos cenários para garantir ausência de abreviações (nomes dizem o que a coisa é)
- [ ] 1.4 Conferir que `routing-lifecycle` referencia, e não duplica, a spec `documentar-sistema-di`

## 2. Verificação da capability routing-routes contra o código

- [ ] 2.1 Confirmar seleção polimórfica de rotas por `whereType` no `ModularRouteBuilder` (`route_builder.dart`, `i_modular_route.dart`)
- [ ] 2.2 Confirmar conversão de `ChildRoute` em `GoRoute` (builder, `pageBuilder`, exclusão do índice `/`) (`child_route.dart`, `route_builder.dart`)
- [ ] 2.3 Confirmar `ModuleRoute` → `GoRoute` aninhado e composição de path do índice do módulo (`module_route.dart`, `route_builder.dart`)
- [ ] 2.4 Confirmar `ShellModularRoute` → `ShellRoute` e a asserção contra `ChildRoute('/')` direta no shell (`shell_modular_route.dart`, `route_builder.dart`)
- [ ] 2.5 Confirmar `StatefulShellModularRoute` → `StatefulShellRoute`, branches e equivalência de `ModuleBranch` (`stateful_shell_modular_route.dart`, `route_builder.dart`)
- [ ] 2.6 Confirmar agregação por `buildRoutes` e a normalização de paths (top-level, aninhado, barras duplicadas, `/:` parâmetro) (`route_builder.dart`)

## 3. Verificação da capability routing-lifecycle contra o código

- [ ] 3.1 Confirmar registro de binds no `redirect` antes de construir a tela e o skip de módulo já ativo (`route_builder.dart`, `injection_manager.dart`)
- [ ] 3.2 Confirmar exibição/ocultação do `ModularLoader` e a condição do completer pendente (`route_builder.dart`, `modular_loader.dart`)
- [ ] 3.3 Confirmar descarte do módulo no `dispose` do `ParentWidgetObserver` ao sair da rota (`parent_widget_observer.dart`, `route_builder.dart`, `injection_manager.dart`)
- [ ] 3.4 Confirmar proteção contra descarte prematuro via `onDidChangeGoingReference` (janela de microtask) (`module.dart`, `route_builder.dart`)
- [ ] 3.5 Confirmar descarte em cascata das branches do shell stateful (`route_builder.dart`, `injection_manager.dart`)
- [ ] 3.6 Confirmar que `OnceBuilder` executa a closure uma única vez e evita reinstanciação de factory no rebuild (`once_builder.dart`, `route_builder.dart`)

## 4. Verificação da capability routing-configuration contra o código

- [ ] 4.1 Confirmar `configure` construindo rotas top-level a partir do `appModule` e a idempotência do singleton (`go_router_modular_configure.dart`)
- [ ] 4.2 Confirmar snapshot imutável de parâmetros, `copyRouterConfig`/`copyWith` e memoização do router derivado (`go_router_modular_configure.dart`)
- [ ] 4.3 Confirmar transição padrão global e a precedência da transição por rota (`go_router_modular_configure.dart`, `route_builder.dart`)
- [ ] 4.4 Confirmar precedência de container do shell stateful (container explícito > transição > `indexedStack`) (`stateful_shell_branch_transitions.dart`, `route_builder.dart`)
- [ ] 4.5 Confirmar `ModularApp.router` injetando o router modular e sobrepondo o overlay do loader (`material_app_router.dart`, `modular_loader.dart`)

## 5. Verificação da capability routing-navigation contra o código

- [ ] 5.1 Confirmar variantes assíncronas de navegação com completers e `onComplete` (`route_extension.dart`)
- [ ] 5.2 Confirmar utilitários `popUntil`/`popUntilNamed` (`route_extension.dart`)
- [ ] 5.3 Confirmar leitura de estado e parâmetros de rota (`getPathParam`, path corrente, `GoRouterState`) (`route_extension.dart`)
- [ ] 5.4 Confirmar `context.read<T>()` delegando à resolução do container e falhando como a resolução direta (`context_extension.dart`, `bind.dart`)

## 6. Cobertura de testes (mapear cenários ↔ testes existentes)

- [ ] 6.1 Mapear cada `#### Scenario` das quatro specs para o(s) teste(s) que já o cobrem em `test/`
- [ ] 6.2 Identificar cenários sem teste correspondente e adicionar testes (caminho de sucesso e de erro), incluindo widget tests para ciclo de vida e transições
- [ ] 6.3 Garantir cobertura de branches dos mecanismos críticos (registro/descarte, proteção de transição, precedência de transição do shell, normalização de paths)

## 7. Verificação final

- [ ] 7.1 Rodar `flutter analyze` sem warnings
- [ ] 7.2 Rodar `flutter test --coverage` com a suíte passando
- [ ] 7.3 Conferir `coverage/lcov.info` atingindo 100% de cobertura (linhas e branches) nos arquivos de roteamento documentados
- [ ] 7.4 Revisar consistência final entre proposal, specs, design e tasks, e a fronteira com a spec de DI
