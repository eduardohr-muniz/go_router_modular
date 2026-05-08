## 5.1.0

### Improved

- **Dependency injection — code review follow-ups**:
  - Centralised the dual-map invariant (unkeyed binds in `bindsMap[type]`, keyed binds in `bindsMapByKey[key]`) into a single helper (`_writeToCanonicalSlot`); both the batch and legacy single-bind paths now go through it.
  - Replaced the ambiguous `bool _handleExistingBind(...)` with a typed `_SlotConflictResolution` enum (`empty` / `routedToKeyMap` / `replaced`) so each call site reads what it actually does.
  - Renamed the per-batch buffer from `_pendingBatch` to `_uncommittedBatch` — disambiguates from `BindStorage.pendingObjectBinds` (a different, persistent queue).
  - Swallowed exceptions in registration and commit are now logged via `dart:developer.log` when `debugLogGoRouterModular` is enabled (previously fully silent), keeping zero overhead in release builds.
- **`BindLocator._searchCompatibleBind` — preserves singleton identity**: When `Injector.get<IAuthApi>()` resolves through a concrete singleton (`addSingleton((i) => AuthApiImpl())`), the locator now reuses the **canonical bind itself** instead of synthesising a `Bind<T>` wrapper that re-invoked the factory on every call. The previous wrapper silently broke singleton identity (each interface lookup yielded a fresh instance). Factory binds still get a typed delegate since each call must build a new instance anyway. Covered by `test/interface_resolution_regression_test.dart` ("compatibility lookup preserves singleton identity across interface and concrete").

- **Dependency injection — `registerBatch` / `commitBatch`**: Reworked how a module batch is registered so resolution matches the intent of “queue everything, then commit” without ad-hoc retry loops.
  - **Typed binds (`Bind<T>` with `T != Object`)** are indexed in `bindsMap` under the **declared** type up front in `registerBatch`. Another bind in the **same batch** can therefore call `i.get<T>()` in any declaration order (e.g. an `AppModule` singleton consuming a type provided by an imported module).
  - `commitBatch` runs in three phases: (1) materialize each canonical singleton **once** and index its `runtimeType` in `bindsMap` so interface lookup keeps working; (2) propagate `cachedInstance` to duplicate `Bind` objects created when imports re-execute `module.binds`, so `_mapBindsToIdentifiers`, logging, and validation never re-invoke factories; (3) fall back to the deferred path for `Bind<Object>` registrations.

### Fix

- **Dependency injection — `ConcurrentModificationError` during interface lookup**: `BindLocator._searchCompatibleBind` walked the live `bindsMap.entries` view while writing the resolved alias back into `bindsMap`. When a candidate's factory probe (`factoryFunction(Injector())`) recursively triggered another compatibility lookup that wrote into `bindsMap` and the outer iterator still had work to do, the next `moveNext()` raised `Concurrent modification during iteration`. The locator now iterates a snapshot of the entries (`List<MapEntry<Type, Bind>>.of(_storage.bindsMap.entries)`), making the write inside the loop safe under nested resolution. Covered by `test/concurrent_modification_regression_test.dart`.
- **Dependency injection — singleton instantiated multiple times via imports**: Modules that re-imported a bind already registered upstream produced new `Bind` instances with empty `cachedInstance`; downstream introspection (`_mapBindsToIdentifiers`, `_logRegisteredBinds`, `_validateModuleBinds`) called the factory again, leading to duplicated constructions (3× in production traces).
- **Dependency injection — `Injector.get<IService>()` after typed registration**: Registering a singleton with an explicit generic (e.g. `i.addSingleton<IAuthApi>((i) => AuthApiImpl())`) now keeps the bind reachable through both the interface and the concrete `runtimeType`, including when factories elsewhere in the graph delegate via `get<Concrete>()`.
- **Dependency injection — concrete singleton with interface lookup**: Restored the legacy guarantee that an untyped registration like `i.addSingleton((i) => AuthApiImpl())` resolves through any interface it satisfies (`Injector.get<IAuthApi>()`) via `BindLocator._searchCompatibleBind`. The previous attempt to skip lazy factories in `commitBatch` left the `runtimeType` out of `bindsMap`, breaking interface lookup for downstream modules and causing `Bind not found for type "IAuthApi"` after navigation. Covered by `test/interface_resolution_regression_test.dart`.
- **Dependency injection — keyed + unkeyed singleton on the same type**: When a module registers both a keyed singleton and an unkeyed singleton for the same interface (e.g. `IClient` with `key: 'paip-api'` and another `IClient` without key), `bindsMap[type]` now holds **only** the unkeyed bind; keyed binds live exclusively in `bindsMapByKey`. The previous registration order was order-sensitive: when the keyed bind was declared first it took the unkeyed slot, and `BindLocator._searchByType` (which skips keyed slots for unkeyed lookups) returned `null`, breaking `Injector.get<IClient>()` and any downstream factory depending on it. Covered by `test/keyed_and_unkeyed_same_type_test.dart`.
- **Routing — `StatefulShell` + `go_transitions`**: `StatefulShellModularRoute` integrates with **`go_transitions`**: configurable branch switching via `StatefulShellBranchTransitions.withGoTransition` (aligned with `GoTransitionRoute` / `GoTransition.defaultDuration`), optional `navigatorContainerBuilder` override, and `Modular.configure`’s `defaultTransitionDuration` / `defaultTransition` feeding shell branch transitions when durations are omitted.

