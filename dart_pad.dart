class RouteModularModel {
  String moduleR;
  String childR;
  String route;
  List<String>? params;
  Duration? d;

  RouteModularModel({
    required this.moduleR,
    required this.childR,
    required this.route,
    this.params,
    this.d = const Duration(milliseconds: 700),
  });

  @override
  String toString() {
    return 'RouteModularModel(moduleR: $moduleR, childR: $childR, route: $route, params: $params, d: $d)';
  }

  String go({List<String> params = const []}) {
    return _buildPath(route) + params.map((e) => "/$e").join("");
  }

  static RouteModularModel buildRoute({required String module, required String routeName, List<String> params = const []}) {
    final module_ = "/$module";
    final childRoute = "/${routeName == module ? "" : "$routeName/"}";
    final args_ = params.map((e) => ":$e").join("/");
    return RouteModularModel(
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

void main() {
  final home = RouteModularModel.buildRoute(module: "/home/", routeName: "/home/");
  final config = RouteModularModel.buildRoute(module: "/home/config/", routeName: "teste/", params: ["id"]);
  print(home.go(params: ['dudu']));
  print(config);
}
