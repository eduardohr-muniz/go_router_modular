/// Guarda de arquitetura: nenhum arquivo sob `lib/src/` pode importar o barril
/// público `package:go_router_modular/go_router_modular.dart`.
///
/// Por quê: importar o barril dentro do pacote acopla arquivos de base a toda a
/// superfície pública (viola Inversão de Dependências e Interface Segregation) e
/// esconde o grafo real de dependências. Cada arquivo interno deve importar
/// apenas os arquivos específicos que usa.
///
/// A varredura considera apenas DIRETIVAS DE IMPORT REAIS — o bloco no topo do
/// arquivo, antes da primeira declaração — para não confundir com o texto de
/// exemplo que aparece dentro de strings (ex.: mensagens de assert).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String publicBarrelImport = "package:go_router_modular/go_router_modular.dart";

/// Retorna as linhas de import reais (diretivas no topo do arquivo).
///
/// Em Dart, todas as diretivas (`library`, `import`, `export`, `part`) aparecem
/// antes de qualquer declaração. Esta função coleta essas diretivas e para na
/// primeira linha de código, ignorando linhas em branco e comentários.
List<String> leadingImportDirectives(String source) {
  final List<String> imports = <String>[];
  for (final String rawLine in const LineSplitter().convert(source)) {
    final String line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith("//")) continue;
    if (line.startsWith("library ") || line.startsWith("part ") || line.startsWith("@")) {
      continue;
    }
    if (line.startsWith("import ") || line.startsWith("export ")) {
      imports.add(line);
      continue;
    }
    // Primeira linha que não é diretiva nem comentário: fim do bloco de diretivas.
    break;
  }
  return imports;
}

void main() {
  test("nenhum arquivo em lib/src importa o barril público", () {
    final Directory sourceDirectory = Directory("lib/src");
    expect(sourceDirectory.existsSync(), isTrue, reason: "lib/src deve existir");

    final List<String> offendingFiles = <String>[];
    final Iterable<File> dartFiles = sourceDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith(".dart"));

    for (final File dartFile in dartFiles) {
      final List<String> imports = leadingImportDirectives(dartFile.readAsStringSync());
      final bool importsBarrel =
          imports.any((String directive) => directive.contains(publicBarrelImport));
      if (importsBarrel) {
        offendingFiles.add(dartFile.path);
      }
    }

    expect(
      offendingFiles,
      isEmpty,
      reason: "Estes arquivos importam o barril público em vez de imports "
          "específicos:\n${offendingFiles.join('\n')}",
    );
  });
}