### Added

- **Stateful shell branch transitions**: Helpers in `StatefulShellBranchTransitions` (e.g. `withGoTransition`, fade presets) so bottom tabs / branches can reuse the same transition style as modular `GoRoute`s.

## 5.0.6

### Fix

  **Root cause**: `_collectImportedBinds` calls `module.binds(injector)` on every module registration pass, creating new `Bind` objects with `cachedInstance == null`. `commitBatch` correctly skipped those duplicates via the fast-path (`_isSingletonAlreadyRegistered`), but did **not** propagate `cachedInstance` to the new `Bind` object. Downstream methods `_mapBindsToIdentifiers` and `_validateModuleBinds` use `bind.cachedInstance ?? bind.factoryFunction(...)`, so they fell back to calling the factory — executing the constructor 2 extra times.

  **Fix**: when `commitBatch` skips a duplicate bind, it now sets `bind.cachedInstance` from the already-registered bind (`_storage.bindsMap[bind.type]?.cachedInstance`), preventing any further factory calls for that `Bind` object.

- **Dependency Injection**: Fixed orphaned singleton instances when two imported modules declare the same bind type.

  When `Module A` imports both `Module B` and `Module C`, and both declare the same type `Y`, the previous implementation called the factory of `Y_C` even though `Y_B` was already registered (the `_isSingletonAlreadyRegistered` guard fired *after* `_processInstance`). The factory was called, the instance was created and cached in the `Bind` object, but never stored in `bindsMap` — creating a leaked singleton (open streams, duplicate subscriptions, resource conflicts).

  **Fix**: `commitBatch` now checks `_isSingletonAlreadyRegistered` **before** calling `factoryFunction` for typed binds (`bind.type != Object`), completely preventing the duplicate factory call.

## 5.0.5

### Fix

- **Dependency Injection**: Fixed issue where singleton and lazySingleton constructors were called multiple times during module registration. Now the system correctly reuses the cached instance after the first creation for type discovery.

## 5.0.4

### Fix

- **onExit in ChildRoute**: Fixed propagation of `onExit` callback in all route creation paths

## 5.0.3

### Added

- **Advanced Error Reporting**: Enhanced dependency injection error messages with detailed context
  - Clear identification of which component requested the missing dependency
  - Full dependency chain visualization (e.g., `A ➔ B ➔ C`) for easier debugging
  - Specific error messages for missing keys

- **Infinite Loop Prevention**: Robust protection against circular dependencies and search loops
  - Detects and prevents infinite recursion during bind resolution
  - Provides clear error messages with actionable feedback when a loop is detected
  - Automatic cleanup of search state in case of failures

- **Robust Resource Cleanup**: Enhanced `CleanBind` for safer instance disposal
  - Improved detection and execution of cleanup methods (`dispose`, `close`, `cancel`)
  - Safe handling of `NoSuchMethodError` for better compatibility with different instance types
  - Better logging for failed cleanup attempts

### Improved

- **Testing Infrastructure**: Added comprehensive test suite for complex dependency scenarios
  - Validates error reporting accuracy for multiple missing dependencies
  - Ensures reliable loop detection and prevention
  - Verifies correct dependency chain tracking

## 5.0.2

### Improved

- **Dependency Injection**: Changed from nested search to commit-based approach for improved performance

