import 'dart:developer';

import 'package:go_router_modular/src/utils/exception.dart';
import 'package:go_router_modular/src/utils/injector.dart';
import 'package:go_router_modular/src/utils/internal_logs.dart';

class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  T? _instance;
  final StackTrace stackTrace;

  Bind(
    this.factoryFunction, {
    this.isSingleton = true,
    this.isLazy = true,
  }) : stackTrace = StackTrace.current;

  T get instance {
    if (_instance == null || !isSingleton) {
      _instance = factoryFunction(Injector());
    }
    return _instance!;
  }

  static final Map<Type, Bind> _bindsMap = {};

  static void register<T>(Bind<T> bind) {
    final type = bind.instance.runtimeType;
    iLog('📝 Registrando bind: $type (isSingleton: ${bind.isSingleton}, isLazy: ${bind.isLazy})', name: "BIND_DEBUG");

    if (!_bindsMap.containsKey(type)) {
      _bindsMap[type] = bind;
      iLog('✅ Bind registrado com sucesso: $type', name: "BIND_DEBUG");
      return;
    }

    Bind<T> existingBind = _bindsMap[type] as Bind<T>;
    iLog('⚠️ Bind já existe para $type (isLazy: ${existingBind.isLazy}, isSingleton: ${existingBind.isSingleton})', name: "BIND_DEBUG");

    if (existingBind.isLazy || existingBind.isSingleton) {
      iLog('🚫 Mantendo bind existente para $type', name: "BIND_DEBUG");
      return;
    }

    _bindsMap[type] = bind;
    iLog('🔄 Bind substituído para $type', name: "BIND_DEBUG");
  }

  static void dispose<T>(Bind<T> bind) {
    if (T.toString() == "Object") {
      iLog('🚫 Tentativa de dispose para tipo Object - ignorando', name: "BIND_DEBUG");
      return;
    }

    iLog('🗑️ Fazendo dispose do bind: ${T.toString()}', name: "BIND_DEBUG");
    final removed = _bindsMap.remove(T);
    if (removed != null) {
      iLog('✅ Bind removido com sucesso: ${T.toString()}', name: "BIND_DEBUG");
    } else {
      iLog('⚠️ Bind não encontrado para remoção: ${T.toString()}', name: "BIND_DEBUG");
    }
  }

  static void disposeByType(Type type) {
    iLog('🗑️ Fazendo dispose por tipo: $type', name: "BIND_DEBUG");
    final removed = _bindsMap.remove(type);
    if (removed != null) {
      iLog('✅ Bind removido com sucesso por tipo: $type', name: "BIND_DEBUG");
    } else {
      iLog('⚠️ Bind não encontrado para remoção por tipo: $type', name: "BIND_DEBUG");
    }
  }

  // Proteções contra loops infinitos
  static final Map<Type, int> _searchAttempts = {};
  static final Set<Type> _currentlySearching = {};
  static const int _maxSearchAttempts = 1000;

  static T _find<T>() {
    final type = T;

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_currentlySearching.contains(type)) {
      iLog('🚫 BLOQUEIO: Busca já em andamento para ${type.toString()}', name: "BIND_DEBUG");
      throw GoRouterModularException('Circular dependency detected for type ${type.toString()}');
    }

    // Controle de tentativas para evitar loops infinitos
    _searchAttempts[type] = (_searchAttempts[type] ?? 0) + 1;
    final isLastAttempt = _searchAttempts[type]! >= _maxSearchAttempts;

    if (_searchAttempts[type]! > _maxSearchAttempts) {
      iLog('💥 LIMITE EXCEDIDO: Máximo de tentativas atingido para ${type.toString()} (${_searchAttempts[type]} tentativas)', name: "BIND_DEBUG");
      _searchAttempts.remove(type);
      throw GoRouterModularException('Too many search attempts for type ${type.toString()}. Possible infinite loop detected.');
    }

    _currentlySearching.add(type);

    try {
      iLog('🔍 Procurando bind para tipo: ${type.toString()} (tentativa ${_searchAttempts[type]})', name: "BIND_DEBUG");
      iLog('📊 Binds disponíveis no mapa: ${_bindsMap.keys.map((k) => k.toString()).toList()}', name: "BIND_DEBUG");

      var bind = _bindsMap[type];

      if (bind == null) {
        iLog('❌ Bind não encontrado diretamente no mapa para ${type.toString()}', name: "BIND_DEBUG");
        iLog('🔄 Iniciando busca por instância compatível...', name: "BIND_DEBUG");

        for (var entry in _bindsMap.entries) {
          iLog('🧪 Testando se ${entry.value.instance.runtimeType} é compatível com ${type.toString()}', name: "BIND_DEBUG");
          if (entry.value.instance is T) {
            iLog('✅ Encontrado bind compatível: ${entry.value.instance.runtimeType} -> ${type.toString()}', name: "BIND_DEBUG");
            bind = Bind<T>((injector) => entry.value.instance, isSingleton: entry.value.isSingleton, isLazy: entry.value.isLazy);
            _bindsMap[type] = bind; // Atualiza o mapa com o novo Bind encontrado
            iLog('📝 Bind atualizado no mapa para ${type.toString()}', name: "BIND_DEBUG");
            break;
          }
        }

        if (bind == null) {
          // Só loga erro detalhado se for a última tentativa ou se atingir limite
          if (isLastAttempt) {
            log('💥 ERROR: when injecting: ${type.toString()}', name: "GO_ROUTER_MODULAR");
            throw GoRouterModularException('Bind not found for type ${type.toString()} ');
            // log('💥 ERROR: Bind not found: ${type.toString()} \n📋 Available binds: ${_bindsMap.entries.map((e) => '${e.value.instance.runtimeType}').toList()}', name: "GO_ROUTER_MODULAR");
          } else {
            // Para tentativas intermediárias, só log discreto
            iLog('⏳ Bind não encontrado para ${type.toString()} (tentativa ${_searchAttempts[type]}/$_maxSearchAttempts) - tentando novamente...', name: "BIND_DEBUG");
          }
        }
      } else {
        iLog('✅ Bind encontrado diretamente no mapa para ${type.toString()}', name: "BIND_DEBUG");
      }

      final instance = bind?.instance as T;
      iLog('🎯 Retornando instância: ${instance.runtimeType} para ${type.toString()}', name: "BIND_DEBUG");

      // Sucesso: limpar contador de tentativas
      _searchAttempts.remove(type);

      return instance;
    } finally {
      _currentlySearching.remove(type);
    }
  }

  static T get<T>() {
    iLog('🎯 SOLICITAÇÃO DE BIND: ${T.toString()}', name: "BIND_DEBUG");
    return _find<T>();
  }

  static Bind<T> singleton<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, isSingleton: true, isLazy: false);
    return bind;
  }

  // static Bind<T> _lazySingleton<T>(T Function(Injector i) builder) {
  //   final bind = Bind<T>(builder, isSingleton: true, isLazy: true);
  //   return bind;
  // }

  static Bind<T> factory<T>(T Function(Injector i) builder) {
    final bind = Bind<T>(builder, isSingleton: false, isLazy: false);
    return bind;
  }
}
