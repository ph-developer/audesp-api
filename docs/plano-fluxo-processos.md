# Plano: fluxo entre módulos alinhado ao TCE-SP

Data do plano: 27/10/2026.

## Contexto

O fluxo descrito pelo tribunal permite **Edital → Licitação → (Ata de Registro de Preços →) Ajuste**: Ata e Ajuste dependem da Licitação. Na prefeitura que usa o sistema, porém, a licitação gera **Ata OU Ajuste**: edital SRP gera só Ata de Registro de Preços; edital não SRP gera só Ajuste. Não há Ajuste a partir de Ata no sistema (Decisão 4). As pendências de Contratos seguem essa separação, e adesão/participação mantém seu fluxo próprio.

Antes das Fases 1–7, a aplicação liberava Ata e Ajuste a partir do Edital enviado; a Licitação só era usada para conferir números de itens, e a conferência era pulada quando ela não existia. Agora o envio exige as dependências locais, exceto para adesão/participação.

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
4. **Ata OU Ajuste (28/10/2026):** por decisão do usuário e conforme a prática da prefeitura, edital **SRP gera só Ata**; edital **não SRP gera só Ajuste**. O TCE-SP permite Ajuste a partir de Ata, mas o sistema não oferece esse fluxo. **Adesão/participação** (`adesaoParticipacao = true`, ata de outro órgão e códigos digitados) continua como está. Ajustes antigos com `ata_id` ou de edital SRP continuam abrindo e aparecendo nas listas, com o vínculo preservado ao salvar; somente o envio é bloqueado, pelo mesmo mecanismo da Fase 2.

## Fases

| Fase | Escopo | Situação |
| --- | --- | --- |
| 1 | Módulo `processo/` com as regras de dependência | Concluída |
| 2 | Exigir Licitação enviada para Ata e Ajuste | Concluída |
| 3 | Criar por Licitação; Ajuste por Ata removido pela Decisão 4 | Concluída |
| 4 | Preencher Ata e Ajuste com dados da Licitação | Concluída |
| 5 | Menu lateral reorganizado | Concluída |
| 6 | Tela de Processos e Pendências | Concluída |
| 7 | Pontos menores (estado da Estimativa, token AUDESP, Logs) | Concluída |
| 8 | Divisão dos formulários grandes (incremental) | Pendente |

Ordem: 1 → 2 → 3 → 4 → 5 → 6 → 7, com a 8 feita ao mexer em cada formulário. A Fase 5 não depende das demais e pode ser antecipada.

### Fase 1 — Módulo `processo/`

- `lib/features/processo/domain/processo.dart`: `Processo` (edital + licitações, atas e ajustes vinculados) e agrupamento por `edital_id`. Ajustes de adesão sem edital local ficam fora.
- `lib/features/processo/domain/processo_rules.dart`:
  - `situacaoLicitacao` → `inexistente`, `rascunho` ou `enviada`;
  - `podeCriarAta` (edital enviado, SRP, licitação enviada) e `podeCriarAjuste` (edital enviado, não SRP, licitação enviada; adesão/participação isenta), com o motivo do bloqueio;
  - `dependentesDe` (atas e ajustes vinculados), para os avisos de retorno a rascunho;
  - `pendenciasPara(user, processos)`:
    - Contratação: edital enviado sem licitação; licitação só em rascunho;
    - Contratos: licitação enviada de edital SRP sem ata pede só "Criar ata"; licitação enviada de edital não SRP sem ajuste pede só "Criar ajuste". Atas não geram pendência de Ajuste.
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

**Nota (28/10/2026):** o Ajuste a partir da Ata, implementado nesta fase, foi removido pela Decisão 4. Foram retirados a pré-seleção por `ataId`, os atalhos nas telas de Ata, o botão "Criar por Ata" e a seleção de ata local no formulário de Ajuste.

