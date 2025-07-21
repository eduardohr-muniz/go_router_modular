import 'dart:async';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';

class RouteManager {
  static RouteManager? _instance;
  RouteManager._();
  static RouteManager get instance => _instance ??= RouteManager._();

  final Map<Type, int> _bindReferences = {};
  Module? _appModule;

  final Injector _injector = Injector();

  final Map<Module, Set<Type>> _moduleBindTypes = {};

  final List<Function> _bindsToValidate = [];

  void addValidateQueue(void Function() validate, String moduleName) {
    _bindsToValidate.add(validate);

    if (Modular.debugLogDiagnostics) {
      log('⏰ Validação agendada para $moduleName (janela: 500ms)', name: "BIND_VALIDATION");
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      final removed = _bindsToValidate.remove(validate);
      if (removed && Modular.debugLogDiagnostics) {
        log('⏭️ Validação expirada para $moduleName - nenhum dispose detectado', name: "BIND_VALIDATION");
      }
    });
  }

  bool _isBindForAppModule(Type type) {
    return _moduleBindTypes[_appModule]?.contains(type) ?? false;
  }

  void registerAppModule(Module module) {
    if (_appModule != null) {
      return;
    }
    _appModule = module;
    registerBindsModule(module);
  }

  /// Coleta recursivamente todos os binds de imports aninhados
  Future<List<Bind<Object>>> _getAllImportedBindsRecursively(Module module, [Set<Module>? visited]) async {
    visited ??= <Module>{};
    Set<Bind<Object>> allImportedBinds = {};

    if (visited.contains(module)) {
      return allImportedBinds.toList();
    }
    visited.add(module);

    final imports = await module.imports();

    await Future.forEach(imports, (module) async {
      final binds = await module.binds();
      allImportedBinds.addAll(binds);
      allImportedBinds.addAll(await _getAllImportedBindsRecursively(module, visited));
    });

    return allImportedBinds.toList();
  }

  Future<void> registerBindsModule(Module module) async {
    if (_moduleBindTypes.containsKey(module)) {
      return;
    }

    final moduleBinds = await module.binds();

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];

    _recursiveRegisterBinds(allBinds);
    _moduleBindTypes[module] = allBinds.map((e) => e.instance.runtimeType).toSet();

    module.initState(_injector);

    if (Modular.debugLogDiagnostics) {
      log('INJECTED: ${module.runtimeType} BINDS: ${allBinds.map((e) => e.instance.runtimeType.toString()).toList()}', name: "💉");
    }

    // Validação simples após 500ms
    addValidateQueue(() => _validateModuleBinds(module, allBinds), module.runtimeType.toString());
  }

  void _validateModuleBinds(Module module, List<Bind<Object>> moduleBinds) {
    if (Modular.debugLogDiagnostics) {
      log('🧪 Iniciando validação de ${moduleBinds.length} binds do ${module.runtimeType}', name: "BIND_VALIDATION");
    }

    // Lista para rastrear instâncias temporárias (evitar memory leak)
    List<dynamic> tempInstances = [];

    int successCount = 0;
    int errorCount = 0;

    try {
      // Testar cada bind FORÇANDO nova criação
      for (Bind<Object> bind in moduleBinds) {
        Type? bindType;
        try {
          // Primeiro, pegar o tipo sem criar instância
          bindType = bind.instance.runtimeType;

          // FORÇAR criação de nova instância para validar dependências
          var newInstance = bind.factoryFunction(_injector);

          // Adicionar à lista temporária para limpeza posterior
          tempInstances.add(newInstance);
          successCount++;

          if (Modular.debugLogDiagnostics) {
            log('✅ $bindType validado', name: "BIND_VALIDATION");
          }
        } catch (e) {
          if (bindType == null) {
            try {
              bindType = bind.instance.runtimeType;
            } catch (_) {
              bindType = Object;
            }
          }
          errorCount++;

          if (Modular.debugLogDiagnostics) {
            log('❌ $bindType FALHOU: $e', name: "BIND_VALIDATION");
          }
        }
      }
    } finally {
      // DESCARTAR todas as instâncias criadas para validação
      final instanceCount = tempInstances.length;
      tempInstances.clear();

      if (Modular.debugLogDiagnostics) {
        log('🧹 $instanceCount instâncias temporárias descartadas', name: "BIND_VALIDATION");
      }
    }

    // Resultado final da validação
    if (Modular.debugLogDiagnostics) {
      if (errorCount == 0) {
        log('🎉 ${module.runtimeType}: Validação completa - todos os binds OK (✅$successCount)', name: "BIND_VALIDATION");
      } else {
        log('⚠️ ${module.runtimeType}: Validação completa - ✅$successCount ❌$errorCount', name: "BIND_VALIDATION");
      }
    }
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds, [int maxAttempts = 10]) {
    if (binds.isEmpty || maxAttempts <= 0) {
      return;
    }

    List<Bind<Object>> failedBinds = [];

    for (var bind in binds) {
      try {
        // Captura erro ao acessar instance
        final type = bind.instance.runtimeType;
        _incrementBindReference(type);
        Bind.register(bind);
      } catch (e) {
        failedBinds.add(bind);
      }
    }

    // Se ainda há binds que falharam, tenta novamente
    if (failedBinds.isNotEmpty && failedBinds.length < binds.length) {
      _recursiveRegisterBinds(failedBinds, maxAttempts - 1);
    } else if (failedBinds.isNotEmpty) {
      for (var bind in failedBinds) {
        //TODO: PRINT DE ERROS DE BIND NAO RESOLVIDOS
      }
    }
  }

  Future<void> unregisterBinds(Module module) async {
    if (_appModule != null && module == _appModule!) {
      return;
    }

    final Set<Type> bindsToDispose = _moduleBindTypes[module] ?? {};

    List<Type> disposedBinds = [];

    for (var bind in bindsToDispose) {
      try {
        final disposed = _decrementBindReference(bind);
        if (disposed) {
          disposedBinds.add(bind);
          // Só fazer dispose quando não há mais referências
          if (!_isBindForAppModule(bind)) {
            Bind.disposeByType(bind);
          }
        }
      } catch (_) {}
    }

    if (Modular.debugLogDiagnostics) {
      log('DISPOSED: ${module.runtimeType} BINDS: ${disposedBinds.map((e) => e.toString()).toList()}', name: "🗑️");
    }

    // Remover o código problemático que sempre fazia dispose
    // bindsToDispose.map((type) {
    //   if (_isBindForAppModule(type)) {
    //     return;
    //   }
    //   Bind.disposeByType(type);
    // }).toList();
    bindsToDispose.clear();
  }

  void _incrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 0) + 1;
    } else {
      _bindReferences[type] = 1;
    }
  }

  bool _decrementBindReference(Type type) {
    if (_bindReferences.containsKey(type)) {
      _bindReferences[type] = (_bindReferences[type] ?? 1) - 1;
      if (_bindReferences[type] == 0) {
        _bindReferences.remove(type);

        return true;
      }
    }
    return false;
  }

  void unregisterModule(Module module) {
    module.dispose();
    unregisterBinds(module);
    _moduleBindTypes.remove(module);

    // Executar todas as validações pendentes se houver dispose
    if (_bindsToValidate.isNotEmpty) {
      if (Modular.debugLogDiagnostics) {
        log('🔍 Dispose detectado - executando ${_bindsToValidate.length} validações pendentes', name: "BIND_VALIDATION");
      }

      // Executar todas as validações
      final validationsToRun = List<Function>.from(_bindsToValidate);
      for (var validation in validationsToRun) {
        try {
          validation();
        } catch (e) {
          if (Modular.debugLogDiagnostics) {
            log('❌ Erro na validação: $e', name: "BIND_VALIDATION");
          }
        }
      }

      // Limpar fila após execução
      _bindsToValidate.clear();

      if (Modular.debugLogDiagnostics) {
        log('🧹 Fila de validações limpa', name: "BIND_VALIDATION");
      }
    } else {
      if (Modular.debugLogDiagnostics) {
        log('⏭️ Nenhuma validação pendente', name: "BIND_VALIDATION");
      }
    }
  }
}
