/// TDD — garante que o `childBuilder` de `ParentWidgetObserver` é invocado
/// apenas UMA VEZ por ciclo de vida do widget, mesmo quando o widget pai
/// é reconstruído (ex: hot-reload, AnimatedBuilder, setState externo).
///
/// Problema reproduzido:
///   - `ModularRouteBuilder._createModule` passava
///     `child: nonNullChildRoute.child(context, state)` diretamente ao
///     `ParentWidgetObserver`. Como essa expressão é avaliada a cada chamada
///     do `moduleBuilder` (que é o `builder:` do `GoRoute`), todo rebuild
///     do GoRouter chamava a closure da rota novamente.
///   - Quando a closure contém `Modular.get<FactoryBind>()`, uma NOVA
///     instância da factory é criada a cada rebuild — em hot-reload isso
///     descarta o cubit anterior com todo o seu estado.
///
/// Correção:
///   - `ParentWidgetObserver` passa a aceitar `childBuilder: WidgetBuilder`
///     e armazena o widget construído na primeira chamada de `build()`,
///     retornando o mesmo widget em todos os rebuilds subsequentes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/ui/parent_widget_observer.dart';
import 'package:go_router_modular/go_router_modular.dart';

// ---------------------------------------------------------------------------
// Módulo stub (necessário apenas para satisfazer a API do ParentWidgetObserver)
// ---------------------------------------------------------------------------

class _StubModule extends Module {
  @override
  List<ModularRoute> get routes => const [];
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  group('ParentWidgetObserver.childBuilder', () {
    testWidgets(
      'childBuilder é chamado apenas uma vez — mesmo após rebuild do pai',
      (tester) async {
        int buildCount = 0;

        final module = _StubModule();

        // Widget pai com estado para forçar rebuilds
        final controller = ValueNotifier<int>(0);

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<int>(
              valueListenable: controller,
              builder: (context, _, __) => ParentWidgetObserver(
                module: module,
                onDispose: (_) {},
                didChangeDependencies: (_) {},
                childBuilder: (_) {
                  buildCount++;
                  return const Text('child');
                },
              ),
            ),
          ),
        );

        // 1ª renderização: childBuilder deve ter sido chamado exatamente 1x
        expect(buildCount, 1, reason: 'childBuilder deve ser chamado na 1ª renderização');

        // Força rebuild do pai (simula hot-reload / setState externo)
        controller.value = 1;
        await tester.pump();

        // childBuilder NÃO deve ser chamado novamente
        expect(buildCount, 1, reason: 'childBuilder não deve ser chamado em rebuilds');
      },
    );

    testWidgets(
      'child estático (shell routes) continua funcionando sem regressão',
      (tester) async {
        final module = _StubModule();

        await tester.pumpWidget(
          MaterialApp(
            home: ParentWidgetObserver(
              module: module,
              onDispose: (_) {},
              didChangeDependencies: (_) {},
              child: const Text('shell-child'),
            ),
          ),
        );

        expect(find.text('shell-child'), findsOneWidget);
      },
    );

    testWidgets(
      'onDispose é chamado quando o widget é removido da árvore',
      (tester) async {
        final module = _StubModule();
        Module? disposedModule;

        await tester.pumpWidget(
          MaterialApp(
            home: ParentWidgetObserver(
              module: module,
              onDispose: (m) => disposedModule = m,
              didChangeDependencies: (_) {},
              childBuilder: (_) => const Text('child'),
            ),
          ),
        );

        expect(disposedModule, isNull);

        // Remove o widget da árvore
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        expect(disposedModule, same(module));
      },
    );
  });
}
