# Plano: fluxo entre módulos alinhado ao TCE-SP

Data do plano: 27/10/2026.

## Contexto

O fluxo descrito pelo tribunal é **Edital → Licitação → (Ata de Registro de Preços →) Ajuste**: Ata e Ajuste dependem da Licitação. A aplicação hoje libera Ata e Ajuste a partir do Edital enviado; a Licitação só é usada para conferir números de itens, e a conferência é pulada quando ela não existe.

O sistema é usado por três perfis:

| Perfil | Módulos |
| --- | --- |
| Planejamento | Estimativa |
| Contratação | Edital, Licitação |
| Contratos | Ata, Ajuste |

A divisão por documento é mantida: ela corresponde aos envios do AUDESP e às permissões (`AppPermissions`). O plano acrescenta uma camada de processo (agrupada pelo edital, chave de todos os descritores) com as regras de dependência e as pendências de cada perfil.

## Decisões

1. **Licitação enviada** = existe licitação com status local `sent` para o edital. Se o último protocolo dela estiver rejeitado, a interface apenas avisa.
2. **Atas e Ajustes em rascunho sem Licitação enviada** continuam editáveis; somente o **envio** é bloqueado. Nada some da lista.
3. **Dados vindos da Licitação** são sempre sugestões editáveis e só são calculados quando não há ambiguidade.

## Fases

| Fase | Escopo | Situação |
| --- | --- | --- |
| 1 | Módulo `processo/` com as regras de dependência | Concluída |
| 2 | Exigir Licitação enviada para Ata e Ajuste | Concluída |
| 3 | Novo Ajuste a partir da Ata | Concluída |
| 4 | Preencher Ata e Ajuste com dados da Licitação | Concluída |
| 5 | Menu lateral reorganizado | Pendente |
| 6 | Tela de Processos e Pendências | Pendente |
| 7 | Pontos menores (estado da Estimativa, token AUDESP, Logs) | Pendente |
| 8 | Divisão dos formulários grandes (incremental) | Pendente |

Ordem: 1 → 2 → 3 → 4 → 5 → 6 → 7, com a 8 feita ao mexer em cada formulário. A Fase 5 não depende das demais e pode ser antecipada.

### Fase 1 — Módulo `processo/`

- `lib/features/processo/domain/processo.dart`: `Processo` (edital + licitações, atas e ajustes vinculados) e agrupamento por `edital_id`. Ajustes de adesão sem edital local ficam fora.
- `lib/features/processo/domain/processo_rules.dart`:
  - `situacaoLicitacao` → `inexistente`, `rascunho` ou `enviada`;
  - `podeCriarAta` (edital enviado, SRP, licitação enviada) e `podeCriarAjuste` (edital enviado, licitação enviada; adesão/participação isenta), com o motivo do bloqueio;
  - `dependentesDe` (atas e ajustes vinculados), para os avisos de retorno a rascunho;
  - `pendenciasPara(user, processos)`:
    - Contratação: edital enviado sem licitação; licitação só em rascunho;
    - Contratos: licitação enviada de edital SRP sem ata; ata enviada sem ajuste; licitação enviada de edital não SRP sem ajuste.
- `lib/features/processo/processo_providers.dart`: `processosProvider` (4 consultas `watchAll`, agrupamento em memória).
- `unlinked_editais_dialog.dart` passa a contar vínculos a partir de `Processo`.
- Testes: `test/features/processo/domain/processo_rules_test.dart`.

### Fase 2 — Licitação enviada para Ata e Ajuste

- `ata_form_page.dart` e `ajuste_form_page.dart`: editais filtrados por `podeCriarAta` / `podeCriarAjuste`, com o estado da licitação visível; regra conferida de novo no envio.
- `LicitacaoReferencia`: conferência de itens usa só a licitação enviada; sem referência, o envio é bloqueado (exceto adesão).
- "Criar por Edital" de Ata e Ajuste: só editais liberados, com opção "mostrar bloqueados" exibindo o motivo.
- Ata ou Ajuste cujo edital deixou de estar liberado: o edital continua na lista de seleção, somente leitura, com aviso.
- "Retornar para rascunho" de Edital e Licitação mostra quantas atas e ajustes dependem do documento.

