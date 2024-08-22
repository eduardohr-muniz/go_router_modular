import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/page_transition_enum.dart';

class RouteModel {
  String moduleR;
  String childR;
  String route;
  String name;
  List<String>? params;
  PageTransition pageTransition;
  RouteModel({
    required this.moduleR,
    required this.childR,
    required this.route,
    this.name = '',
    this.params,
    this.pageTransition = PageTransition.fade,
  });

  @override
  String toString() {
    return 'RouteModularModel(moduleR: $moduleR, childR: $childR, route: $route, params: $params, )';
  }

  String buildPath({List<String> subParams = const [], List<String> params = const []}) {
    // Adiciona os parâmetros entre moduleR e childR
    String paramPath = params.map((e) => "/$e").join("");
    String subParamPath = subParams.map((e) => "/$e").join("");
    int indexChildR = childR.contains("/:") ? childR.indexOf("/:") : childR.length;
    return _buildPath(moduleR + subParamPath + childR.substring(0, indexChildR) + paramPath);
  }

  static RouteModel build({required String module, required String routeName, List<String> params = const []}) {
    final module_ = "/$module";
    final childRoute = "/${routeName == module ? "" : "$routeName/"}";
    final args_ = params.map((e) => ":$e").join("/");
    return RouteModel(
        route: _buildPath("$module_${routeName == module ? "/" : childRoute}"),
        moduleR: _buildPath("$module_${module == "/" ? "" : "/"}"),
        childR: _buildPath(childRoute + args_),
        name: _extractName(routeName),
        params: params);
  }

  static String _extractName(String path) {
    final regex = RegExp(r'^/([^/]+)/?');
    final match = regex.firstMatch(path);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }

    return path;
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
