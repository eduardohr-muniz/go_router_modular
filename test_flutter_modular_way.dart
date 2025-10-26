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
  
  // Registrar ClientDio como TIPO ClientDio
  injector.addSingleton<ClientDio>(() => ClientDio(baseUrl: 'test'));
  
  // Registrar ClientDio como TIPO IClient também!
  injector.addSingleton<IClient>(() => ClientDio(baseUrl: 'test'));
  
  injector.commit();
  
  // Agora ambos funcionam!
  final clientDio = injector.get<ClientDio>();
  print('✅ ClientDio: ${clientDio.runtimeType}');
  
  final client = injector.get<IClient>();
  print('✅ IClient: ${client.runtimeType}');
  
  // São a mesma instância?
  print('Same instance: ${identical(clientDio, client)}');
}
