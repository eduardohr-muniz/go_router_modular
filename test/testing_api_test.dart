/// TDD tests for the go_router_modular testing API.
///
/// Object Calisthenics applied:
///   - Primitives wrapped in value objects (MoneyAmount, OrderId)
///   - First-class collections (RecordedEventList)
///   - Small, single-responsibility domain objects in helpers
///   - No abbreviations in production code (test helpers may use short names)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/testing.dart';

// ─── Domain value objects (avoid primitive obsession) ────────────────────────

class MoneyAmount {
  final int cents;
  const MoneyAmount(this.cents);

  @override
  bool operator ==(Object other) => other is MoneyAmount && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;
}

class OrderId {
  final int value;
  const OrderId(this.value);
}

// ─── Domain events ────────────────────────────────────────────────────────────

class PaymentProcessedEvent {
  final MoneyAmount amount;
  const PaymentProcessedEvent(this.amount);
}

class OrderPlacedEvent {
  final OrderId orderId;
  const OrderPlacedEvent(this.orderId);
}

class InventoryUpdatedEvent {
  final int quantity;
  const InventoryUpdatedEvent(this.quantity);
}

// ─── Domain interfaces and fakes ──────────────────────────────────────────────

abstract interface class PaymentGateway {
  bool charge(MoneyAmount amount);
}

class FakePaymentGateway implements PaymentGateway {
  MoneyAmount? _lastCharged;

  @override
  bool charge(MoneyAmount amount) {
    _lastCharged = amount;
    return true;
  }

  MoneyAmount? lastCharged() => _lastCharged;
}

abstract interface class UserRepository {
  String findUsername(int userId);
}

class FakeUserRepository implements UserRepository {
  @override
  String findUsername(int userId) => 'user_$userId';
}

class AlwaysEmptyUserRepository implements UserRepository {
  @override
  String findUsername(int userId) => '';
}

// ─── Domain service ───────────────────────────────────────────────────────────

class OrderService {
  final PaymentGateway _gateway;
  final UserRepository _repository;

  OrderService(this._gateway, this._repository);

