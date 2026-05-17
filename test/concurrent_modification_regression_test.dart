import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Regression: `BindLocator._searchCompatibleBind` walked the live
/// `bindsMap.entries` view. When a candidate's factory probe recursively
/// triggered another compatibility search that wrote into `bindsMap`, the
/// outer iterator's next `moveNext()` raised `ConcurrentModificationError`.
///
/// Reproduction relies on a factory-bound (uncached) candidate so that
/// `_candidateProducesT` actually invokes its factory probe instead of
/// short-circuiting on `cachedInstance`.
abstract interface class _IUserApi {
  String get who;
}

abstract interface class _ITaxApi {
  double get rate;
}

class _UserApiImpl implements _IUserApi {
  @override
  final String who = 'user';
}

class _TaxApiImpl implements _ITaxApi {
  @override
  final double rate = 0.1;
}

/// Probe candidate. Registered as a **factory** (not a singleton) so that
/// `_candidateProducesT` cannot short-circuit on `cachedInstance` and must
/// invoke the factory probe — which mutates `bindsMap` via
/// `i.get<_ITaxApi>()`.
class _ProbingCandidate {
  final _ITaxApi tax;
  _ProbingCandidate(this.tax);
}

void main() {
  final injector = Injector();

  setUp(Bind.clearAll);
  tearDown(Bind.clearAll);

  test(
    'nested compatibility lookup during candidate probe does not raise ConcurrentModificationError',
    () {
      injector.startRegistering();

      // Probe candidate appears FIRST in bindsMap insertion order so the
      // outer compat search visits it before the real `_IUserApi` impl.
      // Registered as a factory: no cached instance → probe runs the factory.
      injector.add((i) => _ProbingCandidate(i.get<_ITaxApi>()));

      // Real implementation registered after the probe candidate. The outer
      // iterator must `moveNext()` past the probe (after its mutation) to
      // reach this entry.
      injector.addSingleton((i) => _UserApiImpl());

      // Concrete singleton: only reachable via interface compat search.
      injector.addSingleton((i) => _TaxApiImpl());

      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      // First lookup forces the outer compat search. The probe candidate's
      // factory triggers `i.get<_ITaxApi>()`, whose nested compat search
      // writes `bindsMap[_ITaxApi]` while the outer iterator is mid-loop.
      final user = Bind.get<_IUserApi>();
      expect(user.who, 'user');
    },
  );
}
