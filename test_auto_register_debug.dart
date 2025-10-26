import 'package:auto_injector/auto_injector.dart';

abstract class IClient {
  void makeRequest();
}

class ClientDio implements IClient {
  final String baseUrl;
  ClientDio({required this.baseUrl});
  
  @override
  void makeRequest() {
    print('Making request to $baseUrl');
  }
}

void main() {
  final injector = AutoInjector();
  
  // Registrar ClientDio
  injector.addLazySingleton<ClientDio>(() => ClientDio(baseUrl: 'test'));
  
  // Registrar IClient apontando para ClientDio (auto-registro)
  injector.addLazySingleton<dynamic>(
    () => injector.get<ClientDio>(),
    key: 'IClient',
  );
  
  injector.commit();
  
  // Tentar resolver IClient pelo KEY
  try {
    final client = injector.get<dynamic>(key: 'IClient');
    print('✅ IClient resolved by key: ${client.runtimeType}');
  } catch (e) {
    print('❌ Failed to resolve IClient by key: $e');
  }
  
  // Tentar resolver IClient por TIPO
  try {
    final client = injector.get<IClient>();
    print('✅ IClient resolved by type: ${client.runtimeType}');
  } catch (e) {
    print('❌ Failed to resolve IClient by type: $e');
  }
}
