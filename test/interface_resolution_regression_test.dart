import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Regression: a concrete singleton registered without an explicit generic
/// (e.g. `i.addSingleton((i) => AuthApiImpl())`) must still resolve through
/// the abstraction (`i.get<IAuthApi>()`).
///
/// The compatibility search in `BindLocator` iterates `bindsMap.entries`,
/// runs the factory, and accepts the bind when the produced instance
/// matches the requested interface. For that to work, the **runtime type**
/// of every registered singleton must end up indexed in `bindsMap` after
/// `commitBatch`.
abstract interface class IAuthApi {
  String get name;
}

class AuthApiImpl implements IAuthApi {
  @override
  String get name => 'auth-api-impl';
}

class AuthEmailCubit {
  final IAuthApi api;
  AuthEmailCubit(this.api);
}

void main() {
  final injector = Injector();

  setUp(Bind.clearAll);
  tearDown(Bind.clearAll);

  test('untyped concrete singleton resolves through its interface via compatibility search', () {
    injector.startRegistering();
    injector.addSingleton((i) => AuthApiImpl());
    final binds = injector.finishRegistering();

    Bind.registerBatch(binds);
    Bind.commitBatch(injector);

    final api = Bind.get<IAuthApi>();
    expect(api, isA<AuthApiImpl>());
    expect(api.name, 'auth-api-impl');
  });

  test('downstream module factory consumes interface registered concretely upstream', () {
    injector.startRegistering();
    injector.addSingleton((i) => AuthApiImpl());
    final upstream = injector.finishRegistering();
    Bind.registerBatch(upstream);
    Bind.commitBatch(injector);

    injector.startRegistering();
    injector.addSingleton((i) => AuthEmailCubit(i.get<IAuthApi>()));
    final downstream = injector.finishRegistering();
    Bind.registerBatch(downstream);
    Bind.commitBatch(injector);

    final cubit = Bind.get<AuthEmailCubit>();
    expect(cubit.api, isA<AuthApiImpl>());
  });

  test('typed singleton resolves both as interface and as concrete', () {
    injector.startRegistering();
    injector.addSingleton<IAuthApi>((i) => AuthApiImpl());
    final binds = injector.finishRegistering();
    Bind.registerBatch(binds);
    Bind.commitBatch(injector);

    final asInterface = Bind.get<IAuthApi>();
    final asConcrete = Bind.get<AuthApiImpl>();
    expect(identical(asInterface, asConcrete), isTrue,
        reason: 'singleton must yield the same instance regardless of lookup type');
  });

  test(
    'compatibility lookup preserves singleton identity across interface and concrete',
    () {
      injector.startRegistering();
      injector.addSingleton((i) => AuthApiImpl());
      final binds = injector.finishRegistering();
      Bind.registerBatch(binds);
      Bind.commitBatch(injector);

      final viaConcrete = Bind.get<AuthApiImpl>();
      final viaInterfaceFirst = Bind.get<IAuthApi>();
      final viaInterfaceSecond = Bind.get<IAuthApi>();

      expect(identical(viaInterfaceFirst, viaInterfaceSecond), isTrue,
          reason: 'every interface lookup must yield the same singleton');
      expect(identical(viaInterfaceFirst, viaConcrete), isTrue,
          reason: 'interface lookup must reuse the canonical singleton, not a wrapper');
    },
  );
}
