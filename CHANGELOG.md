## 5.3.0

### Added

- **`copyWith` on the modular router**. Override individual `GoRouter` options at the point where the router is consumed, reusing everything passed to `Modular.configure(...)`. Useful when `ModularApp.router` doesn't expose an option you need — for example attaching a `NavigatorObserver`:

  ```dart
  MaterialApp.router(
    routerConfig: Modular.routerConfig.copyWith(
      observers: [MyAnalyticsObserver()],
    ),
    builder: (context, child) => ModularLoader.builder(context, child),
  );
  ```

  Overridable options include `observers`, `redirect`, `refreshListenable`, `errorBuilder`, `errorPageBuilder`, `redirectLimit`, `navigatorKey`, `restorationScopeId`, and more. The derived router is memoized, so widget rebuilds reuse the same instance and navigation state is preserved.

### Changed

- Bumped the `go_router` constraint to `^17.3.0`, pulling in the chained top-level redirect resolution fix (17.2.1) and the `pop()` + `onExit` stale-configuration fix (17.2.2).

## 5.2.0

### Breaking

- **Untyped factory binds no longer auto-resolve through supertypes**. Applies to **any** supertype relationship — interfaces, abstract classes, concrete superclasses, and mixins — not just interfaces. The previous compatibility search probed every factory bind in `bindsMap` to type-check it against the requested supertype, invoking the factory's constructor (with all its side effects: event publication, stream subscription, HTTP calls, etc.) and discarding the resulting instance. Production traces showed cubits being silently instantiated multiple times per session as a byproduct of unrelated `get<T>()` calls. The compatibility search now skips factory binds entirely; only singletons (whose probe instance is cached and reused) participate. Migration:

  ```dart
  // Before — works by accident, instantiates ServiceImpl as a probe side-effect
  i.addFactory((i) => ServiceImpl());
  i.get<IService>(); // ✅ resolved

  // After — explicit, no probe, zero side effects until first real get
  i.addFactory<IService>((i) => ServiceImpl());
  i.get<IService>(); // ✅ resolved via Strategy 2 (direct lookup)

  // Or, if singleton semantics are acceptable:
  i.addSingleton((i) => ServiceImpl());
  i.get<IService>(); // ✅ resolved (singleton cached, probe-safe)
  ```

  Direct lookups by the registered concrete type (`get<ServiceImpl>()`) still work for untyped factories — only the supertype auto-discovery is removed.

### Fixed

- **Phantom factory instances during interface lookup** (the breaking change above is the fix). Reproduction: with 4 factory binds in a module, every unrelated `get<IUnregistered>` instantiated all 4 (running their constructors). After 100 lookups in a session, ~400 phantom Cubit/Service instances leaked — each potentially opening WebSockets, subscribing to streams, or firing events. Now: zero phantom invocations.
- **Cross-type circular dependency now surfaces a clear error**. `A → B → A` previously fell into the global `hasBlockedBinds` bypass and was masked as `Bind not found for type "A"` at the deepest probe level. The validation bypass is now tightened to the specific self-reference case (`addFactory<I>((i) => i.get())`) using a typed `(bind, requestedType)` invocation stack. Cross-type cycles now throw `GoRouterModularException: Circular dependency detected while resolving type "A". Dependency chain: A -> B -> A.`
- **`BindRegistry.register` indexes typed binds under the declared type**. `Bind.factory<IService>((i) => ServiceImpl())` previously stored the bind only under `ServiceImpl` (the discovered runtime type), making `get<IService>` miss Strategy 2 and depend on probing. Typed binds now occupy `bindsMap[IService]` directly; the discovered runtime type is also indexed for `get<ServiceImpl>` lookups.

### Improved

- **`BindSearchProtection` is re-entrant safe**. Replaced `Set<Object> _blockedBinds` with a counter-backed `Map<Object, int>` so nested invocations of the same bind don't prematurely "unblock" each other on the first `pop`.
- **Single helper for factory invocations**. Extracted `BindLocator._withInvocation(bind, requestedType, action)` — every factory call goes through here, eliminating the previous four-way duplication of `pushInvocation / try / finally / popInvocation`.

