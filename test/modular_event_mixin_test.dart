import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/events/modular_event.dart';

// ─── Eventos de teste ───────────────────────────────────────────────────────

class CounterEvent {
  final int value;
  const CounterEvent(this.value);
}

class LabelEvent {
  final String text;
  const LabelEvent(this.text);
}

// ─── Widget auxiliar genérico ────────────────────────────────────────────────

/// Permite injetar um callback de setup no initState para cada teste.
class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.setup, super.key});

  final void Function(_TestWidgetState state) setup;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> with ModularEventMixin {
  final List<int> counters = [];
  final List<String> labels = [];
  BuildContext? lastContext;

  @override
  void initState() {
    super.initState();
    widget.setup(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _wrap(_TestWidget widget) => MaterialApp(home: Scaffold(body: widget));

// ─── Testes ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    clearEventModuleState();
  });

  group('StatefulEventListenerMixin', () {
    // ── 1. Recebe evento registrado com on<T> ──────────────────────────────
    testWidgets(
      'deve receber evento registrado com on<T>',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>((event, ctx) {
                state.counters.add(event.value);
              });
            },
          )),
        );

        ModularEvent.fire(CounterEvent(42));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(_TestWidget), findsOneWidget);
        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        expect(state.counters, equals([42]));
      },
    );

    // ── 2. Cancela subscriptions no dispose ───────────────────────────────
    testWidgets(
      'deve cancelar todas as subscriptions automaticamente no dispose',
      (tester) async {
        final received = <int>[];

        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>((event, ctx) {
                received.add(event.value);
              });
            },
          )),
        );

        ModularEvent.fire(CounterEvent(1));
        await tester.pump(const Duration(milliseconds: 50));
        expect(received, equals([1]));

        // Remove o widget → chama dispose
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));

        ModularEvent.fire(CounterEvent(99));
        await tester.pump(const Duration(milliseconds: 50));

        // Após dispose, não deve receber mais eventos
        expect(received, equals([1]));
      },
    );

    // ── 3. Substitui listener ao registrar o mesmo tipo duas vezes ─────────
    testWidgets(
      'deve substituir listener ao registrar o mesmo tipo duas vezes',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>((event, ctx) {
                state.counters.add(-1); // listener antigo – nunca deve chegar
              });
              state.on<CounterEvent>((event, ctx) {
                state.counters.add(event.value); // listener novo
              });
            },
          )),
        );

        ModularEvent.fire(CounterEvent(7));
        await tester.pump(const Duration(milliseconds: 50));

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        // Apenas o segundo listener deve ter recebido
        expect(state.counters, equals([7]));
      },
    );

    // ── 4. Múltiplos tipos de eventos independentes ────────────────────────
    testWidgets(
      'deve suportar múltiplos tipos de eventos independentes',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>((event, ctx) {
                state.counters.add(event.value);
              });
              state.on<LabelEvent>((event, ctx) {
                state.labels.add(event.text);
              });
            },
          )),
        );

        ModularEvent.fire(CounterEvent(10));
        ModularEvent.fire(LabelEvent('hello'));
        await tester.pump(const Duration(milliseconds: 50));

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        expect(state.counters, equals([10]));
        expect(state.labels, equals(['hello']));
      },
    );

    // ── 5. EventBus customizado ───────────────────────────────────────────
    testWidgets(
      'deve isolar eventos quando um EventBus customizado é usado',
      (tester) async {
        final customBus = EventBus();

        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>(
                (event, ctx) => state.counters.add(event.value),
                eventBus: customBus,
              );
            },
          )),
        );

        // Evento no bus global → não deve chegar ao widget
        ModularEvent.fire(CounterEvent(1));
        await tester.pump(const Duration(milliseconds: 50));

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        expect(state.counters, isEmpty);

        // Evento no bus customizado → deve chegar
        customBus.fire(CounterEvent(2));
        await tester.pump(const Duration(milliseconds: 50));

        expect(state.counters, equals([2]));
      },
    );

    // ── 6. exclusive=true cria broadcast stream ───────────────────────────
    testWidgets(
      'deve suportar exclusive=true (broadcast stream)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>(
                (event, ctx) => state.counters.add(event.value),
                exclusive: true,
              );
            },
          )),
        );

        ModularEvent.fire(CounterEvent(5));
        await tester.pump(const Duration(milliseconds: 50));

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
        expect(state.counters, equals([5]));
      },
    );

    // ── 7. Context é passado ao callback quando widget está montado ────────
    testWidgets(
      'deve passar context não-nulo ao callback quando widget está montado',
      (tester) async {
        BuildContext? capturedCtx;

        await tester.pumpWidget(
          _wrap(_TestWidget(
            setup: (state) {
              state.on<CounterEvent>((event, ctx) {
                capturedCtx = ctx;
              });
            },
          )),
        );

        ModularEvent.fire(CounterEvent(1));
        await tester.pump(const Duration(milliseconds: 50));

        // O widget ainda está montado, contexto deve ser não-nulo
        expect(capturedCtx, isNotNull);
      },
    );

    // ── 8. Registrar on<T> após initState (em resposta a ação) ────────────
    testWidgets(
      'deve funcionar ao registrar on<T> fora do initState',
      (tester) async {
        final state_key = GlobalKey<_TestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestWidget(key: state_key, setup: (_) {}),
            ),
          ),
        );

        // Registrar listener depois que o widget já está montado
        state_key.currentState!.on<LabelEvent>(
          (event, ctx) => state_key.currentState!.labels.add(event.text),
        );

        ModularEvent.fire(LabelEvent('late-register'));
        await tester.pump(const Duration(milliseconds: 50));

        expect(state_key.currentState!.labels, equals(['late-register']));
      },
    );
  });
}
