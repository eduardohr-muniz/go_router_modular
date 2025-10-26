import 'dart:developer';
import 'package:auto_injector/auto_injector.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Resolve binds com isolamento de módulos
/// Cada módulo só pode acessar:
/// 1. Seus próprios binds
/// 2. Binds dos módulos importados (via imports)
/// 3. Binds do AppModule (sempre disponível)
class BindResolver {
  final AutoInjector _autoInjector;
  final ModuleRegistry _registry;

  BindResolver(this._autoInjector, this._registry);

  T resolve<T extends Object>({String? key}) {
    final currentContext = _registry.currentContext;

    // Rastrear o início da resolução na cadeia
    InjectionManager.instance.pushDependencyChain(T);

    log('🔍 [BindResolver.resolve] Tipo: ${T.toString()}${key != null ? ' key: $key' : ''}', name: "GO_ROUTER_MODULAR");
    log('🔍 [BindResolver.resolve] Contexto: ${currentContext?.toString() ?? "null"}', name: "GO_ROUTER_MODULAR");

    try {
      // Se não há contexto definido, tentar resolver no AppModule
      if (currentContext == null) {
        log('🔍 [BindResolver] Sem contexto, tentando AppModule', name: "GO_ROUTER_MODULAR");
        try {
          final result = _autoInjector.get<T>(key: key);
          log('✅ [BindResolver] Encontrado no AppModule (sem contexto)', name: "GO_ROUTER_MODULAR");
          InjectionManager.instance.popDependencyChain();
          return result;
        } catch (e) {
          log('❌ [BindResolver] Erro no AppModule (sem contexto): $e', name: "GO_ROUTER_MODULAR");
          throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
        }
      }

      // Se o contexto é o AppModule, resolver no injector principal
      if (currentContext == _registry.appModule?.runtimeType) {
        log('🔍 [BindResolver] Contexto é AppModule', name: "GO_ROUTER_MODULAR");
        try {
          final result = _autoInjector.get<T>(key: key);
          log('✅ [BindResolver] Encontrado no AppModule', name: "GO_ROUTER_MODULAR");
          InjectionManager.instance.popDependencyChain();
          return result;
        } catch (e) {
          log('❌ [BindResolver] Erro no AppModule: $e', name: "GO_ROUTER_MODULAR");
          throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
        }
      }

      // Buscar o injector do módulo atual
      final moduleInjector = _getModuleInjector(currentContext);
      log('🔍 [BindResolver] Injector do módulo: ${moduleInjector != null ? moduleInjector.toString() : "null"}', name: "GO_ROUTER_MODULAR");

      if (moduleInjector != null) {
        try {
          log('🔍 [BindResolver] Tentando resolver no injector do módulo...', name: "GO_ROUTER_MODULAR");
          log('🔍 [BindResolver] Injector tag: ${moduleInjector.toString()}', name: "GO_ROUTER_MODULAR");
          // Tentar resolver no injector do módulo atual (que inclui seus próprios binds e imports)
          final result = moduleInjector.get<T>(key: key);
          log('✅ [BindResolver] Encontrado no injector do módulo', name: "GO_ROUTER_MODULAR");
          InjectionManager.instance.popDependencyChain();
          return result;
        } catch (e) {
          log('❌ [BindResolver] Não encontrado no injector do módulo: $e', name: "GO_ROUTER_MODULAR");
          // Extrair trace do erro do auto_injector se disponível
          _logAutoInjectorTrace(e);
          // Não encontrou no módulo atual ou nos imports
          // TENTAR NO APPMODULE GLOBAL (sempre disponível)
          if (_registry.appModule != null) {
            try {
              log('🔍 [BindResolver] Tentando AppModule como fallback...', name: "GO_ROUTER_MODULAR");
              final result = _autoInjector.get<T>(key: key);
              log('✅ [BindResolver] Encontrado no AppModule (fallback)', name: "GO_ROUTER_MODULAR");
              InjectionManager.instance.popDependencyChain();
              return result;
            } catch (e2) {
              log('❌ [BindResolver] Erro no AppModule (fallback): $e2', name: "GO_ROUTER_MODULAR");
              // Extrair trace do erro do auto_injector se disponível
              _logAutoInjectorTrace(e2);
              // Gerar mensagem de erro detalhada
              final errorMessage = _generateDetailedErrorMessage<T>(currentContext, key, e2);
              throw Exception(errorMessage);
            }
          }
          log('❌ [BindResolver] Sem AppModule, lançando exceção', name: "GO_ROUTER_MODULAR");
          // Gerar mensagem de erro detalhada
          final errorMessage = _generateDetailedErrorMessage<T>(currentContext, key, e);
          throw Exception(errorMessage);
        }
      }

      // Se não conseguiu encontrar o injector do módulo, tentar no injector principal
      // (fallback para casos onde o moduleInjector é null)
      if (_registry.appModule != null) {
        try {
          final result = _autoInjector.get<T>(key: key);
          InjectionManager.instance.popDependencyChain();
          return result;
        } catch (e) {
          throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
        }
      }

      throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
    } catch (e) {
      // Em caso de erro, garantir que a cadeia é mantida para exibição na mensagem de erro
      rethrow;
    }
  }

