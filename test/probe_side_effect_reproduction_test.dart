import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/shared/exception.dart';

/// Regression: compatibility search must NOT invoke a factory bind's factory
/// just to type-check it. Pre-fix behavior built a phantom instance with all
/// the constructor's side effects (event publication, stream subscription,
/// HTTP) every time an unrelated `get<IInterface>()` was issued — even when
/// the factory had no relation to the requested type.
///
/// Confirmed reproduction counts (before the fix):
///   * 1 factory bind, 1 unrelated `get<IInterface>` → 1 phantom build
///   * 2 factory binds                                → 2 phantom builds
///   * 1 factory bind × 5 unrelated lookups           → 5 phantom builds
///
/// Post-fix expectation: count stays 0 forever. Only the legitimate
/// `get<ConcreteType>` invokes the factory.
class _SideEffectfulCubit {
  static int constructed = 0;
  static final List<String> sideEffectsLog = [];

  _SideEffectfulCubit() {
    constructed++;
    sideEffectsLog.add('cubit-built-$constructed');
  }
}

class _AnotherFactoryBind {
  static int constructed = 0;
  _AnotherFactoryBind() {
    constructed++;
  }
}

abstract interface class _IUnregistered {
  String get name;
}

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    _SideEffectfulCubit.constructed = 0;
    _SideEffectfulCubit.sideEffectsLog.clear();
    _AnotherFactoryBind.constructed = 0;
  });
  tearDown(Bind.clearAll);

  group('factory bind probe must not run constructor for unrelated lookups', () {
    test('single factory bind: get<IUnregistered> does NOT invoke factory', () {
      injector.startRegistering();
      injector.add<_SideEffectfulCubit>((i) => _SideEffectfulCubit());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(_SideEffectfulCubit.constructed, 0, reason: 'baseline: factory not built during commitBatch');

      expect(() => Bind.get<_IUnregistered>(), throwsA(isA<ModularException>()));

      expect(_SideEffectfulCubit.constructed, 0, reason: 'factory must NOT be invoked for unrelated interface lookup');
      expect(_SideEffectfulCubit.sideEffectsLog, isEmpty, reason: 'no constructor side effects must leak');
    });

    test('multiple factory binds: NONE are invoked for unrelated lookup', () {
      injector.startRegistering();
      injector.add<_SideEffectfulCubit>((i) => _SideEffectfulCubit());
      injector.add<_AnotherFactoryBind>((i) => _AnotherFactoryBind());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(() => Bind.get<_IUnregistered>(), throwsA(isA<ModularException>()));

      expect(_SideEffectfulCubit.constructed, 0);
      expect(_AnotherFactoryBind.constructed, 0);
    });

    test('repeated unrelated lookups: factory still never invoked', () {
      injector.startRegistering();
      injector.add<_SideEffectfulCubit>((i) => _SideEffectfulCubit());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      for (var i = 0; i < 5; i++) {
        try {
          Bind.get<_IUnregistered>();
        } catch (_) {}
      }

      expect(_SideEffectfulCubit.constructed, 0, reason: 'cumulative side-effect leak across calls must be zero');
    });

    test('factory IS invoked for its own type lookup (sanity)', () {
      injector.startRegistering();
      injector.add<_SideEffectfulCubit>((i) => _SideEffectfulCubit());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final cubit = Bind.get<_SideEffectfulCubit>();
      expect(cubit, isA<_SideEffectfulCubit>());
      expect(_SideEffectfulCubit.constructed, 1, reason: 'factory still works for legitimate gets by its declared type');

      // Factory semantics: each get builds a new instance.
      Bind.get<_SideEffectfulCubit>();
      expect(_SideEffectfulCubit.constructed, 2);
    });
  });
}
