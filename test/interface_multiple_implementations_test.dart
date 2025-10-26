import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  setUp(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  tearDown(() async {
    await InjectionManager.instance.clearAllForTesting();
  });

  test('✅ Teste: Interface com Múltiplas Implementações (Maria e João)', () async {
    // Criar módulos
    final appModule = AppModuleTest();
    await InjectionManager.instance.registerAppModule(appModule);

    final escolaModule = EscolaModule();
    await InjectionManager.instance.registerBindsModule(escolaModule);

    final trabalhoModule = TrabalhoModule();
    await InjectionManager.instance.registerBindsModule(trabalhoModule);

    // Definir contexto para Escola
    InjectionManager.instance.setModuleContext(EscolaModule);

    // Escola deve acessar IPessoa -> Maria
    final pessoaNaEscola = Modular.get<IPessoa>();
    expect(pessoaNaEscola, isA<Maria>());
    expect(pessoaNaEscola.nome, 'Maria');
    expect(pessoaNaEscola.idade, 10);

    // Definir contexto para Trabalho
    InjectionManager.instance.setModuleContext(TrabalhoModule);

    // Trabalho deve acessar IPessoa -> João
    final pessoaNoTrabalho = Modular.get<IPessoa>();
    expect(pessoaNoTrabalho, isA<Joao>());
    expect(pessoaNoTrabalho.nome, 'João');
    expect(pessoaNoTrabalho.idade, 30);

    print('✅ Escola acessa Maria: ${pessoaNaEscola.nome}');
    print('✅ Trabalho acessa João: ${pessoaNoTrabalho.nome}');
  });

  test('✅ Teste: Escolas e Trabalho com IPessoa diferentes', () async {
    // Criar módulos
    final appModule = AppModuleTest();
    await InjectionManager.instance.registerAppModule(appModule);

    final escolaModule = EscolaModule();
    await InjectionManager.instance.registerBindsModule(escolaModule);

    final trabalhoModule = TrabalhoModule();
    await InjectionManager.instance.registerBindsModule(trabalhoModule);

    // Resolver no contexto de Escola
    InjectionManager.instance.setModuleContext(EscolaModule);
    final escolaInstancia = Modular.get<Escola>();

    expect(escolaInstancia.aluno, isA<Maria>());
    expect(escolaInstancia.aluno.nome, 'Maria');

    // Resolver no contexto de Trabalho
    InjectionManager.instance.setModuleContext(TrabalhoModule);
    final trabalhoInstancia = Modular.get<Trabalho>();

    expect(trabalhoInstancia.empregado, isA<Joao>());
    expect(trabalhoInstancia.empregado.nome, 'João');

    print('✅ Escola tem aluno: ${escolaInstancia.aluno.nome}');
    print('✅ Trabalho tem empregado: ${trabalhoInstancia.empregado.nome}');
  });
}

// ============ INTERFACES ============

/// Interface abstrata para pessoa
abstract class IPessoa {
  String get nome;
  int get idade;
}

// ============ IMPLEMENTAÇÕES ============

/// Implementação de Maria (10 anos)
class Maria implements IPessoa {
  @override
  String get nome => 'Maria';

  @override
  int get idade => 10;

  void estudar() {
    print('Maria está estudando...');
  }
}

/// Implementação de João (30 anos)
class Joao implements IPessoa {
  @override
  String get nome => 'João';

  @override
  int get idade => 30;

  void trabalhar() {
    print('João está trabalhando...');
  }
}

/// Escola precisa de IPessoa (Maria)
class Escola {
  final IPessoa aluno;

  Escola({required this.aluno});

  void ensinar() {
    print('Escola ensinando ${aluno.nome}...');
  }
}

/// Trabalho precisa de IPessoa (João)
class Trabalho {
  final IPessoa empregado;

  Trabalho({required this.empregado});

  void gerenciar() {
    print('Trabalho gerenciando ${empregado.nome}...');
  }
}

// ============ MÓDULOS ============

class AppModuleTest extends Module {
  @override
  void binds(Injector i) {
    // AppModule pode registrar implementações comuns
  }
}

class EscolaModule extends Module {
  @override
  void binds(Injector i) {
    // Registrar IPessoa apontando para Maria
    i.add<IPessoa>(() => Maria());

    // Registrar Escola que depende de IPessoa (deve inferir Maria)
    i.add<Escola>(() => Escola(aluno: i.get<Maria>()));
  }
}

class TrabalhoModule extends Module {
  @override
  void binds(Injector i) {
    // Registrar IPessoa apontando para João
    i.add<IPessoa>(() => Joao());

    // Registrar Trabalho que depende de IPessoa (deve inferir João)
    i.add<Trabalho>(() => Trabalho(empregado: i.get<Joao>()));
  }
}
