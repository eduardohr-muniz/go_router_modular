## Why

O sistema de injeção de dependências (DI) do `go_router_modular` cresceu para uma arquitetura sofisticada de seis camadas (definição, armazenamento, registro, resolução, proteção e gerenciamento de ciclo de vida), mas esse desenho vive apenas no código-fonte. Não existe documentação que explique **como cada peça funciona** e, principalmente, **por que cada peça existe**. Isso aumenta o custo de manutenção, dificulta a contribuição externa, esconde decisões de design (como a propagação de cache entre módulos importados) e torna regressões fáceis de reintroduzir. Esta mudança documenta o comportamento atual do DI como uma especificação executável e auditável, sem alterar nenhum comportamento.

## What Changes

- Criar uma especificação descritiva e completa do sistema de DL atual, capturada como requisitos testáveis em `openspec/specs/`.
- Documentar os três tipos de bind suportados (singleton eager, singleton lazy e factory/transiente) e seu ciclo de vida.
- Documentar a resolução de binds via `Injector.get` / `Bind.get`, incluindo o caminho rápido (fast-path), o cache negativo e as estratégias de busca.
- Documentar os mecanismos de proteção: detecção de dependência circular, limite de tentativas de busca, bloqueio de fatory durante sua própria execução (self-reference) e propagação de cache entre módulos importados.
- Documentar o ciclo de vida de módulos: registro em batch, rastreamento bidirecional módulo↔bind, descarte automático e a fila de operações que serializa registro/descarte.
- Documentar o descarte polimórfico de instâncias (`dispose` → `close` → `cancel`) e o contrato de teste (`FakeInjector`, `BindTemplate`).
- Mapear, em cada requisito, onde os princípios SOLID aparecem (e onde são fracos), para servir de referência a refatorações futuras.
- **Sem mudança de comportamento**: nenhuma API é alterada, adicionada ou removida. Esta é uma mudança puramente documental.

## Capabilities

### New Capabilities
- `dependency-injection`: Comportamento do container de DI — definição de binds, tipos de bind (singleton eager, singleton lazy, factory), armazenamento dual (por tipo e por chave), resolução com fast-path e cache negativo, e descarte polimórfico de instâncias.
- `dependency-injection-protection`: Mecanismos que garantem resolução segura — detecção de dependência circular, limite de tentativas, bloqueio de factory em execução (self-reference legítima) e propagação de cache entre binds duplicados de módulos importados.
- `module-lifecycle`: Ciclo de vida de módulos sobre o DI — registro em batch via `Injector`, rastreamento bidirecional módulo↔bind, descarte automático quando nenhum módulo usa mais o bind, proteção do AppModule contra descarte e serialização de operações pela fila.

### Modified Capabilities
<!-- Nenhuma capability existente tem requisitos alterados — openspec/specs/ está vazio e esta mudança é puramente documental. -->

## Impact

- **Código de produção**: nenhum. Nenhum arquivo em `lib/` é modificado.
- **Artefatos OpenSpec**: novos arquivos de spec em `openspec/specs/dependency-injection/`, `openspec/specs/dependency-injection-protection/` e `openspec/specs/module-lifecycle/`.
- **Arquivos de referência documentados** (sem alteração, apenas descritos): `lib/src/core/bind/*`, `lib/src/core/manager/*`, `lib/src/core/module/module.dart`, `lib/src/di/*`, `lib/src/testing/fake_injector.dart`, `lib/src/testing/bind_template.dart`, `lib/src/exceptions/exception.dart`.
- **Testes**: a base de testes existente continua sendo a verificação executável dos requisitos documentados; a meta de 100% de cobertura permanece como invariante do pacote.
- **Riscos**: baixos — risco principal é divergência entre a spec e o código se o comportamento evoluir sem atualizar a spec.

## Não-objetivos

- Não alterar, refatorar ou corrigir qualquer comportamento do sistema de DI.
- Não remover os pontos fracos de SOLID identificados (singletons estáticos no `Bind`, cascata de cleanup fixa em `CleanBind`, estado global mutável). Eles são apenas registrados como contexto para decisões futuras.
- Não documentar o sistema de roteamento, eventos ou widgets — o escopo é exclusivamente o DI e o ciclo de vida de módulos no que toca aos binds.
- Não criar API nova de testes nem alterar a API de `FakeInjector` / `BindTemplate`.
