/// Tracks state used by `BindLocator` to prevent infinite loops and
/// distinguish legitimate self-references from real circular dependencies.
class BindSearchProtection {
  static final BindSearchProtection _instance = BindSearchProtection._();
  BindSearchProtection._();
  static BindSearchProtection get instance => _instance;

  /// Per-type counter of nested `_find<T>` calls. Cap enforced in
  /// `BindLocator._validateCanStartSearch`.
  final Map<Type, int> searchAttempts = {};

  /// Types currently being resolved on the call stack. Used to detect re-entry.
  final Set<Type> currentlySearching = {};

  /// Dependency chain (FIFO) used to build readable error messages.
  final List<Type> searchStack = [];

  /// Stack of factory invocations currently in progress, each tagged with the
  /// type the invocation is producing.
  ///
  /// Two consumers:
  ///   * `isBlocked(bind)` — for lookup paths that must skip a bind whose
  ///     factory is on the stack (avoids re-invoking the same factory).
  ///   * `isTopInvocationFor(type)` — `BindLocator._validateCanStartSearch`
  ///     uses this to allow recursive `i.get<T>()` ONLY when the immediate
  ///     factory above is producing the same `T` (self-reference like
  ///     `addFactory<I>((i) => i.get())`). Any other recursive lookup is a
  ///     cross-type circular dependency and is rejected with a clear error.
  final List<_Invocation> _invocationStack = [];

  /// Identity-keyed count of how many times each bind appears on the
  /// invocation stack. Counter (not Set) handles nested invocations of the
  /// same bind so the first `pop` doesn't prematurely "unblock" it.
  final Map<Object, int> _blockedCounts = Map<Object, int>.identity();

  bool get hasBlockedBinds => _blockedCounts.isNotEmpty;

  bool isBlocked(Object bind) => _blockedCounts.containsKey(bind);

  /// True iff the topmost in-flight factory invocation is producing [type].
  /// This is the **only** legitimate trigger for bypassing
  /// `currentlySearching` — everything else is a circular dependency.
  bool isTopInvocationFor(Type type) =>
      _invocationStack.isNotEmpty && _invocationStack.last.requestedType == type;

  /// Marks [bind] as invoking its factory to produce [requestedType]. Must be
  /// paired with [popInvocation] in a `try/finally`.
  void pushInvocation(Object bind, Type requestedType) {
    _invocationStack.add(_Invocation(bind, requestedType));
    _blockedCounts.update(bind, (n) => n + 1, ifAbsent: () => 1);
  }

  /// Undoes the matching [pushInvocation]. Pops the top of the stack when it
  /// matches; otherwise removes the most recent entry for [bind] defensively
  /// (handles exceptional unwinding where balance is suspect).
  void popInvocation(Object bind) {
    if (_invocationStack.isNotEmpty &&
        identical(_invocationStack.last.bind, bind)) {
      _invocationStack.removeLast();
    } else {
      for (var i = _invocationStack.length - 1; i >= 0; i--) {
        if (identical(_invocationStack[i].bind, bind)) {
          _invocationStack.removeAt(i);
          break;
        }
      }
    }

    final n = _blockedCounts[bind];
    if (n == null) return;
    if (n <= 1) {
      _blockedCounts.remove(bind);
    } else {
      _blockedCounts[bind] = n - 1;
    }
  }

  void clearAll() {
    searchAttempts.clear();
    currentlySearching.clear();
    searchStack.clear();
    _invocationStack.clear();
    _blockedCounts.clear();
  }

  void clearForType(Type type) {
    searchAttempts.remove(type);
    currentlySearching.remove(type);
    searchStack.removeWhere((t) => t == type);
  }
}

class _Invocation {
  final Object bind;
  final Type requestedType;
  const _Invocation(this.bind, this.requestedType);
}
