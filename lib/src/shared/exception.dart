class ModularException implements Exception {
  final String message;
  final String? stackTrace;

  ModularException(this.message, {this.stackTrace});

  @override
  String toString() {
    return 'ModularException: $message\n$stackTrace';
  }
}