## 5.0.1

### Feat

- **New Lazy Singleton Support**: Added `Bind.lazySingleton()` method for efficient lazy initialization
  - Creates singleton instances only when first accessed
  - Perfect for expensive resources that may not always be needed
  - Maintains singleton behavior while improving startup performance
  - Example:
    ```dart
    i.lazySingleton<ExpensiveService>((i) => ExpensiveService());
    ```

- **Enhanced Bind Static Methods**: Comprehensive test coverage for all bind registration methods
  - Added unit tests for `Bind.add`, `Bind.factory`, `Bind.singleton`, and `Bind.lazySingleton`
  - Validates proper singleton behavior and factory patterns
  - Ensures correct key isolation and instance management

- **Beautiful Page Transitions**: Comprehensive transition system for smooth page animations
  - Built-in transitions: fade, slide, scale, rotate, and more
  - Smart inheritance: child routes automatically inherit transitions from parent modules
  - Easy customization with duration and curve parameters
  - Platform-specific styles: Cupertino (iOS/macOS) and Material (Android)
  - Combined effects: chain multiple transitions like `slide.toRight.withFade`
  - Module-level transitions: set transitions for all routes in a module
  - Route-level overrides: customize transitions for specific routes
  - Example:

    ```dart
    // Module-level transition
    ModuleRoute('/home', module: HomeModule(),
      transition: GoTransitions.fadeUpwards,
      duration: Duration(milliseconds: 300))

    // Child route inherits or overrides
    ChildRoute('/details', child: (_, __) => DetailsPage(),
      transition: GoTransitions.slide.toRight.withFade)

    // Platform-specific
    ModuleRoute('/ios', module: IOSModule(),
      transition: GoTransitions.cupertino)
    ```

### Improved

- **Test Coverage**: Expanded test suite for dependency injection system
  - Complete validation of factory vs singleton vs lazySingleton patterns
  - Key-based isolation testing
  - Instance reuse verification across all bind types

## 5.0.0

### Breaking Changes

- **Completely Redesigned Dependency Injection System**: Built from the ground up for maximum performance and reliability
  - **BREAKING**: Changed from `FutureOr<List<Bind<Object>>> binds()` to `FutureBinds binds(Injector i)`
  - **BREAKING**: Binds are now registered using injector methods instead of returning a list
  - Removed dependency on external auto_injector package
  - Native injector implementation for better control and performance

### Added

- **New Injector API**: Revolutionary dependency injection approach
  - Direct registration methods: `i.add()`, `i.addSingleton()`, `i.addLazySingleton()`
  - Function-based registration instead of list-based
  - Better type inference and compile-time checks
  - Example:
    ```dart
    @override
    FutureBinds binds(Injector i) {
      i.add<ApiService>((i) => ApiService());
      i.addSingleton<DatabaseService>((i) => DatabaseService());
      i.addLazySingleton<ExpensiveService>((i) => ExpensiveService());
    }
    ```

- **Performance Improvements**: Massive performance gains across the board
  - **4x faster** dependency resolution and injection
  - Optimized type discovery and instance creation
  - Reduced memory overhead and improved garbage collection

- **Enhanced Type Inference**: Significantly improved type safety
  - Better compile-time error detection
  - Enhanced type inference throughout the system
  - Clearer error messages for type mismatches

- **Robust Error Handling**: Improved reliability and debugging
  - Better error handling throughout the dependency injection pipeline
  - Enhanced dependency cycle detection
  - More informative error messages with actionable feedback

### Migration Guide

- **Before (v4.x):**

  ```dart
  class MyModule extends Module {
    @override
    FutureOr<List<Bind<Object>>> binds() => [
      Bind.factory<ApiService>((i) => ApiService()),
      Bind.singleton<DatabaseService>((i) => DatabaseService()),
    ];
  }
  ```

- **After (v5.x):**
  ```dart
  class MyModule extends Module {
    @override
    FutureBinds binds(Injector i) {
      i.add<ApiService>((i) => ApiService());
      i.addSingleton<DatabaseService>((i) => DatabaseService());
    }
  }
  ```

### Benefits

- ✅ **4x faster performance** - Optimized dependency resolution and injection
- ✅ **Better async support** - Native support for asynchronous bind initialization
- ✅ **Improved type inference** - Enhanced type safety with better compile-time checks
- ✅ **More robust** - Better error handling and dependency cycle detection
- ✅ **Cleaner syntax** - More intuitive API without Bind wrapper overhead
- ✅ **Same functionality** - All features preserved with better performance