### Fase 3 — Novo Ajuste a partir da Ata

- Rota `/ajuste/new?ataId=X` → `AjusteFormPage(preselectedAtaId:)`, preenchendo edital e ata.
- Ação "Novo ajuste desta ata" no card da ata enviada e no formulário da ata enviada (somente com permissão de Ajuste).
- `ajuste_page.dart`: "Criar por Edital" vira "Criar por Licitação/Ata" (não SRP: licitações enviadas; SRP: atas enviadas, com a quantidade de ajustes).

### Fase 4 — Preenchimento a partir da Licitação

- `lib/features/licitacao/domain/licitacao_resultado.dart`:
  - `itensHomologados` (`situacaoCompraItemId = 2`);
  - `vencedoresPorItem` (`resultadoHabilitacao = 1`);
  - `fornecedoresVencedores` (itens agrupados por `niPessoa`, com nome e tipo de pessoa);
  - `valorSugerido`: `tipoValor = M` e proposta unitária → valor × quantidade do edital; proposta global → valor; percentual/desconto → sem sugestão.
- Ata: botão "Importar itens homologados" (não apaga o que já foi digitado).
- Ajuste: botão "Preencher pela licitação" → escolha do fornecedor vencedor → fornecedor, itens (cruzados com a ata, se houver) e sugestão de valor inicial, revisados campo a campo na mesma tela de revisão da importação pelo Gemini (generalizada com título e rótulo da coluna de sugestão).
- Testes: `test/features/licitacao/domain/licitacao_resultado_test.dart`, cobrindo as combinações de `tipoProposta` e `tipoValor`.

### Fase 5 — Menu lateral

- `lib/core/navigation/app_modules.dart`: definição única dos módulos (hoje duplicada em `app.dart` e `shell_page.dart`).
- Ordem: Processos | Estimativa | Edital, Licitação | Ata, Ajuste, com divisórias.
- Logs no rodapé, só para quem tem permissão de envio.
- Remover `selectedShellIndexProvider` (a aba vem da rota).

### Fase 6 — Processos e Pendências

- Rota `/processos`: página inicial de quem tem Edital, Licitação, Ata ou Ajuste (perfil só de Estimativa continua em `/estimativa`).
- Uma linha por edital com as etapas e o estado de cada uma; clicar abre ou cria o documento, respeitando a permissão.
- Filtro "Minhas pendências" ligado por padrão, mais busca por código e objeto.

### Fase 7 — Pontos menores

- Migração v13: `estimativas.status` (`rascunho`/`finalizada`) e `editais.estimativa_id` (nulo); ações Finalizar/Reabrir; importação no edital lista só estimativas finalizadas; Processos mostra a estimativa de origem.
- Token AUDESP reaproveitado por usuário e ambiente; senha pedida só sem token válido ou após 401; limpo no logout e na troca de ambiente.
- Atualizar `AGENTS.md` (schema v13, módulo `processo/`, regras de dependência).

### Fase 8 — Formulários grandes

Dividir em widgets por seção, com a lógica de estado e envio fora da tela, ao mexer em cada formulário: primeiro `ajuste_form_page.dart` e `ata_form_page.dart`; `licitacao_form_page.dart` e `estimativa_form_page.dart` por último.

Feito até aqui: na Fase 4, `ajuste_form_page.dart` ganhou `_valoresAtuais()` e `_aplicarCamposAceitos()`, compartilhados entre o Gemini e o preenchimento pela licitação. A divisão em widgets por seção continua pendente.

## Verificação

- Em cada fase: `flutter analyze` e `flutter test`.
- Teste manual no Piloto com um usuário de cada perfil: estimativa finalizada → edital importado dela → licitação → ata → ajuste a partir da ata; e o caso inverso (Ata sem Licitação enviada deve ser bloqueada no envio).
