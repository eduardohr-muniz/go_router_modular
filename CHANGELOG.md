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
