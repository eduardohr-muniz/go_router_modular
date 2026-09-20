class BindIdentifier {
  final Type type;
  final String? key;

  const BindIdentifier(this.type, [this.key]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BindIdentifier && other.type == type && other.key == key;
  }

  @override
  int get hashCode => type.hashCode ^ (key?.hashCode ?? 0);

  /// Stable label for diagnostics and telemetry: `HomeService`, or
  /// `HomeService (key: cart)` when the bind is keyed.
  ///
  /// Separate from [toString] on purpose: this one is part of the payload the
  /// host app receives through `onTelemetry`, so it must not drift with the
  /// package's debug formatting.
  String get label => key == null || key == type.toString() ? '$type' : '$type (key: $key)';

  @override
  String toString() => '$type(${key != null ? (key == type.toString() ? '' : 'key: $key') : ''})';
}
