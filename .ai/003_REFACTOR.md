# 003 — Planejamento de Refatoração e Novas Funcionalidades

## Contexto

Documento de planejamento para as seguintes implementações:

1. Padronização de estilo dos formulários de Ata e Ajuste (igual ao Edital e Licitação)
2. Salvamento de rascunho sem bloquear por campos opcionais
3. Importação de edital via PDF + Gemini (preenchimento automático)
4. Importação de itens de compra via CSV no Edital
5. Importação de itens de licitação + licitantes via CSV na Licitação

---

## Análise do Estado Atual

### Diferença de Estilo (Problema 1)

| Formulário | Componente de seção | Estilo dos campos |
|---|---|---|
| `edital_form_page.dart` | `_SectionCard` (Card com padding + título + divider) | Sem `border` explícito (usa tema) |
| `licitacao_form_page.dart` | `_SectionCard` (idem) | Idem |
| `ata_form_page.dart` | `_SectionHeader` (apenas título + divider, sem Card) | `border: OutlineInputBorder()` explícito em cada campo |
| `ajuste_form_page.dart` | `_SectionHeader` (idem) | Idem |

**Padronização alvo:** converter `ata_form_page.dart` e `ajuste_form_page.dart` para o padrão `_SectionCard`.

### Validação no Rascunho (Problema 2)

Todos os 4 formulários chamam `_formKey.currentState!.validate()` em `_saveDraft()`, bloqueando o salvamento se qualquer campo obrigatório estiver vazio. A exigência é:

- **Rascunho:** validar apenas a seção **Descritor** + seção **Vínculo** (quando existir — Licitação, Ata, Ajuste)
- **Envio:** continuar validando tudo (comportamento atual)

---

## Etapas de Implementação

As etapas foram dimensionadas para caber em janelas de contexto de ~120 k tokens cada.

---

### ~~Etapa 1 — Estilo: Formulário de Ata~~ ✅ CONCLUÍDA (08/04/2026)

**Arquivos afetados:** `lib/features/ata/pages/ata_form_page.dart`, `lib/shared/widgets/section_card.dart`

**O que foi feito:**

1. Widget `SectionCard` extraído para `lib/shared/widgets/section_card.dart` (Sugestão 1).
2. Cla­sse `_SectionHeader` removida do arquivo de Ata.
3. Todas as seções (Vínculo com Edital, Descritor, Dados da Ata, Itens da Licitação Referenciados) convertidas para `SectionCard`.
4. `border: OutlineInputBorder()` explícito removido de todos os campos (cai para o tema).

---

### ~~Etapa 2 — Estilo: Formulário de Ajuste~~ ✅ CONCLUÍDA (08/04/2026)

**Arquivos afetados:** `lib/features/ajuste/pages/ajuste_form_page.dart`

**O que foi feito:** idêntico à Etapa 1 — todas as 12 seções do Ajuste convertidas para `SectionCard`; `_SectionHeader` removida; bordas explícitas removidas.

---

### ~~Etapa 3 — Rascunho Parcial (sem validação completa)~~ ✅ CONCLUÍDA (08/04/2026)

**Arquivos afetados:**
- `lib/features/edital/pages/edital_form_page.dart`
- `lib/features/licitacao/pages/licitacao_form_page.dart`
- `lib/features/ata/pages/ata_form_page.dart`
- `lib/features/ajuste/pages/ajuste_form_page.dart`

**O que foi feito:**

1. Adicionado método `_validateDraft()` em cada formulário validando apenas os campos mínimos:

   | Formulário | Campos obrigatórios para rascunho |
   |---|---|
   | Edital | `codigoEdital`, `dataDocumento` |
   | Licitação | `editalId` (vínculo), `codigoEdital` |
   | Ata | `editalId` (vínculo), `codigoEdital`, `codigoAta` |
   | Ajuste | `editalId` (vínculo), `codigoEdital`, `codigoContrato` |

