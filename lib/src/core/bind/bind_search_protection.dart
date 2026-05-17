/// Responsável APENAS por proteção contra loops infinitos
/// Responsabilidade única: Gerenciar tentativas de busca e prevenir loops
class BindSearchProtection {
  static final BindSearchProtection _instance = BindSearchProtection._();
  BindSearchProtection._();
  static BindSearchProtection get instance => _instance;

  final Map<Type, int> searchAttempts = {};
  final Set<Type> currentlySearching = {};
  final List<Type> searchStack = [];

  /// Binds whose factory is currently executing. Tracked so a
  /// self-referential factory (e.g. `addFactory<I>((i) => i.get())`) can
  /// re-enter the locator and have its own bind skipped — falling through
  /// to compatibility search, which finds another bind that produces `I`.
  ///
  /// Stored as an identity-set of `Object` to avoid a circular import with
  /// `Bind`. Nested self-references push and pop their own bind here so the
  /// blocking handles arbitrary depth.
  final Set<Object> _blockedBinds = Set<Object>.identity();

  bool get hasBlockedBinds => _blockedBinds.isNotEmpty;

  bool isBlocked(Object bind) => _blockedBinds.contains(bind);

  void blockBind(Object bind) {
    _blockedBinds.add(bind);
  }

  void unblockBind(Object bind) {
    _blockedBinds.remove(bind);
  }

  void clearAll() {
    searchAttempts.clear();
    currentlySearching.clear();
    searchStack.clear();
    _blockedBinds.clear();
  }

  void clearForType(Type type) {
    searchAttempts.remove(type);
    currentlySearching.remove(type);
    searchStack.removeWhere((t) => t == type);
  }
}

