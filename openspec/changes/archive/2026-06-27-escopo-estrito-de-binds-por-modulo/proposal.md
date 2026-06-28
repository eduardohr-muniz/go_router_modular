## Why

Hoje o container de DI resolve binds de forma **global e plana**: qualquer bind registrado e vivo é resolvível por qualquer código, independentemente de qual módulo o declarou. Isso permite uma má prática silenciosa: um bind do módulo B depende de um bind que B não injetou nem importou — e funciona por acidente porque outro módulo (ex.: A, ainda na pilha após um `push`) o registrou. Quando o módulo dono é descartado, tudo quebra.

Reproduzimos e confirmamos o comportamento. A regra desejada:

> **O `AppModule` (e os imports dele) é o único escopo global, acessível por todos.** Qualquer outro módulo só pode acessar os binds que **ele mesmo injetou ou importou**.

Esta mudança implementa a regra na abordagem **commit-time**: ao registrar um módulo, valida-se que cada bind declarado por ele resolve suas dependências dentro do seu escopo; fora disso, lança erro acionável **no momento do push**. É a opção de menor risco e maior valor — pega o erro estrutural ("esqueci de importar") cedo, reusando o gancho de validação que já existe, sem acoplar o `BindLocator` ao tracker de módulos.

## What Changes

- Computar o **conjunto visível** de cada módulo M = binds próprios ∪ importados ∪ binds do `AppModule`, a partir do `BindContextTracker` (que já registra `moduleBindTypes[M]` como próprios+importados).
- Taguear cada `Bind` com seu identificador (`BindIdentifier`) para identificar o dono do bind resolvido.
- **Validação de escopo no registro**: ao final do registro de M, rodar as factories dos binds **declarados por M** com um injector que grava os tipos resolvidos, e verificar que cada dependência direta pertence ao conjunto visível de M. Violação → `ModularException` síncrona (fail-fast no push).
- Tornar a validação relevante **eager** (síncrona ao registro) em vez de adiada, para o erro surgir na entrada da rota.
- **Brecha consciente**: `Modular.get`/`Bind.get` estáticos e `context.read` permanecem **globais** (sem enforcement em runtime) — uso indevido ali é responsabilidade do desenvolvedor; não é o caminho idiomático.

Justificativa SOLID/Clean Code: torna explícitas e verificáveis as dependências entre módulos (falha rápido no registro), sem inverter camadas nem inflar o caminho de resolução.

## Capabilities

### New Capabilities

- `module-bind-scope`: validação de escopo de binds por módulo no registro (commit-time) — conjunto visível, checagem das dependências dos binds declarados, exceção acionável, e a brecha consciente na resolução estática.

## Impact

- **Código de produção**: `lib/src/di/injection_manager.dart` (validação de escopo eager + conjunto visível), `lib/src/di/bind_context_tracker.dart` (`isVisible`), `lib/src/di/bind.dart`/`bind_identifier` (tag do bind), `lib/src/di/injector.dart` (injector de gravação para a validação). **Não** altera `BindLocator` nem o caminho de resolução estático.
- **Comportamento**: BREAKING no registro — um módulo cujo bind depende de tipo fora do escopo passa a lançar no push. Resolução estática inalterada (brecha).
- **Testes/exemplos**: testes/exemplos onde um bind de módulo depende de bind de outro módulo não importado precisarão declarar o import — parte do trabalho.
- **Riscos**: médios — menor que o enforcement runtime; foco no registro, sem tocar resolução. Efeito colateral de re-executar factory na validação é o mesmo já assumido por `_validateModuleBinds`.

## Não-objetivos

- Não enforçar escopo em `Modular.get`/`Bind.get` estáticos nem em `context.read` (brecha consciente; seria a fase runtime, fora deste escopo).
- Não criar armazenamento separado por módulo (continua um `BindStorage` global; é validação de acesso, não isolamento de instâncias).
- Não alterar o `BindLocator`, o ciclo de vida/descarte de binds, nem a mecânica de imports.
