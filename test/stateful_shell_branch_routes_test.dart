import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/routing/route_builder.dart';

class _EmptyLeafModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const SizedBox()),
      ];
}

class _TwoBranchShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          branches: [
            ModularBranch(
              routes: [
                ModuleRoute('/pos', module: _EmptyLeafModule()),
              ],
            ),
            ModularBranch(
              routes: [
                ModuleRoute('/settings', module: _EmptyLeafModule()),
              ],
            ),
          ],
        ),
      ];
}

class _TabsStatefulShellModule extends Module {
  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          branches: [
            ModularBranch(
              routes: [
                ModuleRoute('/alpha', module: _EmptyLeafModule()),
              ],
            ),
          ],
        ),
      ];
}

class _AppModuleUnderTest extends Module {
  @override
  List<ModularRoute> get routes => [
        ModuleRoute('/tabs', module: _TabsStatefulShellModule()),
      ];
}

void main() {
  group('ModularBranch — apenas routes', () {
    test('ModularBranch deve falhar quando routes está vazio', () {
      expect(
        () => ModularBranch(routes: []),
        throwsAssertionError,
      );
    });

    test('cada branch com ModuleRoute distinto gera GoRoute com path diferente no shell', () {
      final built = ModularRouteBuilder(_TwoBranchShellModule()).buildRoutes(modulePath: '/home', topLevel: false);
      final shell = built.whereType<StatefulShellRoute>().single;
      expect(shell.branches.length, equals(2));

      final branchPaths = shell.branches.map((b) {
        expect(b.routes, isNotEmpty);
        final route = b.routes.single;
        expect(route, isA<GoRoute>());
        return (route as GoRoute).path;
      }).toList();

      expect(branchPaths.toSet().length, equals(2), reason: 'paths duplicados quebram redirect do go_router');
      expect(branchPaths, containsAll(<String>['pos', 'settings']));
    });

    testWidgets(
      'GoRouter: ModuleRoute com StatefulShell não quebra redirect quando primeira branch resolve para o mesmo path',
      (tester) async {
        final routes = ModularRouteBuilder(_AppModuleUnderTest()).buildRoutes(topLevel: true);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              routes: routes,
              initialLocation: '/tabs',
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
      },
    );
  });

  group('ModuleBranch', () {
    test('expõe path e module alinhados ao ModuleRoute interno', () {
      final leaf = _EmptyLeafModule();
      final branch = ModuleBranch('/checkout', module: leaf);

      expect(branch.path, '/checkout');
      expect(identical(branch.module, leaf), isTrue);

      expect(branch.routes.length, 1);
      final mr = branch.routes.single as ModuleRoute;
      expect(mr.path, '/checkout');
      expect(identical(mr.module, leaf), isTrue);
    });

    test('produz o mesmo resultado no RouteBuilder que ModularBranch + ModuleRoute', () {
      final leaf = _EmptyLeafModule();

      final shellModular = _ShellWithModularBranches(leaf);
      final shellModuleBranch = _ShellWithModuleBranches(leaf);

      final builtA = ModularRouteBuilder(shellModular).buildRoutes(modulePath: '/app', topLevel: false);
      final builtB = ModularRouteBuilder(shellModuleBranch).buildRoutes(modulePath: '/app', topLevel: false);

      final pathsA = _branchPathsFromShell(builtA);
      final pathsB = _branchPathsFromShell(builtB);
      expect(pathsA, equals(pathsB));
    });
  });
}

List<String> _branchPathsFromShell(List<RouteBase> built) {
  final shell = built.whereType<StatefulShellRoute>().single;
  return shell.branches.map((b) => (b.routes.single as GoRoute).path).toList();
}

class _ShellWithModularBranches extends Module {
  _ShellWithModularBranches(this.leaf);

  final Module leaf;

  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          branches: [
            ModularBranch(routes: [ModuleRoute('/a', module: leaf)]),
            ModularBranch(routes: [ModuleRoute('/b', module: leaf)]),
          ],
        ),
      ];
}

class _ShellWithModuleBranches extends Module {
  _ShellWithModuleBranches(this.leaf);

  final Module leaf;

  @override
  List<ModularRoute> get routes => [
        StatefulShellModularRoute(
          branches: [
            ModuleBranch('/a', module: leaf),
            ModuleBranch('/b', module: leaf),
          ],
        ),
      ];
}
