import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/core/injection_manager/_bind_registration.dart';

/// Gerencia o registro de módulos e seus estados
class ModuleRegistry {
  /// Rastrear quais módulos estão ativos
  final Set<Type> _activeModules = {};

  /// Rastrear quais módulos cada módulo importa
  final Map<Type, Set<Type>> _moduleImports = {};

  /// Rastrear os binds registrados por cada módulo (para unregister)
  final Map<Type, List<BindRegistration>> _moduleBinds = {};

  /// Módulo ativo no contexto atual (para resolução de binds)
  Type? _currentModuleContext;

  Module? _appModule;

  bool isActive(Type moduleType) => _activeModules.contains(moduleType);

  Set<Type> getImports(Type moduleType) => _moduleImports[moduleType] ?? {};

  List<BindRegistration> getBinds(Type moduleType) => _moduleBinds[moduleType] ?? [];

  Type? get currentContext => _currentModuleContext;

  Module? get appModule => _appModule;

  void setContext(Type moduleType) {
    _currentModuleContext = moduleType;
  }

  void clearContext() {
    _currentModuleContext = null;
  }

  void setAppModule(Module module) {
    _appModule = module;
  }

  void registerModule(Type moduleType) {
    _activeModules.add(moduleType);
    _moduleImports[moduleType] = <Type>{};
    _moduleBinds[moduleType] = [];
  }

  void addImport(Type moduleType, Type importedModule) {
    _moduleImports[moduleType]?.add(importedModule);
  }

  void trackBind(Type moduleType, BindRegistration bind) {
    _moduleBinds[moduleType]?.add(bind);
  }

  void unregisterModule(Type moduleType) {
    _activeModules.remove(moduleType);
    _moduleImports.remove(moduleType);
    _moduleBinds.remove(moduleType);
  }

  void clear() {
    _activeModules.clear();
    _moduleImports.clear();
    _moduleBinds.clear();
    _currentModuleContext = null;
    _appModule = null;
  }

  String getPrefix(Type moduleType) {
    return '${moduleType.toString()}_';
  }
}
