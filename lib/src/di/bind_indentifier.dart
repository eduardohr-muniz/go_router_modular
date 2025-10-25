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

  @override
  String toString() => '$type(${key != null ? (key == type.toString() ? '' : 'key: $key') : ''})';
}
