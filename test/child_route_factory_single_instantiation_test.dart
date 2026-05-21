/// TDD — garante que o builder de um ChildRoute dentro de um ModuleRoute
/// invoca a closure da rota apenas UMA VEZ por ciclo de vida da página,
/// mesmo quando o GoRouter reconstrói o widget (hot-reload, setState, etc.).
///
/// Problema reproduzido:
///   - `_createChild` montava `builder: (ctx, state) => childRoute.child(ctx, state)`
///     diretamente no GoRoute. Esse callback é chamado a cada rebuild do GoRouter.
///   - Se a closure contiver `Modular.get<FactoryBind>()`, cada rebuild cria
///     uma nova instância, descartando silenciosamente o cubit/state anterior.
///
/// Correção:
///   - O builder do GoRoute deve envolver a closure num widget StatefulWidget
///     (`_OnceBuilder`) que chama o builder apenas na primeira renderização
///     e cacheia o resultado para todos os rebuilds subsequentes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/widgets/once_builder.dart';

void main() {
  group('OnceBuilder', () {
    testWidgets(
      'builder é chamado apenas uma vez — mesmo após rebuild do pai',
      (tester) async {
        int buildCount = 0;
        final controller = ValueNotifier<int>(0);

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<int>(
              valueListenable: controller,
              builder: (context, _, __) => OnceBuilder(
                builder: (ctx) {
                  buildCount++;
                  return const Text('page');
                },
              ),
            ),
          ),
        );

        expect(buildCount, 1);

        // Simula rebuild do pai (hot-reload / setState externo)
        controller.value = 1;
        await tester.pump();

        expect(buildCount, 1, reason: 'builder não deve ser chamado em rebuilds');
      },
    );

    testWidgets(
      'builder é chamado novamente quando OnceBuilder é removido e re-inserido',
      (tester) async {
        int buildCount = 0;
        final show = ValueNotifier<bool>(true);

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (context, visible, __) => visible
                  ? OnceBuilder(builder: (_) {
                      buildCount++;
                      return const Text('page');
                    })
                  : const SizedBox(),
            ),
          ),
        );

        expect(buildCount, 1);

        // Remove da árvore
        show.value = false;
        await tester.pump();

        // Re-insere — deve criar um novo OnceBuilder state → novo build
        show.value = true;
        await tester.pump();

        expect(buildCount, 2,
            reason: 'nova inserção na árvore deve chamar o builder novamente');
      },
    );
  });
}
