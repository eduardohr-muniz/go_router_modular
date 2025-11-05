import 'package:go_router_modular/src/core/bind/bind.dart';

/// Responsável APENAS por armazenar binds
/// Responsabilidade única: Gerenciar as coleções de binds
class BindStorage {
  static final BindStorage _instance = BindStorage._();
  BindStorage._();
  static BindStorage get instance => _instance;

  final Map<Type, Bind> bindsMap = {};
  final Map<String, Bind> bindsMapByKey = {};
  final List<Bind> pendingObjectBinds = [];
}

