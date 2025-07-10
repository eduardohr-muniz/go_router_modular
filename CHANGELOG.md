

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
