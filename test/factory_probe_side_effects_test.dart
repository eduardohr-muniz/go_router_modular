import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/shared/exception.dart';

/// Compatibility search MUST cache singleton probes — re-running a singleton
/// factory on every interface lookup would silently break singleton identity
/// and (when the constructor has side effects: stream subscriptions, event
/// listeners, HTTP calls) flood the system with duplicated work.
///
/// Factory binds, by definition, build a fresh instance per call — so the
/// probe instance can't be reused. They're still probed, but the loop
/// protection (`BindSearchProtection.pushInvocation` / `isBlocked`) prevents
/// the cascading re-invocation that previously caused production freezes.
class _SideEffectful {
  static int constructed = 0;
  _SideEffectful() {
    constructed++;
  }
}

abstract interface class _IUnrelated {
  String get name;
}

class _UnrelatedConcrete implements _IUnrelated {
  @override
  final String name = 'concrete';
}

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    _SideEffectful.constructed = 0;
  });
  tearDown(Bind.clearAll);

  test(
    'compat search resolves interfaces against singleton concretes',
    () {
      injector.startRegistering();
      injector.addSingleton((i) => _UnrelatedConcrete());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final via = Bind.get<_IUnrelated>();
      expect(via, isA<_UnrelatedConcrete>());
      expect(via.name, 'concrete');
    },
  );

  test(
    'singleton probe is cached; multiple compat lookups do not re-invoke the factory',
    () {
      injector.startRegistering();
      injector.addSingleton<_SideEffectful>((i) => _SideEffectful());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final afterCommit = _SideEffectful.constructed;
      expect(afterCommit, 1, reason: 'eager singleton built once during commit');

      for (var i = 0; i < 5; i++) {
        expect(() => Bind.get<_IUnrelated>(),
            throwsA(isA<GoRouterModularException>()));
      }

      expect(_SideEffectful.constructed, afterCommit,
          reason: 'cached singleton must not be rebuilt by probes');
    },
  );

  test(
    'singleton probe-built instance preserves identity (concrete and interface return the same instance)',
    () {
      injector.startRegistering();
      // Untyped singleton — bindsMap initially indexes only the discovered
      // runtime type. The first interface lookup must probe, then cache.
      injector.addSingleton((i) => _UnrelatedConcrete());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final viaConcrete = Bind.get<_UnrelatedConcrete>();
      final viaInterface = Bind.get<_IUnrelated>();
      expect(identical(viaConcrete, viaInterface), isTrue,
          reason: 'interface lookup must reuse the canonical singleton');
    },
  );
}
