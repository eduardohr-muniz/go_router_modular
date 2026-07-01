/// Normalização pura de paths de rota modular.
///
/// Extraído de `route_builder.dart` para isolar a responsabilidade de path
/// (Single Responsibility). Funções puras, sem dependências de roteamento.
class RoutePathNormalizer {
  const RoutePathNormalizer._();

  /// Trata um path como índice (`/`) quando é a raiz ou um parâmetro (`/:`).
  static String adjustRoute(String route) {
    if (route == "/") return "/";
    if (route.startsWith("/:")) return "/";
    return route;
  }

  /// Normaliza o path conforme o nível: top-level mantém a barra inicial,
  /// aninhado a remove (exceto parâmetros `/:`); compacta barras e remove a final.
  static String normalizePath({required String path, required bool topLevel}) {
    if (path.startsWith("/") && !topLevel && !path.startsWith("/:")) {
      path = path.substring(1);
    }
    return _parsePath(path);
  }

  static String _parsePath(String path) {
    if (!path.endsWith('/')) path = '$path/';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path == '/') return path;
    return path.substring(0, path.length - 1);
  }
}
