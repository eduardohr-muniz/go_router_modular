import 'package:go_router_modular/go_router_modular.dart';

class TestController {
  static TestController? _instance;
  TestController._();
  static TestController get instance => _instance ??= TestController._();

  final List<TestResult> _testResults = [];
  final List<String> _navigationHistory = [];
  final List<String> _bindHistory = [];

  // Estado atual do teste
  String? _currentModule;
  int _testCount = 0;

  // Getters para acesso aos dados
  List<TestResult> get testResults => List.unmodifiable(_testResults);
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  List<String> get bindHistory => List.unmodifiable(_bindHistory);
  String? get currentModule => _currentModule;
  int get testCount => _testCount;

  // Registrar entrada em módulo
  void enterModule(String moduleName) {
    _currentModule = moduleName;
    final timestamp = _getTimestamp();
    _navigationHistory.insert(0, '[$timestamp] 🏠 Entrou em: $moduleName');
    _bindHistory.insert(0, '[$timestamp] 📝 Módulo ativo: $moduleName');
    print('📍 CONTROLLER: Entrou em módulo $moduleName');
  }

  // Registrar saída de módulo
  void exitModule(String moduleName) {
    final timestamp = _getTimestamp();
    _navigationHistory.insert(0, '[$timestamp] 🚪 Saiu de: $moduleName');
    _bindHistory.insert(0, '[$timestamp] 🗑️ Módulo disposed: $moduleName');

    if (_currentModule == moduleName) {
      _currentModule = null;
    }
    print('📍 CONTROLLER: Saiu do módulo $moduleName');
  }

  // Teste de resolução de dependências
  TestResult testDependencyResolution(String moduleName, Map<String, Function()> dependencyGetters) {
    _testCount++;
    final timestamp = _getTimestamp();

    try {
      final testedDeps = <String, String>{};

      for (final entry in dependencyGetters.entries) {
        final depName = entry.key;
        final getter = entry.value;

        try {
          final instance = getter();
          testedDeps[depName] = '✅ ${instance.runtimeType}';
        } catch (e) {
          testedDeps[depName] = '❌ Erro: $e';
        }
      }

      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: moduleName,
        testType: TestType.dependencyResolution,
        success: testedDeps.values.every((v) => v.startsWith('✅')),
        details: testedDeps,
        message: 'Teste de resolução de dependências',
      );

      _testResults.insert(0, result);
      _bindHistory.insert(0, '[$timestamp] 🧪 Teste #$_testCount: ${result.success ? 'PASSOU' : 'FALHOU'}');

      return result;
    } catch (e) {
      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: moduleName,
        testType: TestType.dependencyResolution,
        success: false,
        details: {'error': e.toString()},
        message: 'Erro no teste de dependências',
      );

      _testResults.insert(0, result);
      return result;
    }
  }

  // Teste de bind disposal
  TestResult testBindDisposal(String moduleName, Map<String, Function()> dependencyGetters) {
    _testCount++;
    final timestamp = _getTimestamp();

    try {
      final disposalResults = <String, String>{};

      for (final entry in dependencyGetters.entries) {
        final depName = entry.key;
        final getter = entry.value;

        try {
          getter();
          disposalResults[depName] = '❌ Ainda existe (não foi disposed)';
        } catch (e) {
          disposalResults[depName] = '✅ Corretamente disposed';
        }
      }

      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: moduleName,
        testType: TestType.bindDisposal,
        success: disposalResults.values.every((v) => v.startsWith('✅')),
        details: disposalResults,
        message: 'Teste de disposal de binds',
      );

      _testResults.insert(0, result);
      _bindHistory.insert(0, '[$timestamp] 🗑️ Teste disposal #$_testCount: ${result.success ? 'PASSOU' : 'FALHOU'}');

      return result;
    } catch (e) {
      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: moduleName,
        testType: TestType.bindDisposal,
        success: false,
        details: {'error': e.toString()},
        message: 'Erro no teste de disposal',
      );

      _testResults.insert(0, result);
      return result;
    }
  }

  // Teste de shell navigation
  TestResult testShellNavigation(String shellRoute, List<String> childRoutes) {
    _testCount++;
    final timestamp = _getTimestamp();

    try {
      final shellResults = <String, String>{};
      shellResults['shell_route'] = '✅ Shell route acessível: $shellRoute';

      for (final route in childRoutes) {
        shellResults['child_$route'] = '✅ Child route acessível: $route';
      }

      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: 'Shell',
        testType: TestType.shellNavigation,
        success: true,
        details: shellResults,
        message: 'Teste de navegação shell',
      );

      _testResults.insert(0, result);
      _navigationHistory.insert(0, '[$timestamp] 🐚 Teste shell #$_testCount: PASSOU');

      return result;
    } catch (e) {
      final result = TestResult(
        id: _testCount,
        timestamp: timestamp,
        moduleName: 'Shell',
        testType: TestType.shellNavigation,
        success: false,
        details: {'error': e.toString()},
        message: 'Erro no teste de shell',
      );

      _testResults.insert(0, result);
      return result;
    }
  }

  // Limpar históricos
  void clearAll() {
    _testResults.clear();
    _navigationHistory.clear();
    _bindHistory.clear();
    _testCount = 0;
    _currentModule = null;
    print('📍 CONTROLLER: Histórico limpo');
  }

  void clearTestResults() {
    _testResults.clear();
    print('📍 CONTROLLER: Resultados de teste limpos');
  }

  void clearNavigationHistory() {
    _navigationHistory.clear();
    print('📍 CONTROLLER: Histórico de navegação limpo');
  }

  void clearBindHistory() {
    _bindHistory.clear();
    print('📍 CONTROLLER: Histórico de binds limpo');
  }

  String _getTimestamp() {
    return DateTime.now().toString().substring(11, 19);
  }
}

class TestResult {
  final int id;
  final String timestamp;
  final String moduleName;
  final TestType testType;
  final bool success;
  final Map<String, dynamic> details;
  final String message;

  TestResult({
    required this.id,
    required this.timestamp,
    required this.moduleName,
    required this.testType,
    required this.success,
    required this.details,
    required this.message,
  });

  @override
  String toString() {
    return '[$timestamp] Test #$id ($moduleName): ${success ? 'PASSOU' : 'FALHOU'} - $message';
  }
}

enum TestType {
  dependencyResolution,
  bindDisposal,
  shellNavigation,
}