---

## 5.1.0

### Added

- **Stateful shell branch transitions**: `StatefulShellBranchTransitions` helpers (e.g. `withGoTransition`, fade presets) so bottom tabs/branches can reuse the same transition style as modular `GoRoute`s.

### Improved

- **Dependency injection — batch registration**: Typed binds (`Bind<T>`) are now indexed up front in `registerBatch`, so any bind in the same batch can resolve siblings in any declaration order. `commitBatch` runs in three phases: materialize singletons, propagate cached instances to duplicate `Bind` objects, then fall back to deferred resolution for `Bind<Object>` registrations.
- **Dependency injection — code quality**: Extracted `_writeToCanonicalSlot` to centralise the dual-map invariant (`bindsMap` for unkeyed, `bindsMapByKey` for keyed binds). Replaced the ambiguous `bool _handleExistingBind` with a `_SlotConflictResolution` enum. Renamed `_pendingBatch` to `_uncommittedBatch`. Swallowed registration errors now surface via `dart:developer.log` when `debugLogGoRouterModular` is enabled.

### Fixed

- **Singleton identity across interface lookups**: `BindLocator._searchCompatibleBind` now reuses the canonical bind when resolving through an interface, preventing a new factory call on every `Injector.get<IFoo>()` call.
- **Self-referential interface factory** (`addFactory<I>((i) => i.get())`): The locator now detects recursive resolution for the same type and skips the executing bind, falling through to the concrete implementation. Previously this threw `"Type IFoo is already being searched"`.
- **`ConcurrentModificationError` during interface lookup**: `_searchCompatibleBind` now iterates a snapshot of `bindsMap.entries` instead of the live view, making in-loop writes safe under nested resolution.
- **Singleton instantiated multiple times via imports**: Duplicate `Bind` objects created by re-imported modules now receive the cached instance from the already-registered bind, preventing repeated factory calls.
- **`Injector.get<IService>()` after typed registration**: A singleton registered with an explicit generic (e.g. `i.addSingleton<IAuthApi>(...)`) is now reachable through both the interface and the concrete `runtimeType`.
- **Keyed + unkeyed singleton on the same type**: `bindsMap[type]` now holds only the unkeyed bind; keyed binds live exclusively in `bindsMapByKey`, making `Injector.get<IClient>()` order-independent.

---

## 5.0.6

### Fixed

- **Duplicate singleton construction via imports**: `_collectImportedBinds` created new `Bind` objects with `cachedInstance == null` on every registration pass. `commitBatch` now propagates `cachedInstance` to duplicate binds before downstream methods run, preventing 2× extra factory calls.
- **Orphaned singleton instances**: When two imported modules declare the same type, `commitBatch` now checks `_isSingletonAlreadyRegistered` *before* calling `factoryFunction`, completely preventing duplicate factory calls and leaked instances (open streams, duplicate subscriptions).

---

## 5.0.5

### Fixed

- **Dependency injection**: Singleton and lazySingleton constructors were called multiple times during module registration. The system now correctly reuses the cached instance after the first creation.

---

## 5.0.4

### Fixed

- **`onExit` in `ChildRoute`**: Fixed propagation of the `onExit` callback across all route creation paths.

---

## 5.0.3

### Added

- **Detailed error messages**: Missing dependency errors now include which component made the request and a full dependency chain (e.g. `A ➔ B ➔ C`).
- **Circular dependency detection**: Detects infinite recursion during bind resolution and surfaces a clear, actionable error message.
- **Safer resource cleanup**: `CleanBind` now handles `dispose`, `close`, and `cancel` more robustly, with safe fallback for `NoSuchMethodError`.

---

## 5.0.2

### Improved

- **Dependency injection**: Switched from nested search to a commit-based approach for better performance.

---

## 5.0.1

### Added

- **`Bind.lazySingleton`**: Creates singleton instances only on first access — useful for expensive resources that may not always be needed.
  ```dart
  i.lazySingleton<ExpensiveService>((i) => ExpensiveService());
  ```

