import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// `registerBatch` indexes typed binds in `bindsMap` up front, so factories
/// inside the batch can `i.get<Dep>()` regardless of declaration order without
/// extra constructions — the same pattern as `AppModule` declaring a singleton
/// that depends on a type provided by an imported module.
class _Dependency {
  static int constructions = 0;
  _Dependency() {
    constructions++;
  }
}

class _Depender {
  static int constructions = 0;
  final _Dependency d;
  _Depender(this.d) {
    constructions++;
  }
}

void main() {
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    _Dependency.constructions = 0;
    _Depender.constructions = 0;
  });

  tearDown(Bind.clearAll);

  test(
    'declaration order inside a batch does not multiply singleton constructions',
    () {
      injector.startRegistering();
      injector.addSingleton((i) => _Depender(i.get<_Dependency>()));
      injector.addSingleton((i) => _Dependency());
      final binds = injector.finishRegistering();

      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      expect(_Dependency.constructions, 1);
      expect(_Depender.constructions, 1);
      expect(Bind.get<_Depender>().d, isA<_Dependency>());
    },
  );
}
