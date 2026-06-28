## 1. Renomear o arquivo e o símbolo

- [ ] 1.1 `git mv lib/src/routing/guards/modular_guard.dart lib/src/routing/guards/route_guard.dart`
- [ ] 1.2 Renomear `abstract class ModularGuard` para `abstract class RouteGuard` (e o construtor `const ModularGuard()` → `const RouteGuard()`) em `route_guard.dart`
- [ ] 1.3 Atualizar a doc `///` e o exemplo (`class AuthGuard extends ModularGuard` → `extends RouteGuard`) e o texto do `guardsRedirectDeprecation` que cita `extends ModularGuard`, em `route_guard.dart`

## 2. Atualizar export e referências internas em lib/

- [ ] 2.1 Atualizar o export no barril `lib/go_router_modular.dart` de `src/routing/guards/modular_guard.dart` para `src/routing/guards/route_guard.dart`
- [ ] 2.2 Atualizar `lib/src/routing/guards/guard_fn.dart`: import do novo arquivo, `class GuardFn extends RouteGuard` e doc `///`
- [ ] 2.3 Atualizar `lib/src/routing/guards/guard_resolver.dart`: import, assinaturas `List<RouteGuard>`, variável `chain` e docs `///`
- [ ] 2.4 Atualizar `lib/src/routing/child_route.dart`: `final List<RouteGuard> guards;` e referência `[RouteGuard]` na doc
- [ ] 2.5 Atualizar `lib/src/routing/module_route.dart`: `final List<RouteGuard> guards;` e referência `[RouteGuard]` na doc
- [ ] 2.6 Atualizar `lib/src/routing/shell_modular_route.dart`: `final List<RouteGuard> guards;` e referência `[RouteGuard]` na doc
- [ ] 2.7 Atualizar `lib/src/routing/stateful_shell_modular_route.dart`: `final List<RouteGuard> guards;` e referência `[RouteGuard]` na doc
- [ ] 2.8 Atualizar `lib/src/bootstrap/go_router_modular_configure.dart`: parâmetro `List<RouteGuard> guards` e doc `///`

## 3. Atualizar testes

- [ ] 3.1 Substituir `ModularGuard` por `RouteGuard` e o import `modular_guard.dart` por `route_guard.dart` em `test/guards_core_test.dart`
- [ ] 3.2 Substituir `ModularGuard` por `RouteGuard` em `test/guards_public_api_test.dart`
- [ ] 3.3 Substituir `ModularGuard` por `RouteGuard` em `test/guards_route_fields_test.dart`
- [ ] 3.4 Substituir `ModularGuard` por `RouteGuard` em `test/guards_builders_integration_test.dart`
- [ ] 3.5 Substituir `ModularGuard` por `RouteGuard` em `test/guards_global_configure_test.dart`

## 4. Atualizar documentação

- [ ] 4.1 Substituir `ModularGuard` por `RouteGuard` em `skills/go-router-modular/SKILL.md`

## 5. Verificação

- [ ] 5.1 `grep -rn "ModularGuard\|modular_guard" lib/ test/ skills/` retorna zero resultados
- [ ] 5.2 `flutter analyze` sem erros nem warnings
- [ ] 5.3 `flutter test --coverage` com todos os testes passando e cobertura mantida (linhas e branches)
