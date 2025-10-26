library go_router_modular;

// Core exports
export 'src/core/bind/bind.dart';
export 'src/core/go_router_modular_configure.dart';
export 'src/core/module/module.dart';
export 'src/core/injection_manager/injection_manager.dart';

// Dependency Injection exports
export 'src/di/injector.dart';

// Routing exports
export 'src/routing/route_model.dart';
export 'src/routing/child_route.dart';
export 'src/routing/i_modular_route.dart';
export 'src/routing/module_route.dart';
export 'src/routing/shell_modular_route.dart';

// Extensions exports
export 'src/extensions/context_extension.dart';
export 'src/extensions/route_extension.dart';

// Exceptions exports
export 'src/exceptions/exception.dart';

// Widgets exports
export 'src/widgets/material_app_router.dart';
export 'src/widgets/modular_loader.dart';

// Event System exports
export 'src/events/event_module.dart' show EventModule, ModularEvent;

// External packages
export 'package:go_router/go_router.dart' hide ShellRoute;
export 'package:event_bus/event_bus.dart';
export 'package:go_transitions/go_transitions.dart';
export 'package:auto_injector/auto_injector.dart' show AutoInjector;
