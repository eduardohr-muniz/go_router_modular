/// Responsável APENAS por proteção contra loops infinitos
/// Responsabilidade única: Gerenciar tentativas de busca e prevenir loops
class BindSearchProtection {
  static final BindSearchProtection _instance = BindSearchProtection._();
  BindSearchProtection._();
  static BindSearchProtection get instance => _instance;

  final Map<Type, int> searchAttempts = {};
  final Set<Type> currentlySearching = {};
  final List<Type> searchStack = [];

  void clearAll() {
    searchAttempts.clear();
    currentlySearching.clear();
    searchStack.clear();
  }

  void clearForType(Type type) {
    searchAttempts.remove(type);
    currentlySearching.remove(type);
    searchStack.removeWhere((t) => t == type);
  }
}

