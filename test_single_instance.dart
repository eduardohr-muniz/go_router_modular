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
  
  // Primeiro registrar ClientDio
  injector.addSingleton<ClientDio>(() => ClientDio(baseUrl: 'test'));
  
  // Depois registrar IClient apontando para ClientDio já registrado
  injector.addLazySingleton<IClient>(() => injector.get<ClientDio>());
  
  injector.commit();
  
  // Agora ambos funcionam e são a mesma instância!
  final clientDio = injector.get<ClientDio>();
  print('✅ ClientDio: ${clientDio.runtimeType}');
  
  final client = injector.get<IClient>();
  print('✅ IClient: ${client.runtimeType}');
  
  // São a mesma instância?
  print('Same instance: ${identical(clientDio, client)}');
}
