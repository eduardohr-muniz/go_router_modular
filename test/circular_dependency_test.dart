import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Cross-type circular dependencies must surface a clear, actionable error
/// instead of being masked as "Bind not found" or silently looping.
///
/// The previous `hasBlockedBinds` global bypass in
/// `BindLocator._validateCanStartSearch` allowed *any* recursive `i.get<T>()`
/// to skip the `currentlySearching` check whenever any factory was on the
/// stack. That hid real circular dependencies behind a generic NotFound at
/// the deepest probe level.
class _A {
  final _B b;
  _A(this.b);
}

class _B {
  final _A a;
  _B(this.a);
}

void main() {
  final injector = Injector();

  setUp(Bind.clearAll);
  tearDown(Bind.clearAll);

  test('cross-type circular dependency throws GoRouterModularException with "circular" in message', () {
    injector.startRegistering();
    injector.addSingleton<_A>((i) => _A(i.get<_B>()));
    injector.addSingleton<_B>((i) => _B(i.get<_A>()));
    final binds = injector.finishRegistering();

    Bind.registerBatch(binds);
    Bind.commitBatch(injector); // swallowed, leaves cache empty

    expect(
      () => Bind.get<_A>(),
      throwsA(
        isA<GoRouterModularException>().having(
          (e) => e.toString().toLowerCase(),
          'message',
          contains('circular'),
        ),
      ),
    );
  });

  test('self-reference (addFactory<I>((i) => i.get())) still works after tightened bypass', () {
    injector.startRegistering();
    injector.addSingleton<_SelfRefImpl>((i) => _SelfRefImpl());
    injector.addFactory<_ISelfRef>((i) => i.get());
    final binds = injector.finishRegistering();

    Bind.registerBatch(binds);
    Bind.commitBatch(injector);

    final via = Bind.get<_ISelfRef>();
    expect(via, isA<_SelfRefImpl>());
  });
}

abstract interface class _ISelfRef {
  String get tag;
}

class _SelfRefImpl implements _ISelfRef {
  @override
  final String tag = 'self-ref-impl';
}
