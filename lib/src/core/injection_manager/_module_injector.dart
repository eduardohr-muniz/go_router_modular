import 'package:get_it/get_it.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/injection_manager/_bind_registration.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';

/// Injector com contexto de módulo para registrar binds com prefixo
class ModuleInjector extends Injector {
  final GetIt _getIt;
  final String? _modulePrefix;
  final Type _moduleType;
  final ModuleRegistry _registry;

  ModuleInjector(this._getIt, this._modulePrefix, this._moduleType, this._registry) : super.fromGetIt(_getIt);

  String _getInstanceName<T>(String? key) {
    final baseName = key ?? T.toString();
    return _modulePrefix != null ? '$_modulePrefix$baseName' : baseName;
  }

  void _trackBind<T>(String? instanceName) {
    _registry.trackBind(_moduleType, BindRegistration(T, instanceName));
  }

  @override
  void add<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerFactory<T>(builder);
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerFactory<T>(builder, instanceName: instanceName);
      _trackBind<T>(instanceName);
    }
  }

  @override
  void addSingleton<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerLazySingleton<T>(
        builder,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerLazySingleton<T>(
        builder,
        instanceName: instanceName,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(instanceName);
    }
  }

  @override
  void addLazySingleton<T extends Object>(T Function() builder, {String? key}) {
    if (_modulePrefix == null && key == null) {
      // AppModule sem key: registrar sem instanceName
      _getIt.registerLazySingleton<T>(
        builder,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(null);
    } else {
      final instanceName = _getInstanceName<T>(key);
      _getIt.registerLazySingleton<T>(
        builder,
        instanceName: instanceName,
        dispose: (instance) {
          CleanBind.fromInstance(instance);
        },
      );
      _trackBind<T>(instanceName);
    }
  }

  @override
  T get<T extends Object>({String? key}) {
    return InjectionManager.instance.getWithModuleContext<T>(key: key);
  }
}
