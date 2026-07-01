import 'package:go_router_modular/src/module/module.dart';
import 'package:go_router_modular/src/di/bind_identifier.dart';

/// Tracks which modules use which binds for lifecycle management.
class BindContextTracker {
  final Map<BindIdentifier, Set<Module>> _bindModuleContext = {};
  final Map<Module, Set<BindIdentifier>> moduleBindTypes = {};
  Module? appModule;

  bool isBindForAppModule(BindIdentifier bindId) {
    if (appModule == null) return false;
    final modules = _bindModuleContext[bindId] ?? {};
    return modules.contains(appModule);
  }

  /// `true` se [bindId] é visível ao módulo [scope]: pertence aos binds próprios
  /// ou importados de [scope], ou aos binds do `AppModule` (o escopo global).
  bool isVisible(BindIdentifier bindId, Module scope) {
    final scopeSet = moduleBindTypes[scope];
    if (scopeSet != null && scopeSet.contains(bindId)) return true;
    final appModuleScope = appModule;
    if (appModuleScope != null) {
      final appSet = moduleBindTypes[appModuleScope];
      if (appSet != null && appSet.contains(bindId)) return true;
    }
    return false;
  }

  void addModuleToBindContext(BindIdentifier bindId, Module module) {
    _bindModuleContext.putIfAbsent(bindId, () => <Module>{}).add(module);
  }

  bool removeModuleFromBindContext(BindIdentifier bindId, Module module) {
    final modules = _bindModuleContext[bindId];
    if (modules == null || modules.isEmpty) return false;

    modules.remove(module);

    if (modules.isEmpty) {
      _bindModuleContext.remove(bindId);
      return true;
    }

    return false;
  }

  /// Clears all module/bind associations (e.g. between tests).
  void clear() {
    _bindModuleContext.clear();
    moduleBindTypes.clear();
    appModule = null;
  }
}
