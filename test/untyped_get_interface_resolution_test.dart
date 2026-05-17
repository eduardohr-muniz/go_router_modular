import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Regression real: numa aplicação o usuário escreveu
///
/// ```dart
/// ..addSingleton<ApiSearchAddressDatasource>(
///     (i) => ApiSearchAddressDatasource(searchAddressApi: i.get()))
/// ..addFactory<IAddressAutocompleteDatasource>((i) => i.get())
/// ..addFactory<IAddressPostcodeGeocodeDatasource>((i) => i.get())
/// ```
///
/// O `i.get()` sem generic infere o **mesmo tipo** que a factory está
/// produzindo (`IAddressAutocompleteDatasource` etc.) — então o lookup
/// recursivamente tenta resolver a si mesmo e o motor lança
/// `Too many search attempts` / `already being searched`.
///
/// A intenção do usuário era delegar a interface para a implementação
/// concreta (`ApiSearchAddressDatasource`) registrada no mesmo módulo.
/// Como o diferencial do pacote é "resolver para quem não tipa", o
/// `BindLocator` deve detectar a auto-referência, pular o próprio bind
/// e cair na busca de compatibilidade contra os outros binds presentes.

abstract interface class IAddressAutocompleteDatasource {
  String autocomplete(String q);
}

abstract interface class IAddressPostcodeGeocodeDatasource {
  String geocode(String postcode);
}

class ApiSearchAddressDatasource
    implements IAddressAutocompleteDatasource, IAddressPostcodeGeocodeDatasource {
  @override
  String autocomplete(String q) => 'autocomplete:$q';

  @override
  String geocode(String postcode) => 'geocode:$postcode';
}

abstract interface class IAuthApi {
  String get name;
}

class AuthApiImpl implements IAuthApi {
  @override
  String get name => 'auth-impl';
}

class AuthEmailCubit {
  final IAuthApi api;
  AuthEmailCubit(this.api);
}

class AddressModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i.addSingleton<ApiSearchAddressDatasource>((i) => ApiSearchAddressDatasource());
    // Estes são os binds problemáticos: i.get() sem generic infere o próprio
    // tipo da factory (interface), causando auto-referência.
    i.addFactory<IAddressAutocompleteDatasource>((i) => i.get());
    i.addFactory<IAddressPostcodeGeocodeDatasource>((i) => i.get());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final injector = Injector();

  setUp(() {
    Bind.clearAll();
    InjectionManager.instance.resetForTesting();
  });
  tearDown(() {
    Bind.clearAll();
    InjectionManager.instance.resetForTesting();
  });

  group('Self-referential i.get() should delegate to compatible concrete bind', () {
    test(
      'addFactory<Interface>((i) => i.get()) resolves to compatible concrete singleton (same module)',
      () {
        injector.startRegistering();
        injector.addSingleton<ApiSearchAddressDatasource>((i) => ApiSearchAddressDatasource());
        // i.get() infere IAddressAutocompleteDatasource — não deve loopar.
        injector.addFactory<IAddressAutocompleteDatasource>((i) => i.get());
        injector.addFactory<IAddressPostcodeGeocodeDatasource>((i) => i.get());
        final binds = injector.finishRegistering();

        Bind.registerBatch(binds);
        Bind.commitBatch(injector);

        final autocomplete = Bind.get<IAddressAutocompleteDatasource>();
        expect(autocomplete, isA<ApiSearchAddressDatasource>());
        expect(autocomplete.autocomplete('foo'), 'autocomplete:foo');

        final geocode = Bind.get<IAddressPostcodeGeocodeDatasource>();
        expect(geocode, isA<ApiSearchAddressDatasource>());
        expect(geocode.geocode('00000-000'), 'geocode:00000-000');
      },
    );

    test(
      'addFactory<Interface>((i) => i.get()) resolves via real Module (integration)',
      () async {
        await InjectionManager.instance.registerBindsModule(AddressModule());

        final autocomplete = Bind.get<IAddressAutocompleteDatasource>();
        expect(autocomplete, isA<ApiSearchAddressDatasource>());

        final geocode = Bind.get<IAddressPostcodeGeocodeDatasource>();
        expect(geocode, isA<ApiSearchAddressDatasource>());
      },
    );

    test(
      'self-referential singleton (addSingleton<Interface>((i) => i.get())) also delegates',
      () {
        injector.startRegistering();
        injector.addSingleton<ApiSearchAddressDatasource>((i) => ApiSearchAddressDatasource());
        injector.addSingleton<IAddressAutocompleteDatasource>((i) => i.get());
        final binds = injector.finishRegistering();

        Bind.registerBatch(binds);
        Bind.commitBatch(injector);

        final via = Bind.get<IAddressAutocompleteDatasource>();
        expect(via, isA<ApiSearchAddressDatasource>());
      },
    );

    test(
      'untyped impl + untyped consumer: classic interface compat (sanity, should still pass)',
      () {
        injector.startRegistering();
        injector.addSingleton((i) => AuthApiImpl());
        injector.addSingleton((i) => AuthEmailCubit(i.get()));
        final binds = injector.finishRegistering();

        Bind.registerBatch(binds);
        Bind.commitBatch(injector);

        final cubit = Bind.get<AuthEmailCubit>();
        expect(cubit.api, isA<AuthApiImpl>());
      },
    );
  });
}
