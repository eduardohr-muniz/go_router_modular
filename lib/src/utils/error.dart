import 'package:go_router_modular/go_router_modular.dart';

abstract class GoRouterModularError implements Error {
  final String message;
  final StackTrace _stackTrace;

  const GoRouterModularError(this.message, this._stackTrace);

  @override
  StackTrace? get stackTrace => _stackTrace;
}

final class InjectorGoRouterModularError extends GoRouterModularError {
  final List<Bind<Object>> binds;
  const InjectorGoRouterModularError(
    super.message,
    super.stackTrace,
    this.binds,
  );
}
