## Context

A API de guards foi introduzida recentemente (classe abstrata `ModularGuard`, adaptador `GuardFn`, resolução em curto-circuito e composição do `redirect` legado). O símbolo público que os consumidores estendem chama-se `ModularGuard` e vive em `lib/src/routing/guards/modular_guard.dart`, exportado pelo barril `lib/go_router_modular.dart`. O prefixo `Modular` é redundante e não diz o que o tipo é. Esta é uma renomeação pura de um símbolo público novo, sem base de consumidores publicada, então o custo de mudar agora é mínimo e não há valor em manter compatibilidade retroativa.

## Goals / Non-Goals

**Goals:**
- Renomear a classe abstrata `ModularGuard` para `RouteGuard`, mantendo contrato, método e comportamento idênticos.
- Renomear o arquivo `modular_guard.dart` para `route_guard.dart` e o export correspondente.
- Atualizar todas as referências internas (tipos, docs `///`, mensagem de depreciação) e testes, mantendo 100% de cobertura.
- Manter os specs ativos coerentes com o novo nome.

**Non-Goals:**
- Alterar comportamento, assinatura ou ordem de resolução dos guards.
- Renomear `GuardFn`, `guardsRedirectDeprecation` ou qualquer outro símbolo.
- Manter alias deprecado `ModularGuard`.
- Tocar nos artefatos arquivados em `openspec/changes/archive/`.

## Decisions

### Decisão 1: Renomeação direta, sem `typedef` de compatibilidade
Optou-se por renomear o símbolo sem deixar `typedef ModularGuard = RouteGuard;` deprecado.
- **Por quê:** a API é nova e não publicada; um alias só adicionaria código morto e ruído à superfície pública (Clean Code — sem código morto; YAGNI). Manter dois nomes para o mesmo conceito viola a clareza de nomes.
- **Alternativa considerada:** manter `ModularGuard` como `@Deprecated typedef`. Rejeitada porque não há consumidores a proteger e o objetivo é justamente eliminar o nome confuso.

### Decisão 2: Renomear o arquivo `modular_guard.dart` → `route_guard.dart`
O nome do arquivo deve acompanhar o nome do tipo (Effective Dart — um tipo público por arquivo, nome do arquivo em `snake_case` do tipo).
- **Impacto:** o `export` em `lib/go_router_modular.dart` e o `import` em `guard_fn.dart`, `guard_resolver.dart` e nos builders/rotas que referenciam o tipo precisam apontar para o novo caminho.
- **Observação:** o `guardsRedirectDeprecation` (const compartilhada) vive nesse arquivo e permanece nele; só o texto que cita "extends `ModularGuard`" é atualizado para "extends `RouteGuard`".

### Decisão 3: Substituição mecânica abrangente + verificação por análise/testes
A renomeação é uma substituição textual de `ModularGuard` → `RouteGuard` e `modular_guard` → `route_guard`, validada por `flutter analyze` (zero referências pendentes) e `flutter test --coverage` (comportamento inalterado, cobertura mantida).

## Risks / Trade-offs

- [Referência residual ao nome antigo em doc ou string] → Mitigação: `grep -rn "ModularGuard\|modular_guard"` em `lib/`, `test/` e `skills/` após a troca; análise estática acusa qualquer tipo não resolvido.
- [Quebra de consumidores externos que já adotaram `ModularGuard`] → Mitigação aceita: documentado como **BREAKING** na proposal; como a API é nova/não publicada, o impacto real é nulo. Caso fosse necessário, a migração é um find/replace de `ModularGuard` por `RouteGuard`.
- [Esquecer de renomear o arquivo e deixar só o símbolo] → Mitigação: tarefa explícita de `git mv` e atualização do export, conferida pela ausência de `modular_guard.dart` no diretório.

## Migration Plan

1. `git mv lib/src/routing/guards/modular_guard.dart lib/src/routing/guards/route_guard.dart`.
2. Renomear o símbolo e atualizar docs `///` e a mensagem de depreciação dentro do arquivo.
3. Atualizar export no barril e imports/usos internos.
4. Atualizar os testes e a documentação da skill.
5. Rodar `flutter analyze` e `flutter test --coverage`; confirmar zero referências ao nome antigo.

Rollback: reverter o commit (mudança puramente textual, sem migração de dados).

## Open Questions

- Nenhuma. A decisão de não manter alias deprecado está alinhada ao pedido ("trocar somente a nomenclatura") e à ausência de consumidores publicados.
