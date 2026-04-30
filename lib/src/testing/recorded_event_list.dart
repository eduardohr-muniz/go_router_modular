/// Coleção de primeira classe para eventos capturados durante testes.
///
/// Object Calisthenics:
///   - Encapsula `List<E>` (coleção de primeira classe — Regra 4)
///   - Uma única variável de instância (Regra 8)
///   - Sem getters/setters de mutação expostos (Regra 9)
class RecordedEventList<E> {
  final List<E> _events;

  const RecordedEventList(List<E> events) : _events = events;

  RecordedEventList.empty() : _events = [];

  int get length => _events.length;

  bool get isEmpty => _events.isEmpty;

  bool get isNotEmpty => _events.isNotEmpty;

  E get first => _events.first;

  E get last => _events.last;

  E operator [](int index) => _events[index];

  bool any(bool Function(E event) predicate) => _events.any(predicate);

  RecordedEventList<E> where(bool Function(E event) predicate) {
    return RecordedEventList(_events.where(predicate).toList());
  }

  List<E> toList() => List.unmodifiable(_events);
}
