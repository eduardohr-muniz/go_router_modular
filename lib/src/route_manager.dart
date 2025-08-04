import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/utils/setup.dart';
import 'package:go_router_modular/src/utils/internal_logs.dart';
import 'package:go_router_modular/src/utils/exception.dart';
import 'package:go_router_modular/src/utils/injector.dart';
import 'package:go_router_modular/src/bind.dart';
import 'package:go_router_modular/src/module.dart';

/// ValueObject para representar um bind único (Type + Key)
class BindIdentifier {
  final Type type;
  final String? key;

  const BindIdentifier(this.type, [this.key]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BindIdentifier && other.type == type && other.key == key;
  }

  @override
  int get hashCode => type.hashCode ^ (key?.hashCode ?? 0);

  @override
  String toString() => 'BindIdentifier($type${key != null ? ', key: $key' : ''})';
}

class RouteManager {
  static RouteManager? _instance;
  RouteManager._();
  static RouteManager get instance => _instance ??= RouteManager._();

  final Map<BindIdentifier, int> _bindReferences = {};
  Module? _appModule;

  final Injector _injector = Injector();

  final Map<Module, Set<BindIdentifier>> _moduleBindTypes = {};

  final List<Function> _bindsToValidate = [];

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  // Sistema de fila sequencial para operações de módulos
  final Queue<Future<void> Function()> _operationQueue = Queue<Future<void> Function()>();
  bool _isProcessingQueue = false;

  // Processa operações na fila sequencialmente
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _operationQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    try {
      while (_operationQueue.isNotEmpty) {
        final operation = _operationQueue.removeFirst();

        try {
          await operation();
        } catch (e) {
          // Se for GoRouterModularException, propaga para o usuário
          if (e is GoRouterModularException) {
            rethrow;
          }
          iLog('❌ Erro na operação da fila: $e', name: "ROUTE_MANAGER");
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  // Adiciona operação à fila e garante processamento sequencial
  Future<T> _enqueueOperation<T>(Future<T> Function() operation) async {
    final completer = Completer<T>();

    _operationQueue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        // Sempre propaga exceptions via completer para que sejam vistas pelo usuário
        completer.completeError(e);
      }
    });

    // Inicia processamento se não estiver rodando
    _processQueue();

    return completer.future;
  }

