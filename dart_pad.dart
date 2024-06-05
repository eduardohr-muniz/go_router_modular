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

  String buildPath({List<String> subParams = const [], List<String> params = const []}) {
    // Adiciona os parâmetros entre moduleR e childR
    String paramPath = params.map((e) => "/$e").join("");
    String subParamPath = subParams.map((e) => "/$e").join("");
    int indexChildR = childR.contains("/:") ? childR.indexOf("/:") : childR.length;
    return _buildPath(moduleR + subParamPath + childR.substring(0, indexChildR) + paramPath);
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
  final menu = RouteModularModel.buildRoute(module: "/menu", routeName: "/:id", params: ['id']);
  final teste = RouteModularModel.buildRoute(module: "/menu", routeName: "teste");
  final config = RouteModularModel.buildRoute(module: "/home/config/", routeName: "teste/", params: ["id"]);
  print(menu.buildPath(params: ['dudu'], subParams: ["oi"]));
  print(teste.buildPath(subParams: ["oi"]));
  // print(config);
}
