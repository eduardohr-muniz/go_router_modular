library go_router_modular;

// Core exports
export 'src/di/bind.dart';
export 'src/bootstrap/modular_configure.dart';
export 'src/routing/route_with_completer_service.dart';
export 'src/routing/modular_router_runtime.dart' show modularNavigatorKey;
export 'src/module/module.dart';
export 'src/di/injection_manager.dart';

// Dependency Injection exports
export 'src/di/injector.dart';

// Routing exports
export 'src/routing/child_route.dart';
export 'src/routing/i_modular_route.dart';
export 'src/routing/module_route.dart';
export 'src/routing/shell_modular_route.dart';
export 'src/routing/stateful_shell_modular_route.dart';
export 'src/routing/stateful_shell_branch_transitions.dart';
export 'src/routing/guards/route_guard.dart';
export 'src/routing/guards/guard_fn.dart';
export 'src/ui/context_extension.dart';
export 'src/ui/route_extension.dart';

// Exceptions exports
export 'src/shared/exception.dart';

// Widgets exports
export 'src/ui/material_app_router.dart';
export 'src/ui/modular_loader.dart';

// Event System exports
export 'src/events/modular_event.dart' show ModularEvent, clearEventModuleState, defaultModularEventBus;
export 'src/events/event_module.dart' show EventModule;

// External packages
export 'package:go_router/go_router.dart' hide GoRouter, ShellRoute;
export 'package:event_bus/event_bus.dart';
export 'package:go_transitions/go_transitions.dart' hide GoTransition;
export 'src/events/modular_event_mixin.dart' show ModularEventMixin;
