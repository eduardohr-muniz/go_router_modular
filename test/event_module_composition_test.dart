import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/shared/setup.dart';

class HostEvent {
  final String message;
  const HostEvent(this.message);
}

class ChildEvent {
  final String message;
  const ChildEvent(this.message);
}

class ChildEventModule extends EventModule {
  ChildEventModule(this.receivedMessages);

  final List<String> receivedMessages;

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => Container()),
      ];

  @override
  void listen() {
    on<ChildEvent>((event, context) => receivedMessages.add(event.message));
  }
}

class HostEventModule extends EventModule {
  HostEventModule({required this.childMessages, required this.hostMessages});

  final List<String> childMessages;
  final List<String> hostMessages;

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => Container()),
      ];

  @override
  void listen() {
    on<HostEvent>((event, context) => hostMessages.add(event.message));
    ChildEventModule(childMessages).listen();
  }
}

class NoListenEventModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => Container()),
      ];
}

class LifecycleOrderEventModule extends EventModule {
  final List<String> calls;

  LifecycleOrderEventModule(this.calls);

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, state) => Container()),
      ];

  @override
  void listen() => calls.add('listen');

  @override
  void onAfterListen() => calls.add('onAfterListen');
}

class MockInjector extends Injector {
  @override
  T get<T>({String? key}) => throw UnimplementedError();
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Composição de EventModule via listen()', () {
    setUp(() {
      clearEventModuleState();
      try {
        modularNavigatorKey.currentContext;
      } catch (_) {
        modularNavigatorKey = GlobalKey<NavigatorState>();
      }
      SetupModular.instance.setDebugModel(SetupModel(
        debugLogEventBus: false,
        debugLogGoRouter: false,
        autoDisposeEvents: true,
        debugLogGoRouterModular: false,
      ));
    });

    test('ouvinte composto recebe eventos no barramento do host e é descartado junto com o host', () async {
      final childMessages = <String>[];
      final hostMessages = <String>[];
      final host = HostEventModule(childMessages: childMessages, hostMessages: hostMessages);
      host.initState(MockInjector());

      ModularEvent.fire(const HostEvent('host-1'));
      ModularEvent.fire(const ChildEvent('child-1'));
      await _settle();

      expect(hostMessages, ['host-1']);
      expect(childMessages, ['child-1']);

      host.dispose();

      ModularEvent.fire(const HostEvent('host-2'));
      ModularEvent.fire(const ChildEvent('child-2'));
      await _settle();

      expect(hostMessages, ['host-1']);
      expect(childMessages, ['child-1']);
    });

    test('recriar o host (init → dispose → init) não duplica ouvintes compostos', () async {
      final childMessages = <String>[];

      final firstHost = HostEventModule(childMessages: childMessages, hostMessages: []);
      firstHost.initState(MockInjector());
      firstHost.dispose();

      final secondHost = HostEventModule(childMessages: childMessages, hostMessages: []);
      secondHost.initState(MockInjector());

      ModularEvent.fire(const ChildEvent('only-once'));
      await _settle();

      expect(childMessages, ['only-once']);

      secondHost.dispose();
    });

    test('listen() chamado sem host ativo usa o escopo próprio da instância', () async {
      final childMessages = <String>[];
      final child = ChildEventModule(childMessages);

      child.listen();

      ModularEvent.fire(const ChildEvent('own-scope'));
      await _settle();

      expect(childMessages, ['own-scope']);

      child.dispose();

      ModularEvent.fire(const ChildEvent('after-dispose'));
      await _settle();

      expect(childMessages, ['own-scope']);
    });

    test('initState executa listen() antes de onAfterListen()', () {
      final calls = <String>[];
      final module = LifecycleOrderEventModule(calls);

      module.initState(MockInjector());

      expect(calls, ['listen', 'onAfterListen']);

      module.dispose();
    });

    test('EventModule sem listen() sobrescrito inicializa sem registrar ouvintes', () {
      final module = NoListenEventModule();

      expect(() => module.initState(MockInjector()), returnsNormally);

      module.dispose();
    });

    test('re-registrar exclusive do mesmo tipo no mesmo módulo cancela a assinatura ativa anterior', () async {
      final module = ChildEventModule([]);
      module.initState(MockInjector());

      final firstCalls = <String>[];
      final secondCalls = <String>[];

      module.on<HostEvent>((event, context) => firstCalls.add(event.message), exclusive: true);
      module.on<HostEvent>((event, context) => secondCalls.add(event.message), exclusive: true);

      ModularEvent.fire(const HostEvent('exclusive'));
      await _settle();

      expect(firstCalls, isEmpty);
      expect(secondCalls, ['exclusive']);

      module.dispose();
    });

    test('ModularEvent.on com exclusive=true recebe o evento no barramento global', () async {
      final received = <String>[];

      ModularEvent.instance.on<HostEvent>((event, context) => received.add(event.message), exclusive: true);

      ModularEvent.fire(const HostEvent('global-exclusive'));
      await _settle();

      expect(received, ['global-exclusive']);

      ModularEvent.instance.dispose<HostEvent>();
    });
  });
}
