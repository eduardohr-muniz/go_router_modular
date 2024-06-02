import 'package:go_router_modular/go_router_modular.dart';

class RouteModel {
  String moduleR;
  String childR;
  String route;
  List<String>? params;
  PageTransition pageTransition;
  RouteModel({
    required this.moduleR,
    required this.childR,
    required this.route,
    this.params,
    this.pageTransition = PageTransition.fade,
  });

  @override
  String toString() {
    return 'RouteModularModel(moduleR: $moduleR, childR: $childR, route: $route, params: $params, )';
  }

  String go([List<String> params = const []]) {
    return _buildPath(route) + params.map((e) => "/$e").join("");
  }

  static RouteModel build({required String module, required String routeName, List<String> params = const []}) {
    final module_ = "/$module";
    final childRoute = "/${routeName == module ? "" : "$routeName/"}";
    final args_ = params.map((e) => ":$e").join("/");
    return RouteModel(
        route: _buildPath("$module_${routeName == module ? "/" : childRoute}"),
        moduleR: _buildPath("$module_${module == "/" ? "" : "/"}"),
        childR: _buildPath(childRoute + args_),
        params: params);
  }

  static String _buildPath(String path) {
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