  bool processOrder(int userId, MoneyAmount amount) {
    final username = _repository.findUsername(userId);
    if (username.isEmpty) return false;
    return _gateway.charge(amount);
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ══════════════════════════════════════════════════════════════════════════
  // ModularTestScope — DI
  // ══════════════════════════════════════════════════════════════════════════

  group('ModularTestScope', () {
    group('DI — registerInstance', () {
      late ModularTestScope scope;

      setUp(() {
        scope = ModularTestScope.fresh();
        scope.setUp();
      });

      tearDown(() => scope.tearDown());

      test('deve resolver instância registrada via registerInstance', () {
        final gateway = FakePaymentGateway();
        scope.registerInstance<PaymentGateway>(gateway);

        expect(scope.get<PaymentGateway>(), same(gateway));
      });

      test('deve resolver factory registrada via registerFactory', () {
        // Bind.register chama a factory uma vez para descobrir o tipo em runtime.
        // O teste verifica que cada get() retorna uma instância diferente (identidade).
        scope.registerFactory<Object>(() => Object());

        final first = scope.get<Object>();
        final second = scope.get<Object>();

        expect(first, isNot(same(second)));
      });

      test('deve resolver lazy singleton via registerLazySingleton', () {
        int counter = 0;
        scope.registerLazySingleton<int>(() => ++counter);

        expect(scope.get<int>(), equals(1));
        expect(scope.get<int>(), equals(1));
      });

      test('isRegistered retorna true para tipo registrado', () {
        scope.registerInstance<String>('hello');

        expect(scope.isRegistered<String>(), isTrue);
      });

      test('isRegistered retorna false para tipo não registrado', () {
        expect(scope.isRegistered<DateTime>(), isFalse);
      });

      test('dois tipos distintos são resolvidos independentemente', () {
        scope.registerInstance<PaymentGateway>(FakePaymentGateway());
        scope.registerInstance<UserRepository>(FakeUserRepository());

        expect(scope.get<PaymentGateway>(), isA<FakePaymentGateway>());
        expect(scope.get<UserRepository>(), isA<FakeUserRepository>());
      });
    });

    // ── Template (pre-setUp fluent configuration) ─────────────────────────

    group('DI — template (withInstance/withFactory)', () {
      test('template configurado antes do setUp é aplicado no setUp', () {
        final gateway = FakePaymentGateway();
        final scope = ModularTestScope.fresh().withInstance<PaymentGateway>(gateway);

        scope.setUp();

        expect(scope.get<PaymentGateway>(), same(gateway));

        scope.tearDown();
      });

      test('withInstance retorna novo scope (imutável por template)', () {
        final original = ModularTestScope.fresh();
        final configured = original.withInstance<String>('value');

        configured.setUp();
        expect(configured.isRegistered<String>(), isTrue);
        configured.tearDown();

        original.setUp();
        expect(original.isRegistered<String>(), isFalse);
        original.tearDown();
      });

      test('template com withFactory resolve novo valor a cada get', () {
        // Bind.register chama a factory uma vez para descobrir o tipo em runtime.
        // O teste verifica identidade: cada get() deve retornar instância diferente.
        final scope = ModularTestScope.fresh().withFactory<Object>(() => Object());

        scope.setUp();

        final first = scope.get<Object>();
        final second = scope.get<Object>();

        expect(first, isNot(same(second)));

        scope.tearDown();
      });

      test('template com withLazySingleton resolve mesma instância', () {
        int counter = 0;
        final scope =
            ModularTestScope.fresh().withLazySingleton<int>(() => ++counter);

        scope.setUp();

        expect(scope.get<int>(), equals(1));
        expect(scope.get<int>(), equals(1));

        scope.tearDown();
      });

      test('template é reaplicado a cada setUp/tearDown', () {
        final scope =
            ModularTestScope.fresh().withInstance<String>('persistent');

        scope.setUp();
        expect(scope.isRegistered<String>(), isTrue);
        scope.tearDown();

        scope.setUp();
        expect(scope.isRegistered<String>(), isTrue);
        scope.tearDown();
      });

      test('tearDown limpa todos os registros', () {
        final scope = ModularTestScope.fresh();
        scope.setUp();
        scope.registerInstance<String>('temp');
        expect(scope.isRegistered<String>(), isTrue);

        scope.tearDown();
        expect(scope.isRegistered<String>(), isFalse);
      });
    });

    // ── Eventos ───────────────────────────────────────────────────────────

    group('eventos — fireEvent / eventsOf / listenFor', () {
      late ModularTestScope scope;

      setUp(() {
        scope = ModularTestScope.fresh();
        scope.setUp();
        scope.listenFor<PaymentProcessedEvent>();
      });

      tearDown(() => scope.tearDown());

      test('fireEvent dispara e listenFor captura o evento', () async {
        scope.fireEvent(const PaymentProcessedEvent(MoneyAmount(500)));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(scope.eventsOf<PaymentProcessedEvent>().length, equals(1));
        expect(
          scope.eventsOf<PaymentProcessedEvent>()[0].amount,
          equals(const MoneyAmount(500)),
        );
      });

      test('eventsOf retorna lista vazia antes de qualquer evento', () {
        expect(scope.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);
      });

      test('eventos de outro tipo não contaminam o recorder', () async {
        scope.listenFor<OrderPlacedEvent>();
        scope.fireEvent(const OrderPlacedEvent(OrderId(1)));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(scope.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);
        expect(scope.eventsOf<OrderPlacedEvent>().length, equals(1));
      });

      test('clearRecordedEvents limpa apenas o histórico, mantém o listener',
          () async {
        scope.fireEvent(const PaymentProcessedEvent(MoneyAmount(100)));
        await Future.delayed(const Duration(milliseconds: 50));
        expect(scope.eventsOf<PaymentProcessedEvent>().length, equals(1));

        scope.clearRecordedEvents();

        expect(scope.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);

        scope.fireEvent(const PaymentProcessedEvent(MoneyAmount(200)));
        await Future.delayed(const Duration(milliseconds: 50));
        expect(scope.eventsOf<PaymentProcessedEvent>().length, equals(1));
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // EventRecorder
  // ══════════════════════════════════════════════════════════════════════════

  group('EventRecorder', () {
    late EventRecorder recorder;

    setUp(() {
      recorder = EventRecorder.fresh();
      recorder.listenFor<PaymentProcessedEvent>();
    });

    tearDown(() {
      recorder.dispose();
    });

    test('captura eventos do tipo registrado', () async {
      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(100)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(recorder.eventsOf<PaymentProcessedEvent>().length, equals(1));
    });

    test('não captura tipos não registrados', () async {
      ModularEventBus.fire(const OrderPlacedEvent(OrderId(9)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(recorder.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);
    });

    test('captura múltiplos eventos do mesmo tipo', () async {
      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(1)));
      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(2)));
      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(3)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(recorder.eventsOf<PaymentProcessedEvent>().length, equals(3));
    });

    test('captura múltiplos tipos quando listenFor é chamado para cada um',
        () async {
      recorder.listenFor<OrderPlacedEvent>();

      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(10)));
      ModularEventBus.fire(const OrderPlacedEvent(OrderId(42)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(recorder.eventsOf<PaymentProcessedEvent>().length, equals(1));
      expect(recorder.eventsOf<OrderPlacedEvent>().length, equals(1));
    });

    test('clear apaga eventos sem cancelar o listener', () async {
      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(5)));
      await Future.delayed(const Duration(milliseconds: 50));

      recorder.clear();
      expect(recorder.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);

      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(6)));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(recorder.eventsOf<PaymentProcessedEvent>().length, equals(1));
    });

    test('dispose para de gravar novos eventos', () async {
      recorder.dispose();

      ModularEventBus.fire(const PaymentProcessedEvent(MoneyAmount(99)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(recorder.eventsOf<PaymentProcessedEvent>().isEmpty, isTrue);
    });

    test('eventsOf retorna lista vazia para tipo nunca registrado', () {
      expect(recorder.eventsOf<InventoryUpdatedEvent>().isEmpty, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // RecordedEventList<E> — first-class collection
  // ══════════════════════════════════════════════════════════════════════════

  group('RecordedEventList', () {
    test('length retorna quantidade total de eventos', () {
      final events = RecordedEventList([
        const PaymentProcessedEvent(MoneyAmount(10)),
        const PaymentProcessedEvent(MoneyAmount(20)),
      ]);

      expect(events.length, equals(2));
    });

    test('isEmpty retorna true quando não há eventos', () {
      expect(RecordedEventList<PaymentProcessedEvent>.empty().isEmpty, isTrue);
    });

    test('isNotEmpty retorna true quando há ao menos um evento', () {
      expect(
        RecordedEventList([const PaymentProcessedEvent(MoneyAmount(1))]).isNotEmpty,
        isTrue,
      );
    });

    test('operator[] acessa evento por índice', () {
      final events = RecordedEventList([const PaymentProcessedEvent(MoneyAmount(42))]);

      expect(events[0].amount, equals(const MoneyAmount(42)));
    });

    test('any retorna true quando predicado é satisfeito', () {
      final events = RecordedEventList([
        const PaymentProcessedEvent(MoneyAmount(5)),
        const PaymentProcessedEvent(MoneyAmount(50)),
      ]);

      expect(events.any((e) => e.amount.cents > 10), isTrue);
    });

    test('any retorna false quando nenhum item satisfaz o predicado', () {
      final events = RecordedEventList([const PaymentProcessedEvent(MoneyAmount(5))]);

      expect(events.any((e) => e.amount.cents > 100), isFalse);
    });

    test('where filtra e retorna nova RecordedEventList', () {
      final events = RecordedEventList([
        const PaymentProcessedEvent(MoneyAmount(1)),
        const PaymentProcessedEvent(MoneyAmount(2)),
        const PaymentProcessedEvent(MoneyAmount(3)),
      ]);

      final filtered = events.where((e) => e.amount.cents > 1);

      expect(filtered.length, equals(2));
    });

    test('first retorna o primeiro evento', () {
      final events = RecordedEventList([
        const PaymentProcessedEvent(MoneyAmount(1)),
        const PaymentProcessedEvent(MoneyAmount(2)),
      ]);

      expect(events.first.amount, equals(const MoneyAmount(1)));
    });

    test('last retorna o último evento', () {
      final events = RecordedEventList([
        const PaymentProcessedEvent(MoneyAmount(1)),
        const PaymentProcessedEvent(MoneyAmount(2)),
      ]);

      expect(events.last.amount, equals(const MoneyAmount(2)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FakeInjector
  // ══════════════════════════════════════════════════════════════════════════

  group('FakeInjector', () {
    test('get retorna instância registrada com add', () {
      final gateway = FakePaymentGateway();
      final injector = FakeInjector.empty().add<PaymentGateway>(gateway);

      expect(injector.get<PaymentGateway>(), same(gateway));
    });

    test('add retorna novo injector sem modificar o original', () {
      final original = FakeInjector.empty();
      original.add<String>('value');

      expect(
        () => original.get<String>(),
        throwsA(isA<FakeInjectorMissingBindError>()),
      );
    });

    test('encadear add constrói injector com múltiplos tipos', () {
      final injector = FakeInjector.empty()
          .add<PaymentGateway>(FakePaymentGateway())
          .add<UserRepository>(FakeUserRepository());

      expect(injector.get<PaymentGateway>(), isA<FakePaymentGateway>());
      expect(injector.get<UserRepository>(), isA<FakeUserRepository>());
    });

    test('lança FakeInjectorMissingBindError para tipo não registrado', () {
      final injector = FakeInjector.empty();

      expect(
        () => injector.get<DateTime>(),
        throwsA(isA<FakeInjectorMissingBindError>()),
      );
    });

    test('FakeInjectorMissingBindError contém o tipo faltante na mensagem', () {
      try {
        FakeInjector.empty().get<DateTime>();
        fail('esperado lançar FakeInjectorMissingBindError');
      } on FakeInjectorMissingBindError catch (e) {
        expect(e.toString(), contains('DateTime'));
      }
    });

    test('pode ser usado como InjectorReader em módulos e serviços', () {
      final gateway = FakePaymentGateway();
      final repo = FakeUserRepository();

      final injector = FakeInjector.empty()
          .add<PaymentGateway>(gateway)
          .add<UserRepository>(repo);

      final service = OrderService(
        injector.get<PaymentGateway>(),
        injector.get<UserRepository>(),
      );

      expect(service.processOrder(1, const MoneyAmount(100)), isTrue);
      expect(gateway.lastCharged(), equals(const MoneyAmount(100)));
    });
  });
}