- **Page transitions**: Built-in transition system for smooth route animations.
  - Presets: fade, slide, scale, rotate, and more.
  - Child routes automatically inherit transitions from parent modules.
  - Platform-specific styles: Cupertino (iOS/macOS) and Material (Android).
  - Chainable effects: `GoTransitions.slide.toRight.withFade`.
  ```dart
  ModuleRoute('/home', module: HomeModule(),
    transition: GoTransitions.fadeUpwards,
    duration: Duration(milliseconds: 300))

  ChildRoute('/details', child: (_, __) => DetailsPage(),
    transition: GoTransitions.slide.toRight.withFade)
  ```

---

## 5.0.0

### Breaking Changes

- **New `binds` API**: Changed from `FutureOr<List<Bind<Object>>> binds()` to `FutureBinds binds(Injector i)`. Binds are now registered via injector methods instead of returning a list.

  ```dart
  // Before (4.x)
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.factory<ApiService>((i) => ApiService()),
    Bind.singleton<DatabaseService>((i) => DatabaseService()),
  ];

  // After (5.x)
  FutureBinds binds(Injector i) {
    i.add<ApiService>((i) => ApiService());
    i.addSingleton<DatabaseService>((i) => DatabaseService());
  }
  ```

### Added

- **Native injector**: Removed dependency on `auto_injector`. Direct registration methods: `i.add()`, `i.addSingleton()`, `i.addLazySingleton()`.
- **Performance**: ~4× faster dependency resolution and reduced memory overhead.
- **Better error messages**: Clearer type mismatch and cycle detection errors.

---

## 4.2.2

### Improved

- Improved the dispose process to ensure proper resource release and prevent memory leaks.

---

## 4.2.0+4

### Fixed

- Added validation to prevent overwriting already-registered singletons for the same type and key.

---

## 4.2.0

### Added

- **Event broadcasting**: Modules can now broadcast events across multiple modules with improved subscription management.

### Improved

- **Error messages**: More descriptive errors throughout the dependency injection system.

---

## 4.1.0

### Added

- `autoDisposeEventBus` parameter in `Modular.configure` to control whether events are automatically disposed when modules are destroyed (default: `true`).

### Fixed

- Nullable context in `EventModule` to handle web scenarios where context may not be available during page refreshes or redirects.

---

## 4.0.0

### Breaking Changes

- **`ModularApp.router`**: Replaces `MaterialApp.router`. `routerConfig` is set automatically — remove it from your code.
- **Async binds and imports**: `binds()` and `imports()` now return `FutureOr<List<T>>` instead of `List<T>`.

  ```dart
  // Before (3.x)
  List<Bind<Object>> get binds => [Bind.singleton<MyService>((i) => MyService())];
  List<Module> get imports => [SharedModule()];

  // After (4.x)
  FutureOr<List<Bind<Object>>> binds() => [Bind.singleton<MyService>((i) => MyService())];
  FutureOr<List<Module>> imports() => [SharedModule()];
  ```

### Added

- **`ModularApp.router`**: Extends `MaterialApp.router` with automatic loader display during module registration.
- **`ModularLoader`**: Built-in loading overlay with `ModularLoader.show()` / `ModularLoader.hide()` and a `CustomModularLoader` abstract class for full appearance customisation.

---

## 3.0.0

### Breaking Changes

- **Root route required**: Modules must now declare a root `ChildRoute('/')` as their entry point. An assertion error is thrown if it is missing.

  ```dart
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => HomePage()), // required
    ChildRoute('/details', child: (_, __) => DetailsPage()),
  ];
  ```

---

## 2.0.3+1

### Added

- `initState` and `dispose` lifecycle methods in modules.
- Recursive binding imports between modules.

### Fixed

- Auto-dispose mechanism to ensure proper resource cleanup.

---

## 2.0.2+1

### Added

- `InternalLogs` class for consistent debug output across route registration and bind management.

### Fixed

- `_register` was not being called during route redirects, causing missing dependency injection before page construction.

### Improved

- Bind registration is skipped when no redirect occurs, reducing redundant operations and log noise.