2. `_saveDraft()` agora chama `_validateDraft()` — sem `_formKey.currentState!.validate()`, sem exigência de itens/datas.
3. `_enviar()` mantém validação completa (`_formKey.currentState!.validate()` + checagens de itens/datas).
4. Banco já aceita colunas opcionais como null — nenhuma alteração no schema.

---

### ~~Etapa 4 — Importação PDF + Gemini no Edital~~ ✅ CONCLUÍDA (08/04/2026)

**Arquivos criados/afetados:**
- `pubspec.yaml` — adicionado `google_generative_ai: ^0.4.6`
- `lib/core/database/tables.dart` — nova tabela `AppSettings` (chave/valor)
- `lib/core/database/daos/app_settings_dao.dart` — novo DAO com `get`, `set`, `delete`; constantes `SettingsKeys.geminiApiKey` e `SettingsKeys.geminiModel`
- `lib/core/database/app_database.dart` — versão do schema elevada para 5, migração cria `app_settings`
- `lib/core/database/database_providers.dart` — providers `appSettingsDaoProvider` e `geminiServiceProvider`
- `lib/core/services/gemini_service.dart` — novo (Sugestão 2: serviço genérico, agnóstico de formulário)
- `lib/features/edital/widgets/gemini_import_dialog.dart` — novo (dialog em 2 etapas: loading com `LinearProgressIndicator` + revisão por campo)
- `lib/features/edital/pages/edital_form_page.dart` — botão "Importar do PDF" adicionado à `AppBar` à esquerda de "Salvar Rascunho"; método `_importFromPdf()`
- `lib/features/admin/pages/admin_page.dart` — 4ª aba "IA / Gemini" para configurar chave de API e nome do modelo

**O que foi feito:**

1. **`google_generative_ai`** adicionado ao `pubspec.yaml`.
2. **Tabela `AppSettings`** criada no banco (chave/valor genérico), com schema migration v5.
3. **`GeminiService`** (Sugestão 2): serviço genérico reutilizável — recebe PDF + lista de `GeminiField`, lê a chave/modelo das `AppSettings`, constrói o prompt e retorna `GeminiExtractionResult`. Pode ser reutilizado em qualquer módulo futuro.
4. **`GeminiImportDialog`** com dois estágios:
   - **Stage 1** (`_GeminiLoadingDialog`): `LinearProgressIndicator` + mensagem "Analisando PDF..." enquanto a API responde (Sugestão 4); exibe erro inline se a chamada falhar.
   - **Stage 2** (`_GeminiReviewDialog`): tabela com 4 colunas (campo, valor atual, sugestão Gemini, checkbox); botões "Selecionar tudo" / "Desmarcar tudo"; campos sem sugestão ficam desabilitados.
5. **Botão "Importar do PDF"** na `AppBar` do `EditalFormPage`, à esquerda de "Salvar Rascunho", com ícone `auto_fix_high`; fica desabilitado durante a chamada exibindo um `CircularProgressIndicator` inline.
6. **Aba "IA / Gemini"** no `AdminPage`: campos para chave de API (com toggle mostrar/ocultar) e nome do modelo (padrão `gemini-2.0-flash` quando em branco).

---

### Etapa 5 — Importação CSV: Itens de Compra (Edital)

**Arquivos novos/afetados:**
- `lib/features/edital/widgets/csv_itens_compra_import_dialog.dart` (novo)
- `lib/features/edital/pages/edital_form_page.dart` (botão na seção de itens)
- `pubspec.yaml` (nova dependência: `csv`)

**O que fazer:**

1. Adicionar dependência `csv: ^6.x` ao `pubspec.yaml`.

