library go_router_modular;

export 'src/bind.dart';
export 'src/utils/context_extension.dart';
export 'src/utils/exception.dart';
export 'src/go_router_modular_configure.dart';
export 'src/module.dart';
export 'src/utils/injector.dart';
export 'src/utils/page_transition_enum.dart';
export 'src/injections_manager.dart';
export 'src/routes/route_model.dart';
export 'src/utils/transition.dart';
export 'src/routes/child_route.dart';
export 'src/routes/i_modular_route.dart';
export 'src/routes/module_route.dart';
export 'src/routes/shell_modular_route.dart';
export 'package:go_router/go_router.dart' hide GoRouter, ShellRoute;
export 'package:go_router_modular/src/utils/material_app_router.dart';
export 'package:go_router_modular/src/utils/modular_loader.dart';

// Event System exports
export 'src/utils/event_module.dart' show EventModule, ModularEvent;
export 'package:event_bus/event_bus.dart';
