import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  setUp(() async {
    // await InjectionManager.instance.clearAllForTesting();
  });

  tearDown(() async {
    // await InjectionManager.instance.clearAllForTesting();
  });

  test('✅ Teste: Interface com múltiplas implementações usando keys', () async {
    // Criar módulos
    final appModule = AppModuleTest();
    await InjectionManager.instance.registerAppModule(appModule);

    final escolaModule = EscolaModule();
    await InjectionManager.instance.registerBindsModule(escolaModule);

    // Definir contexto para Escola
    InjectionManager.instance.setModuleContext(EscolaModule);

    // 🎯 TESTE 1: Buscar com key "da-silva"
    try {
      final pessoaComKey = Modular.get<IPessoa>(key: 'da-silva');
      expect(pessoaComKey, isA<Joao>());
      expect(pessoaComKey.nome, 'João');
      expect(pessoaComKey.sobrenome, 'da Silva');
      print('✅ Busca com key "da-silva": ${pessoaComKey.nome} ${pessoaComKey.sobrenome}');
    } catch (e) {
      print('❌ Erro ao buscar com key: $e');
      rethrow;
    }

    // 🎯 TESTE 2: Buscar sem key (deve retornar o primeiro/sem key)
    try {
      final pessoaSemKey = Modular.get<IPessoa>();
      expect(pessoaSemKey, isA<Joao>());
      expect(pessoaSemKey.nome, 'João');
      expect(pessoaSemKey.sobrenome, 'Silva');
      print('✅ Busca sem key: ${pessoaSemKey.nome} ${pessoaSemKey.sobrenome}');
    } catch (e) {
      print('❌ Erro ao buscar sem key: $e');
      rethrow;
    }
  });
}

// ============ INTERFACES ============

/// Interface abstrata para pessoa
abstract class IPessoa {
  String get nome;
  String get sobrenome;
  String get nomeCompleto => '$nome $sobrenome';
}

// ============ IMPLEMENTAÇÕES ============

/// Implementação de João Silva
class Joao implements IPessoa {
  final String sobrenomeValue;

  Joao({this.sobrenomeValue = 'Silva'});

  @override
  String get nome => 'João';

  @override
  String get sobrenome => sobrenomeValue;

  @override
  String get nomeCompleto => 'João $sobrenomeValue';
}

// ============ MÓDULOS ============

class AppModuleTest extends Module {
  @override
  void binds(Injector i) {
    // AppModule vazio
  }
}

class EscolaModule extends Module {
  @override
  void binds(Injector i) {
    // ✅ Registrar IPessoa SEM KEY primeiro (Silva - padrão)
    i.add<IPessoa>(() => Joao());

    // ✅ Registrar IPessoa COM KEY depois (da Silva)
    i.add<IPessoa>(() => Joao(sobrenomeValue: 'da Silva'), key: 'da-silva');

    print('📝 Registrado: IPessoa sem key primeiro, depois com key "da-silva"');
  }
}