2. **Layout CSV para itens de compra (proposta — confirmar):**

   | Coluna | Campo no JSON | Tipo | Obrigatório |
   |---|---|---|---|
   | `numero_item` | `numeroItem` | inteiro | sim |
   | `tipo_item` | `tipoItemId` | inteiro (id) | sim |
   | `criterio_julgamento` | `criterioJulgamentoId` | inteiro (id) | sim |
   | `quantidade` | `quantidade` | decimal | sim |
   | `unidade` | `unidadeFornecimento` | string (até 6 chars) | sim |
   | `valor_unitario_estimado` | `valorUnitarioEstimado` | decimal | não |
   | `valor_total_estimado` | `valorTotalEstimado` | decimal | não |
   | `descricao` | `descricaoItem` | string | não |
   | `material_servico` | `materialOuServico` | string (M/S) | não |
   | `criterio_sustentabilidade` | `criterioSustentabilidadeId` | inteiro (id) | não |
   | `situacao_compra` | `situacaoCompraItemId` | inteiro (id) | não |

   > **Pergunta 5:** Confirmar/ajustar o layout acima do CSV de itens de compra. Deve usar vírgula ou ponto-e-vírgula como separador? A primeira linha é cabeçalho?

3. **`CsvItensCompraImportDialog`:** dialog com:
   - Botão para selecionar arquivo CSV
   - Preview da tabela com os dados lidos (role horizontal se necessário)
   - Linhas com erro de parse destacadas em vermelho
   - Checkbox "substituir todos os itens atuais" vs. "adicionar ao final"
   - Botão "Importar"

4. **Botão no EditalFormPage:** dentro da seção "Itens de Compra", ao lado do botão "Adicionar Item", ícone "upload_file" e label "Importar CSV".

**Estimativa de tokens:** ~25 k

---

### Etapa 6 — Importação CSV: Itens de Licitação + Licitantes

**Arquivos novos/afetados:**
- `lib/features/licitacao/widgets/csv_itens_licitacao_import_dialog.dart` (novo)
- `lib/features/licitacao/pages/licitacao_form_page.dart` (botão na seção de itens)

**O que fazer:**

1. Reutilizar dependência `csv` (adicionada na Etapa 5).

2. **Layout CSV (proposta — confirmar):**

   A estrutura da licitação é hierárquica: cada item possui N licitantes. Proposta: **dois arquivos CSV separados** — um para itens, outro para licitantes — vinculados por `numero_item`.

   **Arquivo 1 — Itens:**

   | Coluna | Campo no JSON | Tipo |
   |---|---|---|
   | `numero_item` | `numeroItem` | inteiro |
   | `tipo_beneficio` | `tipoBeneficioId` | inteiro (id) |
   | `inciso_i_art_24` | `incisoIArt24` | booleano (S/N) |
   | `resultado` | `resultadoItemId` | inteiro (id) |
   | `valor_estimado` | `valorEstimado` | decimal |

   **Arquivo 2 — Licitantes por item:**

   | Coluna | Campo no JSON | Tipo |
   |---|---|---|
   | `numero_item` | (vínculo) | inteiro |
   | `ni_fornecedor` | `niFornecedor` | string (14 dígitos) |
   | `tipo_pessoa` | `tipoPessoa` | string (F/J) |
   | `nome_razao_social` | `nomeRazaoSocialFornecedor` | string |
   | `situacao_licitante` | `situacaoLicitanteId` | inteiro (id) |
   | `descricao_situacao` | `descricaoSituacaoLicitante` | string |
   | `valor_proposta` | `valorProposta` | decimal |
   | `percentual_desconto` | `percentualDesconto` | decimal |
   | `classificacao` | `classificacao` | inteiro |
   | `valor_negociado` | `valorNegociado` | decimal |
   | `percentual_negociado` | `percentualNegociado` | decimal |

   > **Pergunta 6:** Confirmar layout acima. Preferência por **dois arquivos** (itens + licitantes) ou **um arquivo único** onde as linhas de licitante são sub-linhas do item (ex.: coluna `tipo_linha` = `ITEM` ou `LICITANTE`)?

   > **Pergunta 7:** O CSV de licitantes deve aceitar múltiplos licitantes por item (N linhas com o mesmo `numero_item`)?

