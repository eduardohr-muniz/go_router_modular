import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// The supported pattern for "factory bind reachable through an interface":
/// **type the factory with the interface explicitly**.
///
///   ```dart
///   i.addFactory<IService>((i) => ServiceImpl());
///   i.get<IService>(); // ✅
///   ```
///
/// This indexes the bind directly under `IService` in `bindsMap` (Strategy 2),
/// so `get<IService>` is an O(1) lookup with zero probe — the factory only
/// runs when the user actually consumes an instance.
///
/// The untyped form (`addFactory((i) => Impl())` + `get<IInterface>()`) is
/// **no longer supported**: probing factories to discover interface
/// relationships ran the constructor's side effects spuriously. Migrate by
/// typing the factory or registering the concrete as a singleton.
class _ServiceImpl implements _IService {
  static int constructed = 0;
  _ServiceImpl() {
    constructed++;
  }

  @override
  String get name => 'service-impl';
}

abstract interface class _IService {
  String get name;
}

abstract interface class _IUnrelated {}

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    _ServiceImpl.constructed = 0;
  });
  tearDown(Bind.clearAll);

  group('typed factory + interface lookup', () {
    test('addFactory<IService>((i) => Impl()) resolves via get<IService>', () {
      injector.startRegistering();
      injector.addFactory<_IService>((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final s = Bind.get<_IService>();
      expect(s, isA<_ServiceImpl>());
      expect(s.name, 'service-impl');
    });

    test('typed factory is NOT built during commit (still lazy)', () {
      injector.startRegistering();
      injector.addFactory<_IService>((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(_ServiceImpl.constructed, 0,
          reason: 'factory must not be invoked until a real get happens');
    });

    test('factory semantics preserved: each get<IService> builds a new instance', () {
      injector.startRegistering();
      injector.addFactory<_IService>((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final a = Bind.get<_IService>();
      final b = Bind.get<_IService>();
      expect(identical(a, b), isFalse,
          reason: 'factory binds must produce a fresh instance per call');
      expect(_ServiceImpl.constructed, 2);
    });

    test('unrelated lookups do not invoke a typed factory', () {
      injector.startRegistering();
      injector.addFactory<_IService>((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(() => Bind.get<_IUnrelated>(),
          throwsA(isA<GoRouterModularException>()));

      expect(_ServiceImpl.constructed, 0);
    });
  });

  group('untyped factory: resolves via interface without phantom instances', () {
    test('addFactory((i) => Impl()) + get<IService> resolves (no phantom, no breaking change)', () {
      injector.startRegistering();
      // T is inferred as _ServiceImpl; bind is Bind<_ServiceImpl>.
      // The declared type is checked via <_ServiceImpl>[] is List<_IService>
      // — no factory invocation needed to discover compatibility.
      injector.add((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      // Must resolve without throwing — no breaking change.
      final svc = Bind.get<_IService>();
      expect(svc, isA<_ServiceImpl>());
      // Factory invoked exactly once (for the real lookup, not a phantom probe).
      expect(_ServiceImpl.constructed, 1);
    });

    test('untyped factory still resolves via its concrete type (no probe needed)', () {
      injector.startRegistering();
      injector.add((i) => _ServiceImpl());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final s = Bind.get<_ServiceImpl>();
      expect(s, isA<_ServiceImpl>());
      expect(_ServiceImpl.constructed, 1);
    });
  });
}
