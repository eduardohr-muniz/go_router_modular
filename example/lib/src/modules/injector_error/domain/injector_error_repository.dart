import 'package:example/src/modules/injector_error/injector_error.dart';

abstract class IInjectorErrorRepository {}

class InjectorErrorRepository implements IInjectorErrorRepository {
  final InjectorErrorService injectorErrorService;
  InjectorErrorRepository(this.injectorErrorService);
}

class InjectorErrorRepository2 implements IInjectorErrorRepository {
  final InjectorErrorService injectorErrorService;
  InjectorErrorRepository2(this.injectorErrorService);
}
