## 5.0.0

### Breaking Changes
* **Dependency Injection System**: Migrated from custom injection system to GetIt
  - Migration examples:
    ```dart
    // Before (4.2.x):
    @override
    List<Bind<Object>> get binds => [
      Bind.singleton<MyService>((i) => MyService()),
      Bind.factory<ApiService>((i) => ApiService()),
    ];
    final service = Modular.get<MyService>();
    
    // After (4.3.x):
    @override
   FutureBinds binds(Injector i) {
      i.addLazySingleton<MyService>(() => MyService());
      i.add<ApiService>(() => ApiService());
    }

    ```
### Added
* **Enhanced Dependency Injection**: New `Bind.get<T>()` API with key support
  - Support for retrieving dependencies with unique keys
  - Better type safety and error handling
  - Improved service composition capabilities
  - Example:
    ```dart
    // Register with key
    Bind.register(Bind.singleton<ApiService>((i) => ApiService(), key: 'api'));
    
    // Retrieve with key
    final apiService = Bind.get<ApiService>(key: 'api');
    ```

* **Advanced Transition System**: Integrated go_transitions package
  - Rich set of built-in transitions (fade, slide, scale, rotate, etc.)
  - Transition inheritance system (child routes inherit from parent modules)
  - Customizable duration and curve settings
  - Example:
    ```dart
    // Module with transition
    ModuleRoute('/', module: HomeModule(), 
      transition: GoTransitions.fadeUpwards, 
      duration: Duration(milliseconds: 300))
    
    // Child route inherits or overrides
    ChildRoute('/details', child: (_, __) => DetailsPage(),
      transition: GoTransitions.slide.toRight.withFade)
    ```

### Improved
* **Performance**: Optimized dependency injection with GetIt
  - Faster dependency resolution
  - Better memory management
  - Reduced overhead in dependency lookup

* **Developer Experience**: Enhanced transition system
  - More intuitive transition configuration
  - Better error messages for transition issues
  - Comprehensive transition inheritance

## 4.2.2
### Improved
* Improved the dispose process to ensure proper resource release and prevent memory leaks.

## 4.2.0+4
### Fix
* Added validation to prevent overwriting already registered singletons for the same type and key, avoiding multiple instances and preserving the expected singleton behavior.

## 4.2.0+3
### Feat
  - Update Readme

## 4.2.0

### Feat
* **Enhanced Event Broadcasting**: Improved Module event system with broadcast capabilities
  - Added support for broadcasting events across multiple modules
  - Enhanced event propagation and subscription management
  - Better integration with module lifecycle

### Improved
* **Error Messages**: Enhanced error messages throughout the system
  - More descriptive and user-friendly error messages
  - Better debugging information for dependency injection issues
  - Clearer guidance for common configuration mistakes
  - Improved exception handling with actionable feedback

## 4.1.0
### Fix
* Added nullable context in EventModule to handle web scenarios where context might not be available during page refreshes or redirects

### Feat
* Added `autoDisposeEventBus` parameter in Modular.configure to customize whether events should be automatically disposed when modules are destroyed (default: true)

## 4.0.0+8

### Fix
 Dispose AppModule

## 4.0.0

### Added
* **ModularApp.router**: New widget that extends MaterialApp.router with built-in loader system
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

* **ModularLoader System**: Built-in loading system with ValueNotifier
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

* **CustomModularLoader**: Abstract class for customizing loader appearance
  - `backgroundColor` getter for background color customization
  - `child` getter for custom widget display
  - Seamless integration with ModularApp.router

### Breaking Changes
* **ModularApp.router**: Replace MaterialApp.router with ModularApp.router
  - Required for loader system integration
  - Maintains all MaterialApp.router functionality
  - **BREAKING**: `routerConfig` parameter is automatically set - remove it from your code
  - Adds customModularLoader parameter for customization

* **Async Binds and Imports**: Module methods now support async operations
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
    FutureModules imports() => [SharedModule()];
    ```

* **Loader API Changes**: Updated loader system implementation
  - Removed ModularLoaderNotification system
  - Replaced with ValueNotifier-based approach
  - Simplified API with direct show/hide methods

### Migration Guide
* **Before (3.x):**
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

* **After (4.x):**
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
    FutureModules imports() => [ // ✅ Async method
      SharedModule()
    ];
  }
  ```

### Improved
* **Performance**: Optimized loader system with ValueNotifier
  - Reactive updates without complex notification system
  - Reduced memory usage and improved performance
  - Better integration with Flutter's widget lifecycle

* **Reliability**: Enhanced loader display reliability
  - Stack-based implementation prevents overlay issues
  - Automatic context management
  - Better error handling and fallbacks

### Technical Details
* Replaced complex InheritedWidget + Notification system with simple ValueNotifier
* Implemented Stack-based loader overlay for consistent display
* Added automatic loader during module registration process
* Enhanced ModularApp.router with built-in loader management
* **Automatic routerConfig**: ModularApp.router automatically sets routerConfig to Modular.routerConfig
* **Async Module Support**: Binds and imports now support async operations for dynamic loading
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
  FutureModules imports() async {
    if (await shouldLoadFeatureModule()) {
      return [FeatureModule()];
    }
    return [];
  }
  ```

## 3.0.0

### Breaking Changes
* **Root Route Handling**: Changed behavior for "/" route in modules
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
* **Module Route Structure**: Improved module route hierarchy validation
  - Added assertion check for required root route in modules
  - Better error messages to help developers implement correct route structure
  - Enhanced documentation around module route requirements

## 2.0.3+1

### Added
* **Lifecycle Methods**: Added support for initState and dispose methods in modules
* **Recursive Import**: Implemented recursive binding imports between modules

### Fixed
* **Auto Dispose**: Fixed auto dispose mechanism to ensure proper resource cleanup
* **State Management**: Improved module state management during lifecycle


## 2.0.2+1

### Added
* **Debug Logging**: Added comprehensive debug logging system for route registration and bind management
  - New `InternalLogs` class for consistent debug output
  - Detailed logs for `_register`, `_recursiveRegisterBinds`, `registerBindsIfNeeded`, and `_handleRouteExit` functions
  - Enhanced visibility into module lifecycle and dependency injection process

### Fixed
* **Redirect Bind Registration**: Fixed issue where `_register` function was not being called during route redirects
  - Modified `ChildRoute._createChild` to register binds before redirect evaluation
  - Modified `ModuleRoute._createModule` to register binds before redirect evaluation  
  - Modified `ShellRoute._createShellRoutes` to register binds before redirect evaluation
  - Ensures dependencies are properly injected before page construction during redirects

### Improved
* **Performance Optimization**: Optimized bind registration to avoid unnecessary registrations
  - Only register binds when an actual redirect occurs (redirectResult != null)
  - Prevents duplicate module registrations and improves performance
  - Reduces noise in debug logs by eliminating redundant operations

### Technical Details
* Enhanced route creation workflow to ensure proper dependency injection timing
* Improved module lifecycle management with better dispose handling for unused modules
* Added safeguards to prevent bind registration conflicts and circular dependencies

## 0.0.1

* TODO: Describe initial release.