### Technical Details

- Complete rewrite of dependency injection system
- Removed external dependency on auto_injector
- Native implementation provides better control and optimization opportunities
- Improved memory management and resource cleanup
- Enhanced modular architecture support

## 4.2.2

### Improved

- Improved the dispose process to ensure proper resource release and prevent memory leaks.

## 4.2.0+4

### Fix

- Added validation to prevent overwriting already registered singletons for the same type and key, avoiding multiple instances and preserving the expected singleton behavior.

## 4.2.0+3

### Feat

- Update Readme

## 4.2.0

### Feat

- **Enhanced Event Broadcasting**: Improved Module event system with broadcast capabilities
  - Added support for broadcasting events across multiple modules
  - Enhanced event propagation and subscription management
  - Better integration with module lifecycle

### Improved

- **Error Messages**: Enhanced error messages throughout the system
  - More descriptive and user-friendly error messages
  - Better debugging information for dependency injection issues
  - Clearer guidance for common configuration mistakes
  - Improved exception handling with actionable feedback

## 4.1.0

### Fix

- Added nullable context in EventModule to handle web scenarios where context might not be available during page refreshes or redirects

### Feat

- Added `autoDisposeEventBus` parameter in Modular.configure to customize whether events should be automatically disposed when modules are destroyed (default: true)

## 4.0.0+8

### Fix

Dispose AppModule

## 4.0.0

### Added

- **ModularApp.router**: New widget that extends MaterialApp.router with built-in loader system
  - Replaces MaterialApp.router for better integration with go_router_modular
  - **IMPORTANT**: `routerConfig` parameter is automatically set to `Modular.routerConfig` - no need to specify it
  - Automatic loader management during module registration
  - Customizable loader appearance through CustomModularLoader
  - Example:
    ```dart
    return ModularApp.router(
      customModularLoader: MyCustomLoader(),
      title: 'My App',
    );
    ```

- **ModularLoader System**: Built-in loading system with ValueNotifier
  - Automatic loader display during module dependency injection
  - Manual control with `ModularLoader.show()` and `ModularLoader.hide()`
  - Customizable appearance through CustomModularLoader abstract class
  - Stack-based implementation for reliable overlay display
  - Example:

    ```dart
    // Manual control
    ModularLoader.show();
    ModularLoader.hide();

    // Custom loader
    class MyCustomLoader extends CustomModularLoader {
      @override
      Color get backgroundColor => Colors.black87;

      @override
      Widget get child => const CircularProgressIndicator();
    }
    ```

- **CustomModularLoader**: Abstract class for customizing loader appearance
  - `backgroundColor` getter for background color customization
  - `child` getter for custom widget display
  - Seamless integration with ModularApp.router

### Breaking Changes

- **ModularApp.router**: Replace MaterialApp.router with ModularApp.router
  - Required for loader system integration
  - Maintains all MaterialApp.router functionality
  - **BREAKING**: `routerConfig` parameter is automatically set - remove it from your code
  - Adds customModularLoader parameter for customization

- **Async Binds and Imports**: Module methods now support async operations
  - **BREAKING**: `binds()` and `imports()` now return `FutureOr<List<T>>` instead of `List<T>`
  - Allows for async dependency injection and module imports
  - Better support for dynamic module loading and configuration
  - Example migration:

    ```dart
    // Before (3.x):
    @override
    List<Bind<Object>> get binds => [
      Bind.singleton<MyService>((i) => MyService()),
    ];

    @override
    List<Module> get imports => [SharedModule()];

    // After (4.x):
    @override
    FutureOr<List<Bind<Object>>> binds() => [
      Bind.singleton<MyService>((i) => MyService()),
    ];

    @override
    FutureOr<List<Module>> imports() => [SharedModule()];
    ```

- **Loader API Changes**: Updated loader system implementation
  - Removed ModularLoaderNotification system
  - Replaced with ValueNotifier-based approach
  - Simplified API with direct show/hide methods

### Migration Guide