  /// Obtém o injector de um módulo específico
  AutoInjector? _getModuleInjector(Type moduleType) {
    // Buscar o injector do módulo no mapa de injectors
    try {
      final moduleInjectors = InjectionManager.instance.moduleInjectors;
      log('🔍 [BindResolver._getModuleInjector] Buscando injector para: $moduleType', name: "GO_ROUTER_MODULAR");
      log('🔍 [BindResolver._getModuleInjector] Mapas disponíveis: ${moduleInjectors.keys}', name: "GO_ROUTER_MODULAR");
      final injector = moduleInjectors[moduleType];
      if (injector != null) {
        log('✅ [BindResolver._getModuleInjector] Injector encontrado para $moduleType', name: "GO_ROUTER_MODULAR");
      } else {
        log('❌ [BindResolver._getModuleInjector] Injector NÃO encontrado para $moduleType', name: "GO_ROUTER_MODULAR");
      }
      return injector;
    } catch (e) {
      log('❌ [BindResolver._getModuleInjector] Erro ao buscar injector: $e', name: "GO_ROUTER_MODULAR");
      return null;
    }
  }

  /// Extrai e loga o trace do auto_injector
  void _logAutoInjectorTrace(dynamic e) {
    try {
      final errorStr = e.toString();
      if (errorStr.contains('Trace:')) {
        final traceMatch = RegExp(r'Trace: (.*)', multiLine: true).firstMatch(errorStr);
        if (traceMatch != null) {
          final trace = traceMatch.group(1);
          log('🔗 [BindResolver] AutoInjector trace: $trace', name: "GO_ROUTER_MODULAR");

          // Tentar extrair também o trace em formato de seta
          final arrowsMatch = RegExp(r'=> (.+)', multiLine: true).firstMatch(errorStr);
          if (arrowsMatch != null) {
            log('🔗 [BindResolver] Dependency chain: ${arrowsMatch.group(1)}', name: "GO_ROUTER_MODULAR");
          }
        }
      }
    } catch (e) {
      // Ignorar erros ao extrair trace
    }
  }

  /// Gera mensagem de erro detalhada com orientações ao usuário
  String _generateDetailedErrorMessage<T extends Object>(Type? moduleContext, String? key, [dynamic originalError]) {
    final typeName = T.toString();

    final sb = StringBuffer();

    // Obter a cadeia de dependências
    final dependencyChain = InjectionManager.instance.dependencyChain;

    // Título
    sb.writeln('🛑 Dependency Injection Error');
    sb.writeln('   Bind not found for type: `$typeName` | Module: `${moduleContext?.toString() ?? "Global"}`');

    // Descrição
    sb.writeln('The dependency `$typeName` is not registered in the DI container.');

    // Exibir a cadeia de dependências completa
    if (dependencyChain.isNotEmpty) {
      sb.writeln('');
      sb.writeln('🔗 DEPENDENCY CHAIN:');
      sb.writeln('   1. $typeName');
      if (dependencyChain.length > 1) {
        for (var i = 0; i < dependencyChain.length - 1; i++) {
          sb.writeln('      ↓ needs');
          sb.writeln('   ${i + 2}. ${dependencyChain[i]}');
        }
      }
      sb.writeln('      ↓ needs');
      sb.writeln('   ${dependencyChain.length + 1}. ${dependencyChain.last} ← Este tipo não está registrado!');
    }

    // Aviso sobre possível dependência em falta
    sb.writeln('');
    sb.writeln('⚠️  DIAGNÓSTICO:');
    sb.writeln('   Este erro indica que a dependência na base da cadeia não foi registrada.');

    // Incluir trace do auto_injector se disponível
    String? chain;
    if (originalError != null) {
      final errorStr = originalError.toString();
      final traceMatch = RegExp(r'Trace: (.*)', multiLine: true).firstMatch(errorStr);
      if (traceMatch != null) {
        chain = traceMatch.group(1);
        if (chain != null) {
          sb.writeln('$chain');
        }
      }
    }

    // Tentar extrair arquivo .dart mais provável do stack trace
    String? mostLikelyFile;
    if (originalError != null) {
      final errorStr = originalError.toString();
      // Procurar por padrão: package:package_name/path/file.dart
      final fileMatch = RegExp(r'(package:[^\s]+\.dart)').firstMatch(errorStr);
      if (fileMatch != null) {
        mostLikelyFile = fileMatch.group(1);
      }
    }

    // Recomendação de fix
    sb.writeln('');
    sb.writeln('✅ RECOMMENDED FIX:');
    sb.writeln('Ensure all required dependencies are registered before usage:');

    // Gerar exemplos de registros baseados na cadeia de dependências
    if (chain != null) {
      final types = chain.split('->');
      for (var i = 0; i < types.length; i++) {
        final type = types[i].trim();
        sb.writeln('  i.add<$type>(() => YourImplementation());');
      }
    } else {
      sb.writeln('  i.add<$typeName>(() => YourImplementation());');
    }

    // Adicionar arquivo mais provável se encontrado
    if (mostLikelyFile != null) {
      sb.writeln('');
      sb.writeln('📍 Most likely file: $mostLikelyFile');
    }

    return sb.toString();
  }
}
