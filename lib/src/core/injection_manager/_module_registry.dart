import 'package:go_router_modular/go_router_modular.dart';

/// Registry para rastrear módulos ativos e suas importações
class ModuleRegistry {
  Module? _appModule;
  final Set<Type> _activeModules = {};
  final Map<Type, Set<Type>> _moduleImports = {};

  Module? get appModule => _appModule;

  void setAppModule(Module module) {
    _appModule = module;
  }

  void registerModule(Type moduleType) {
    _activeModules.add(moduleType);
  }

  bool isActive(Type moduleType) {
    return _activeModules.contains(moduleType);
  }

  void unregisterModule(Type moduleType) {
    _activeModules.remove(moduleType);
    _moduleImports.remove(moduleType);
  }

  void addImport(Type moduleType, Type importedModuleType) {
    _moduleImports.putIfAbsent(moduleType, () => {});
    _moduleImports[moduleType]!.add(importedModuleType);
  }

  Set<Type> getImports(Type moduleType) {
    return _moduleImports[moduleType] ?? {};
  }

  Type? _currentModuleContext;

  void setContext(Type moduleType) {
    _currentModuleContext = moduleType;
  }

  Type? get currentModuleContext => _currentModuleContext;

  void clear() {
    _appModule = null;
    _activeModules.clear();
    _moduleImports.clear();
    _currentModuleContext = null;
  }
}
