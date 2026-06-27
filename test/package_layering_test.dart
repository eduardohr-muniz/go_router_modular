/// Guarda de arquitetura: ausência dos ciclos entre áreas centrais que a
/// refatoração de camadas eliminou.
///
/// Não é uma guarda de "zero ciclos" — o subsistema de DI (`di/bind` ⇄
/// `di/injector`) e o de eventos têm ciclos intra-subsistema benignos e
/// aceitos em Dart. A guarda mira exatamente os cruzamentos corrigidos:
///   - `module` não pode alcançar `routing/route_builder` nem
///     `di/injection_manager` (quebra `module ⇄ routing`);
///   - `routing/route_builder` não pode alcançar o façade
///     `go_router_modular_configure` (quebra `config ⇄ route_builder`).
///
/// A análise usa apenas DIRETIVAS DE IMPORT REAIS (bloco no topo do arquivo),
/// resolvendo imports internos `package:go_router_modular/src/...` e relativos.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String sourceRoot = "lib/src";

/// Diretivas de import no topo do arquivo (antes da primeira declaração).
List<String> leadingImports(String source) {
  final List<String> imports = <String>[];
  for (final String rawLine in const LineSplitter().convert(source)) {
    final String line = rawLine.trim();
    if (line.isEmpty || line.startsWith("//")) continue;
    if (line.startsWith("library ") || line.startsWith("part ") || line.startsWith("@")) {
      continue;
    }
    if (line.startsWith("import ") || line.startsWith("export ")) {
      final RegExpMatch? match = RegExp("'([^']+)'").firstMatch(line);
      if (match != null) imports.add(match.group(1)!);
      continue;
    }
    break;
  }
  return imports;
}

/// Resolve um import para um caminho de arquivo dentro de `lib/`, ou `null` se
/// for um pacote externo / dart: SDK.
String? resolveImport(String importUri, String fromFile) {
  const String internalPrefix = "package:go_router_modular/";
  if (importUri.startsWith("${internalPrefix}src/")) {
    return "lib/${importUri.substring(internalPrefix.length)}";
  }
  if (importUri.startsWith("package:") || importUri.startsWith("dart:")) {
    return null;
  }
  final String resolved = File("${File(fromFile).parent.path}/$importUri").uri.normalizePath().toFilePath();
  final int libIndex = resolved.indexOf("lib/");
  return libIndex >= 0 ? resolved.substring(libIndex) : resolved;
}

Map<String, Set<String>> buildImportGraph() {
  final Map<String, Set<String>> graph = <String, Set<String>>{};
  final Iterable<File> dartFiles = Directory(sourceRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith(".dart"));
  for (final File dartFile in dartFiles) {
    final String normalized = dartFile.path.replaceFirst(RegExp(r"^\./"), "");
    final Set<String> targets = <String>{};
    for (final String importUri in leadingImports(dartFile.readAsStringSync())) {
      final String? target = resolveImport(importUri, normalized);
      if (target != null && target.endsWith(".dart")) targets.add(target);
    }
    graph[normalized] = targets;
  }
  return graph;
}

/// `true` se `target` é alcançável a partir de `start` seguindo os imports.
bool canReach(Map<String, Set<String>> graph, String start, String target) {
  final List<String> stack = <String>[start];
  final Set<String> visited = <String>{};
  while (stack.isNotEmpty) {
    final String current = stack.removeLast();
    if (!visited.add(current)) continue;
    for (final String next in graph[current] ?? const <String>{}) {
      if (next == target) return true;
      stack.add(next);
    }
  }
  return false;
}

void main() {
  late Map<String, Set<String>> graph;

  setUpAll(() {
    graph = buildImportGraph();
  });

  const String moduleFile = "lib/src/module/module.dart";
  const String routeBuilderFile = "lib/src/routing/route_builder.dart";
  const String injectionManagerFile = "lib/src/di/injection_manager.dart";
  const String facadeFile = "lib/src/bootstrap/go_router_modular_configure.dart";

  test("module não alcança route_builder (sem ciclo module ⇄ routing)", () {
    expect(
      canReach(graph, moduleFile, routeBuilderFile),
      isFalse,
      reason: "module.dart não deve depender (nem transitivamente) de route_builder.dart",
    );
  });

  test("module não alcança injection_manager", () {
    expect(
      canReach(graph, moduleFile, injectionManagerFile),
      isFalse,
      reason: "module.dart não deve depender de injection_manager.dart — orquestração vive no composition root",
    );
  });

  test("route_builder não alcança o façade (sem ciclo config ⇄ route_builder)", () {
    expect(
      canReach(graph, routeBuilderFile, facadeFile),
      isFalse,
      reason: "route_builder.dart não deve depender do façade go_router_modular_configure.dart",
    );
  });
}