- **Before (3.x):**

  ```dart
  // AppWidget
  return MaterialApp.router(
    routerConfig: Modular.routerConfig, // ❌ Remove this
    title: 'My App',
  );

  // Module
  class UserModule extends Module {
    @override
    List<Bind<Object>> get binds => [ // ❌ Change to async method
      Bind.singleton<UserService>((i) => UserService()),
    ];

    @override
    List<Module> get imports => [ // ❌ Change to async method
      SharedModule()
    ];
  }
  ```

- **After (4.x):**

  ```dart
  // AppWidget
  return ModularApp.router(
    title: 'My App', // ✅ routerConfig is automatic
  );

  // Module
  class UserModule extends Module {
    @override
    FutureOr<List<Bind<Object>>> binds() => [ // ✅ Async method
      Bind.singleton<UserService>((i) => UserService()),
    ];

    @override
    FutureOr<List<Module>> imports() => [ // ✅ Async method
      SharedModule()
    ];
  }
  ```

### Improved

- **Performance**: Optimized loader system with ValueNotifier
  - Reactive updates without complex notification system
  - Reduced memory usage and improved performance
  - Better integration with Flutter's widget lifecycle

- **Reliability**: Enhanced loader display reliability
  - Stack-based implementation prevents overlay issues
  - Automatic context management
  - Better error handling and fallbacks

### Technical Details

- Replaced complex InheritedWidget + Notification system with simple ValueNotifier
- Implemented Stack-based loader overlay for consistent display
- Added automatic loader during module registration process
- Enhanced ModularApp.router with built-in loader management
- **Automatic routerConfig**: ModularApp.router automatically sets routerConfig to Modular.routerConfig
- **Async Module Support**: Binds and imports now support async operations for dynamic loading

  ```dart
  // Example of async binds
  @override
  FutureOr<List<Bind<Object>>> binds() async {
    final config = await loadConfigFromServer();
    return [
      Bind.singleton<ConfigService>((i) => ConfigService(config)),
    ];
  }

  // Example of async imports
  @override
  FutureOr<List<Module>> imports() async {
    if (await shouldLoadFeatureModule()) {
      return [FeatureModule()];
    }
    return [];
  }
  ```

## 3.0.0

### Breaking Changes

- **Root Route Handling**: Changed behavior for "/" route in modules
  - Modules must now have a root ChildRoute ("/") as it serves as the parent route
  - This route acts as the module's entry point and container for nested routes
  - Assertion error will be thrown if root route is missing
  - Example:
    ```dart
    @override
    List<ModularRoute> get routes => [
      ChildRoute('/', child: (_, __) => HomePage()), // Required root route
      ChildRoute('/details', child: (_, __) => DetailsPage()),
    ];
    ```

### Fixed

- **Module Route Structure**: Improved module route hierarchy validation
  - Added assertion check for required root route in modules
  - Better error messages to help developers implement correct route structure
  - Enhanced documentation around module route requirements

## 2.0.3+1

### Added

- **Lifecycle Methods**: Added support for initState and dispose methods in modules
- **Recursive Import**: Implemented recursive binding imports between modules

### Fixed

- **Auto Dispose**: Fixed auto dispose mechanism to ensure proper resource cleanup
- **State Management**: Improved module state management during lifecycle

## 2.0.2+1

### Added

- **Debug Logging**: Added comprehensive debug logging system for route registration and bind management
  - New `InternalLogs` class for consistent debug output
  - Detailed logs for `_register`, `_recursiveRegisterBinds`, `registerBindsIfNeeded`, and `_handleRouteExit` functions
  - Enhanced visibility into module lifecycle and dependency injection process

### Fixed

- **Redirect Bind Registration**: Fixed issue where `_register` function was not being called during route redirects
  - Modified `ChildRoute._createChild` to register binds before redirect evaluation
  - Modified `ModuleRoute._createModule` to register binds before redirect evaluation
  - Modified `ShellRoute._createShellRoutes` to register binds before redirect evaluation
  - Ensures dependencies are properly injected before page construction during redirects

### Improved

- **Performance Optimization**: Optimized bind registration to avoid unnecessary registrations
  - Only register binds when an actual redirect occurs (redirectResult != null)
  - Prevents duplicate module registrations and improves performance
  - Reduces noise in debug logs by eliminating redundant operations

### Technical Details

- Enhanced route creation workflow to ensure proper dependency injection timing
- Improved module lifecycle management with better dispose handling for unused modules
- Added safeguards to prevent bind registration conflicts and circular dependencies

## 0.0.1

- TODO: Describe initial release.
