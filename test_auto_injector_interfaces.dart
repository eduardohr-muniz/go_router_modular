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
  
  // Registrar apenas ClientDio
  injector.addSingleton<ClientDio>(() => ClientDio(baseUrl: 'test'));
  
  injector.commit();
  
  // Tentar resolver IClient
  try {
    final client = injector.get<IClient>();
    print('✅ IClient resolved: ${client.runtimeType}');
  } catch (e) {
    print('❌ Failed to resolve IClient: $e');
  }
  
  // Tentar resolver ClientDio
  try {
    final clientDio = injector.get<ClientDio>();
    print('✅ ClientDio resolved: ${clientDio.runtimeType}');
  } catch (e) {
    print('❌ Failed to resolve ClientDio: $e');
  }
}
