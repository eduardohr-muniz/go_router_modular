class GoRouterModularException implements Exception {
  final String message;
  final String? stackTrace;

  GoRouterModularException(this.message, {this.stackTrace});

  @override
  String toString() {
    return 'GoRouterModularException: $message\n$stackTrace';
  }
}