- O restante da Fase 3 continua: `ajuste_page.dart` oferece "Criar por Licitação", listando só editais não SRP com licitação enviada, além da opção de mostrar bloqueados com o motivo.
- Ajustes antigos permanecem disponíveis para abertura e edição, sem permitir novo vínculo com ata local nem envio de ajustes com `ata_id` ou de edital SRP. O código da ata é digitado e exibido no resumo do descritor somente na adesão/participação.

### Fase 4 — Preenchimento a partir da Licitação

- `lib/features/licitacao/domain/licitacao_resultado.dart`:
  - `itensHomologados` (`situacaoCompraItemId = 2`);
  - `vencedoresPorItem` (`resultadoHabilitacao = 1`);
  - `fornecedoresVencedores` (itens agrupados por `niPessoa`, com nome e tipo de pessoa);
  - `valorSugerido`: `tipoValor = M` e proposta unitária → valor × quantidade do edital; proposta global → valor; percentual/desconto → sem sugestão.
- Ata: botão "Importar itens homologados" (não apaga o que já foi digitado).
- Ajuste: botão "Preencher pela licitação" → escolha do fornecedor vencedor → fornecedor, itens e sugestão de valor inicial, revisados campo a campo na mesma tela de revisão da importação pelo Gemini (generalizada com título e rótulo da coluna de sugestão). A limitação de itens por ata foi removida pela Decisão 4.
- Testes: `test/features/licitacao/domain/licitacao_resultado_test.dart`, cobrindo as combinações de `tipoProposta` e `tipoValor`.

### Fase 5 — Menu lateral

- `lib/core/navigation/app_modules.dart`: definição única dos módulos (hoje duplicada em `app.dart` e `shell_page.dart`).
- Ordem: Processos | Estimativa | Edital, Licitação | Ata, Ajuste, com divisórias.
- Logs no rodapé, só para quem tem permissão de envio.
- Remover `selectedShellIndexProvider` (a aba vem da rota).

### Fase 6 — Processos e Pendências

- Rota `/processos`: página inicial de quem tem Edital, Licitação, Ata ou Ajuste (perfil só de Estimativa continua em `/estimativa`).
- Uma linha por edital com as etapas e o estado de cada uma; clicar abre ou cria o documento, respeitando a permissão.
- Filtro "Pendências" / "Todos" (pendências por padrão) e busca por código e objeto, na barra superior como nas demais telas.
- Etapas calculadas em `lib/features/processo/domain/processo_etapas.dart` (situação, motivo do bloqueio e ações já filtradas por permissão); página em `lib/features/processo/pages/processos_page.dart`. Etapa com várias ações abre um menu; as pendências só filtram a lista (o card não tem atalhos além das etapas).

### Fase 7 — Pontos menores

- Migração v13: `estimativas.status` (`rascunho`/`finalizada`) e `editais.estimativa_id` (nulo); ações Finalizar/Reabrir; importação no edital lista só estimativas finalizadas; Processos mostra a estimativa de origem.
- Token AUDESP reaproveitado por usuário e ambiente; senha pedida só sem token válido ou após 401; limpo no logout e na troca de ambiente.
- Atualizar `AGENTS.md` (schema v13, módulo `processo/`, regras de dependência).

### Fase 8 — Formulários grandes

Dividir em widgets por seção, com a lógica de estado e envio fora da tela, ao mexer em cada formulário: primeiro `ajuste_form_page.dart` e `ata_form_page.dart`; `licitacao_form_page.dart` e `estimativa_form_page.dart` por último.

Feito até aqui: na Fase 4, `ajuste_form_page.dart` ganhou `_valoresAtuais()` e `_aplicarCamposAceitos()`, compartilhados entre o Gemini e o preenchimento pela licitação. A divisão em widgets por seção continua pendente.

## Verificação

- Em cada fase: `flutter analyze` e `flutter test`.
- Teste manual no Piloto com um usuário de cada perfil: estimativa finalizada → edital importado dela → licitação → Ata (SRP) ou Ajuste (não SRP); conferir adesão/participação à parte. Ata sem Licitação enviada e Ajuste antigo de edital SRP ou com `ata_id` devem ser bloqueados no envio, mantendo os rascunhos editáveis.