3. **`CsvItensLicitacaoImportDialog`:** dialog com abas ou dois passos:
   - Passo 1: seleção e preview do arquivo de itens
   - Passo 2: seleção e preview do arquivo de licitantes
   - Botão "Importar Tudo"

4. **Botão na LicitacaoFormPage:** dentro da seção "Itens", ao lado de "Adicionar Item", ícone "upload_file" e label "Importar CSV".

**Estimativa de tokens:** ~30 k

---

## Dependências Novas a Adicionar

| Pacote | Finalidade | Etapa |
|---|---|---|
| `google_generative_ai` | Client SDK oficial do Gemini | Etapa 4 |
| `csv` | Parse de arquivos CSV | Etapa 5 |

---

## Perguntas em Aberto (aguardando respostas do usuário)

### ~~Gemini~~ — ✅ Todas respondidas e implementadas

### CSV — Itens de Compra (Edital)

- **Pergunta 5:** Confirmar/ajustar colunas do CSV de itens de compra. Separador: vírgula ou ponto-e-vírgula?

### CSV — Itens de Licitação

- **Pergunta 6:** Preferência por dois arquivos CSV separados (itens + licitantes) ou arquivo único com tipos de linha?
- **Pergunta 7:** Confirmar que múltiplos licitantes por item são representados como múltiplas linhas com o mesmo `numero_item`.

---

## Sugestões

1. ~~**Widget `_SectionCard` compartilhado:** Como `_SectionCard` será idêntico em todos os formulários após as Etapas 1 e 2, considerar extraí-lo para `lib/shared/widgets/section_card.dart` para evitar duplicação.~~ ✅ CONCLUÍDA (08/04/2026) — `SectionCard` extraído em `lib/shared/widgets/section_card.dart`; todos os formulários o importam.

2. ~~**Serviço Gemini genérico:** O `GeminiService` pode ser construído de forma agnóstica ao formulário e reutilizado futuramente em outros módulos (ex.: importar um contrato de ajuste via PDF).~~ ✅ CONCLUÍDA (08/04/2026) — `GeminiService` (em `lib/core/services/gemini_service.dart`) recebe `List<GeminiField>` arbitrária e é totalmente agnóstico ao formulário.

3. **Preview CSV com DataTable:** Usar `DataTable` do Flutter (com scroll horizontal via `SingleChildScrollView`) para exibir o preview das linhas importadas — solução nativa, sem dependência extra.

4. ~~**Feedback de progresso no Gemini:** A chamada ao Gemini pode levar alguns segundos. Exibir um `LinearProgressIndicator` ou `CircularProgressIndicator` com mensagem "Analisando PDF..." durante a chamada.~~ ✅ CONCLUÍDA (08/04/2026) — `_GeminiLoadingDialog` exibe `LinearProgressIndicator` + mensagem "Analisando PDF..." enquanto a chamada está em andamento.

5. **Formato de datas no CSV:** Definir explicitamente o formato esperado (sugestão: `dd/MM/yyyy`) e exibir mensagem de erro clara se o parse falhar.

6. ~~**Modo draft antes da API:** O botão "Importar do PDF" não deve exigir que o usuário já tenha salvo um rascunho — deve funcionar em formulário novo.~~ ✅ Contemplado pela Etapa 3: `_saveDraft` agora é acionável com campos mínimos, sem exigir estado anterior salvo.

---

## Ordem de Execução Recomendada

```
Etapa 1 ✅  →  Etapa 2 ✅  →  Etapa 3 ✅  →  Etapa 4 ✅  →  Etapa 5  →  Etapa 6
  (Ata)        (Ajuste)       (Draft)        (Gemini)     (CSV Edital) (CSV Licit.)
```

As Etapas 1–4 estão concluídas. As Etapas 5 e 6 dependem da instalação do pacote `csv` (instalado na Etapa 5; a Etapa 6 reutiliza).
