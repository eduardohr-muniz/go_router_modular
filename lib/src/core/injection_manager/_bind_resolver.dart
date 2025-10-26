import 'package:get_it/get_it.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';

/// Resolve binds considerando contexto de módulo
class BindResolver {
  final GetIt _getIt;
  final ModuleRegistry _registry;

  BindResolver(this._getIt, this._registry);

  T resolve<T extends Object>({String? key}) {
    final typeName = T.toString();

    // 1. Tentar no módulo atual (com prefixo)
    final currentContext = _registry.currentContext;
    if (currentContext != null && _registry.isActive(currentContext)) {
      final instance = _tryResolveInModule<T>(currentContext, key, typeName);
      if (instance != null) return instance;

      // 2. Tentar nos módulos importados (apenas se estiverem ativos)
      final imports = _registry.getImports(currentContext);
      for (final importedModule in imports) {
        if (!_registry.isActive(importedModule)) {
          continue; // Pular módulos que foram disposed
        }

        final importInstance = _tryResolveInModule<T>(importedModule, key, typeName);
        if (importInstance != null) return importInstance;
      }
    }

    // 3. Tentar no AppModule (sem prefixo - global)
    final appInstance = _tryResolveAppModule<T>(key, typeName);
    if (appInstance != null) return appInstance;

    // 4. Tentar sem instanceName (registro direto por tipo - fallback)
    if (key == null && _getIt.isRegistered<T>()) {
      return _getIt.get<T>();
    }

    throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
  }

  T? _tryResolveInModule<T extends Object>(Type moduleType, String? key, String typeName) {
    final prefix = _registry.getPrefix(moduleType);

    // Tentar com key se fornecida
    if (key != null) {
      final fullName = '$prefix$key';
      if (_getIt.isRegistered<T>(instanceName: fullName)) {
        return _getIt.get<T>(instanceName: fullName);
      }
    }

    // Tentar com tipo
    final fullTypeName = '$prefix$typeName';
    if (_getIt.isRegistered<T>(instanceName: fullTypeName)) {
      return _getIt.get<T>(instanceName: fullTypeName);
    }

    return null;
  }

  T? _tryResolveAppModule<T extends Object>(String? key, String typeName) {
    // Tentar no AppModule (sem prefixo - global)
    if (key != null) {
      if (_getIt.isRegistered<T>(instanceName: key)) {
        return _getIt.get<T>(instanceName: key);
      }
    }

    // Tentar com tipo como instanceName
    if (_getIt.isRegistered<T>(instanceName: typeName)) {
      return _getIt.get<T>(instanceName: typeName);
    }

    return null;
  }
}
