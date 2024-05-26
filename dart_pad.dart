abstract interface class ITeste {
  String getName();
}

class Teste implements ITeste {
  @override
  String getName() {
    return 'Teste';
  }
}

class Name {}

void main() {
  bool isType<T>(Object a) {
    return a is T;
  }

  print("Teste extende: ${isType<ITeste>(Teste())}");
  print("Name extende: ${isType<ITeste>(Name())}");
}