  void addValidateQueue(void Function() validate, String moduleName) {
    _bindsToValidate.add(validate);

    if (debugLog) {
      iLog('⏰ Validação agendada para $moduleName (janela: 500ms)', name: "BIND_VALIDATION");
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      final removed = _bindsToValidate.remove(validate);
      if (removed && debugLog) {
        iLog('⏭️ Validação expirada para $moduleName - nenhum dispose detectado', name: "BIND_VALIDATION");
      }
    });
  }

  bool _isBindForAppModule(BindIdentifier bindId) {
    final isForAppModule = _moduleBindTypes[_appModule]?.contains(bindId) ?? false;
    iLog('🔍 DEBUG: _isBindForAppModule($bindId) = $isForAppModule', name: "ROUTE_MANAGER");
    if (isForAppModule) {
      iLog('🔍 DEBUG: Bind $bindId é do AppModule', name: "ROUTE_MANAGER");
    }
    return isForAppModule;
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
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_moduleBindTypes.containsKey(module)) {
      return;
    }

    final moduleBinds = await module.binds();

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];

    _recursiveRegisterBinds(allBinds);
    _moduleBindTypes[module] = allBinds.map((e) => BindIdentifier(e.instance.runtimeType, e.key ?? e.instance.runtimeType.toString())).toSet();
    iLog('🔍 DEBUG: Módulo ${module.runtimeType} registrou tipos: ${allBinds.map((e) => e.instance.runtimeType).toList()}', name: "ROUTE_MANAGER");

    module.initState(_injector);

    if (debugLog) {
      log('💉 INJECTED: ${module.runtimeType} BINDS: ${allBinds.map((e) => e.instance.runtimeType.toString()).toList()}', name: "GO_ROUTER_MODULAR");
    }

    // Validação simples após 500ms
    addValidateQueue(() => _validateModuleBinds(module, allBinds), module.runtimeType.toString());
  }

  void _validateModuleBinds(Module module, List<Bind<Object>> moduleBinds) {
    if (debugLog) {
      iLog('🧪 Iniciando validação de ${moduleBinds.length} binds do ${module.runtimeType}', name: "BIND_VALIDATION");
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

          if (debugLog) {
            iLog('✅ $bindType validado', name: "BIND_VALIDATION");
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

          if (debugLog) {
            final stackTrace = bind.stackTrace.toString();
            final normalizedStack = _normalizeStackTrace(stackTrace);
            log('❌ $bindType FAILED: $e \n🔎STACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
            throw GoRouterModularException('Bind not found for type ${bindType.toString()}');
          }
        }
      }
    } finally {
      // DESCARTAR todas as instâncias criadas para validação
      final instanceCount = tempInstances.length;
      tempInstances.clear();

      if (debugLog) {
        iLog('🧹 $instanceCount instâncias temporárias descartadas', name: "BIND_VALIDATION");
      }
    }

    // Resultado final da validação
    if (debugLog) {
      if (errorCount == 0) {
        iLog('🎉 ${module.runtimeType}: Validação completa - todos os binds OK (✅$successCount)', name: "BIND_VALIDATION");
      } else {
        iLog('⚠️ ${module.runtimeType}: Validação completa - ✅$successCount ❌$errorCount', name: "BIND_VALIDATION");
      }
    }
  }

  // Normaliza caminhos do stacktrace para o formato padrão
  String _normalizeStackTrace(String stackTrace) {
    return stackTrace
        .split('\n')
        .where((line) => line.contains('binds') || line.contains('imports'))
        .map((line) {
          // Remove prefixos como "../" e normaliza o caminho
          String normalized = line
              .replaceAll('../packages/', 'packages/')
              .replaceAll(RegExp(r'^\s*\.\.\/'), '') // Remove ../ do início
              .trim();

          // Extrair apenas a parte a partir de 'lib/'
          if (normalized.contains('/lib/')) {
            final libIndex = normalized.indexOf('/lib/');
            return normalized.substring(libIndex + 1); // +1 para remover a barra inicial
          }

          // Se já começa com 'lib/', manter como está
          if (normalized.startsWith('lib/')) {
            return normalized;
          }

          // Se começar com packages/ mas não tiver /lib/, inserir lib/ e extrair
          if (normalized.startsWith('packages/')) {
            final parts = normalized.split('/');
            if (parts.length >= 3) {
              // packages/nome_projeto/src/... -> lib/src/...
              if (!parts.contains('lib')) {
                parts.insert(2, 'lib');
              }
              // Pegar apenas a partir de 'lib/'
              final libIndexInParts = parts.indexOf('lib');
              if (libIndexInParts != -1) {
                return parts.sublist(libIndexInParts).join('/');
              }
            }
          }

          return normalized;
        })
        .take(4)
        .join('\n');
  }

  void _recursiveRegisterBinds(List<Bind<Object>> binds, [int maxAttempts = 100]) {
    if (binds.isEmpty || maxAttempts <= 0) {
      return;
    }

    List<Bind<Object>> failedBinds = [];

    for (var bind in binds) {
      try {
        // Captura erro ao acessar instance
        final type = bind.instance.runtimeType;
        final key = bind.key ?? type.toString();
        final bindId = BindIdentifier(type, key);
        iLog('🔍 DEBUG: Processando bind: $bindId', name: "ROUTE_MANAGER");
        _incrementBindReference(bindId);
        Bind.register(bind);
        iLog('✅ DEBUG: Bind $bindId registrado com sucesso', name: "ROUTE_MANAGER");
      } catch (e) {
        iLog('❌ DEBUG: Erro ao registrar bind: $e', name: "ROUTE_MANAGER");
        failedBinds.add(bind);
      }
    }

    // Se ainda há binds que falharam, tenta novamente
    if (failedBinds.isNotEmpty && failedBinds.length < binds.length) {
      _recursiveRegisterBinds(failedBinds, maxAttempts - 1);
    } else if (failedBinds.isNotEmpty) {
      for (var bind in failedBinds) {
        final stackTrace = bind.stackTrace.toString();
        final normalizedStack = _normalizeStackTrace(stackTrace);
        log('❌ ${bind.instance.runtimeType} FAILED:  \n🔎STACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
        throw GoRouterModularException('Bind not found for type ${bind.instance.runtimeType.toString()}');
      }
    }
  }

  Future<void> unregisterBinds(Module module) async {
    if (_appModule != null && module == _appModule!) {
      return;
    }

    final Set<BindIdentifier> bindsToDispose = _moduleBindTypes[module] ?? {};

    List<BindIdentifier> disposedBinds = [];

    iLog('🔍 DEBUG: Binds para dispose: $bindsToDispose', name: "ROUTE_MANAGER");

    // Decrementar referências para cada bind único
    for (var bindId in bindsToDispose) {
      try {
        iLog('🔍 DEBUG: Decrementando referência para $bindId', name: "ROUTE_MANAGER");

        // Decrementar a referência para cada bind do módulo
        final disposed = _decrementBindReference(bindId);
        iLog('🔍 DEBUG: Decremento para $bindId - disposed: $disposed', name: "ROUTE_MANAGER");

        if (disposed) {
          disposedBinds.add(bindId);
          // Só fazer dispose quando não há mais referências
          final isForAppModule = _isBindForAppModule(bindId);
          iLog('🔍 DEBUG: Verificando se bind é do AppModule: $bindId -> $isForAppModule', name: "ROUTE_MANAGER");

          if (!isForAppModule) {
            iLog('🗑️ DEBUG: Chamando disposeByType para: ${bindId.type}', name: "ROUTE_MANAGER");
            Bind.disposeByType(bindId.type);
            iLog('✅ DEBUG: disposeByType concluído para: ${bindId.type}', name: "ROUTE_MANAGER");
          } else {
            iLog('⚠️ DEBUG: Bind $bindId é do AppModule - não fazendo dispose', name: "ROUTE_MANAGER");
          }
        } else {
          iLog('⚠️ DEBUG: Bind $bindId não foi disposed (ainda tem referências)', name: "ROUTE_MANAGER");
        }
      } catch (_) {}
    }

    if (debugLog) {
      log('🗑️ DISPOSED: ${module.runtimeType} BINDS: ${disposedBinds.map((e) => e.toString()).toList()}', name: "GO_ROUTER_MODULAR");
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

  void _incrementBindReference(BindIdentifier bindId) {
    iLog('🔍 DEBUG: _incrementBindReference($bindId)', name: "ROUTE_MANAGER");

    if (_bindReferences.containsKey(bindId)) {
      _bindReferences[bindId] = (_bindReferences[bindId] ?? 0) + 1;
      iLog('🔍 DEBUG: Incrementou referência para $bindId -> ${_bindReferences[bindId]}', name: "ROUTE_MANAGER");
    } else {
      _bindReferences[bindId] = 1;
      iLog('🔍 DEBUG: Nova referência para $bindId -> 1', name: "ROUTE_MANAGER");
    }
  }

  bool _decrementBindReference(BindIdentifier bindId) {
    iLog('🔍 DEBUG: _decrementBindReference($bindId) - _bindReferences: $_bindReferences', name: "ROUTE_MANAGER");

    if (_bindReferences.containsKey(bindId)) {
      _bindReferences[bindId] = (_bindReferences[bindId] ?? 1) - 1;
      iLog('🔍 DEBUG: Decrementou referência para $bindId -> ${_bindReferences[bindId]}', name: "ROUTE_MANAGER");

      if (_bindReferences[bindId] == 0) {
        _bindReferences.remove(bindId);
        iLog('✅ DEBUG: Removendo $bindId do _bindReferences', name: "ROUTE_MANAGER");
        return true;
      }
    } else {
      iLog('⚠️ DEBUG: Bind $bindId não encontrado em _bindReferences', name: "ROUTE_MANAGER");
    }
    return false;
  }

  Future<void> unregisterModule(Module module) async {
    if (module.runtimeType == _appModule?.runtimeType) return;
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    module.dispose();
    unregisterBinds(module);
    _moduleBindTypes.remove(module);

    // Executar todas as validações pendentes se houver dispose
    if (_bindsToValidate.isNotEmpty) {
      if (debugLog) {
        iLog('🔍 Dispose detectado - executando ${_bindsToValidate.length} validações pendentes', name: "BIND_VALIDATION");
      }

      // Executar todas as validações
      final validationsToRun = List<Function>.from(_bindsToValidate);
      for (var validation in validationsToRun) {
        try {
          validation();
        } catch (e) {
          // Se for GoRouterModularException, propaga para o usuário
          if (e is GoRouterModularException) {
            rethrow;
          }
          if (debugLog) {
            iLog('❌ Erro na validação: $e', name: "BIND_VALIDATION");
          }
        }
      }

      // Limpar fila após execução
      _bindsToValidate.clear();

      if (debugLog) {
        iLog('🧹 Fila de validações limpa', name: "BIND_VALIDATION");
      }
    } else {
      if (debugLog) {
        iLog('⏭️ Nenhuma validação pendente', name: "BIND_VALIDATION");
      }
    }
  }
}
