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

### Etapa 1 — Estilo: Formulário de Ata

**Arquivos afetados:** `lib/features/ata/pages/ata_form_page.dart`

**O que fazer:**

1. Adicionar a classe `_SectionCard` ao arquivo (copiar da implementação do edital):
   ```dart
   class _SectionCard extends StatelessWidget {
     final String title;
     final List<Widget> children;
     const _SectionCard({required this.title, required this.children});
     @override Widget build(BuildContext context) { ... }
   }
   ```
2. Remover a classe `_SectionHeader`.
3. Converter cada bloco de seção para retornar um `_SectionCard(...)`, agrupando os campos filhos.
4. Remover `border: OutlineInputBorder()` explícito de todos os `TextFormField` e `DropdownButtonFormField` (deixar cair para o tema).
5. Manter o `_DateField` (já está implementado no arquivo, é reutilizável).
6. O layout do corpo passa de `SingleChildScrollView > Column` (flat) para `SingleChildScrollView > Column > _SectionCard` (idêntico ao edital).

**Seções da Ata a converter:**
- Vínculo com Edital
- Descritor
- Dados da Ata
- Itens da Licitação Referenciados

**Estimativa de tokens:** ~18 k (arquivo médio)

---

### Etapa 2 — Estilo: Formulário de Ajuste

**Arquivos afetados:** `lib/features/ajuste/pages/ajuste_form_page.dart`

**O que fazer:** idêntico à Etapa 1, mas para o formulário de Ajuste — que é o maior do projeto.

**Seções do Ajuste a converter:**
- Vínculo com Edital
- Vínculo com Ata
- Descritor
- Fontes de Recurso
- Itens Contratados
- Dados do Contrato
- Classificações de Despesa
- Fornecedor
- Subcontratado (opcional)
- Objeto e Valores
- Datas
- Tipo de Objeto do Contrato

**Estimativa de tokens:** ~35 k (arquivo extenso)

---

### Etapa 3 — Rascunho Parcial (sem validação completa)

**Arquivos afetados:**
- `lib/features/edital/pages/edital_form_page.dart`
- `lib/features/licitacao/pages/licitacao_form_page.dart`
- `lib/features/ata/pages/ata_form_page.dart`
- `lib/features/ajuste/pages/ajuste_form_page.dart`

**O que fazer:**

1. Adicionar método `_validateDraft()` em cada formulário que valida apenas os campos mínimos:

   | Formulário | Campos obrigatórios para rascunho |
   |---|---|
   | Edital | `codigoEdital`, `dataDocumento` |
   | Licitação | `editalId` (vínculo), `codigoEdital` |
   | Ata | `editalId` (vínculo), `codigoEdital`, `codigoAta` |
   | Ajuste | `editalId` (vínculo), `codigoEdital`, `codigoContrato` |

2. Modificar `_saveDraft()` para chamar `_validateDraft()` no lugar de `_formKey.currentState!.validate()`.
3. Manter `_enviar()` chamando `_formKey.currentState!.validate()` (validação completa).
4. O banco de dados já aceita colunas opcionais como null; apenas garantir que os campos estruturados (usados como chave) não sejam vazios.

**Estimativa de tokens:** ~25 k (4 arquivos lidos + editados)

---

### Etapa 4 — Importação PDF + Gemini no Edital

**Arquivos novos/afetados:**
- `pubspec.yaml` (nova dependência)
- `lib/core/services/gemini_service.dart` (novo)
- `lib/features/edital/widgets/gemini_import_dialog.dart` (novo)
- `lib/features/edital/pages/edital_form_page.dart` (botão + integração)

**O que fazer:**

1. **Dependência:** adicionar `google_generative_ai` ao `pubspec.yaml`.

   > **Pergunta 1:** A chave de API do Gemini deve ser armazenada no arquivo `.env` já existente (em `assets/.env`, lida via `flutter_dotenv`) ou em configuração acessível pelo usuário nas telas de administração?
   > **Resposta 1**: A chave da API deve ser alterável pelo admin na tela de administração. 

2. **`GeminiService`:** serviço que recebe o path do PDF, lê os bytes, envia à API Gemini com instruções e retorna `Map<String, dynamic>` com os campos identificados.

   > **Pergunta 2:** Qual modelo Gemini usar? Sugestão: `gemini-2.0-flash` (suporte nativo a PDF, boa relação custo/velocidade).
   > **Resposta 2:** O nome do modelo deve ser digitável pelo admin na tela de administração.

3. **Prompt Gemini (a definir):**
   O prompt instruirá o modelo a extrair do PDF os seguintes campos do edital:
   `codigoEdital`, `dataDocumento`, `tipoInstrumentoConvocatorioId`, `modalidadeId`, `modoDisputaId`, `numeroCompra`, `anoCompra`, `numeroProcesso`, `objetoCompra`, `srp`, `amparoLegalId`, `dataAberturaProposta`, `dataEncerramentoProposta`.

   > **Pergunta 3:** Confirmar lista de campos que o Gemini deve tentar preencher. Há campos adicionais ou que devem ser excluídos?

   > **Pergunta 4:** O Gemini deve tentar extrair também os **itens de compra** (lista)? Isso aumenta a complexidade do prompt e do dialog de revisão.
   > **Resposta 4:** Não.

4. **`GeminiImportDialog`:** dialog `AlertDialog` que mostra uma tabela com:
   - Nome do campo
   - Valor atual no formulário (pode ser vazio)
   - Valor sugerido pelo Gemini
   - Checkbox para o usuário aceitar/rejeitar cada campo individualmente

5. **Botão no EditalFormPage:** posicionado à **esquerda** do botão "Salvar Rascunho" na `AppBar`, com ícone de "auto_fix_high" ou "psychology" e label "Importar do PDF".
   - Ao clicar: abre `FilePicker` (PDF) → chama `GeminiService` → exibe `GeminiImportDialog`
   - Se o usuário confirmar seleção: popula os campos aceitos no formulário

**Estimativa de tokens:** ~40 k (novo serviço + novo dialog + edição do form)

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

### Gemini

- **Pergunta 1:** A chave de API do Gemini deve ficar no `.env` (já existente) ou em tela de configuração acessível pelo usuário?
- **Pergunta 2:** Modelo Gemini a usar? Sugestão: `gemini-2.0-flash`.
- **Pergunta 3:** Confirmar lista de campos que o Gemini deve tentar extrair do PDF do edital.
- **Pergunta 4:** O Gemini deve tentar extrair também a **lista de itens de compra** do PDF?

### CSV — Itens de Compra (Edital)

- **Pergunta 5:** Confirmar/ajustar colunas do CSV de itens de compra. Separador: vírgula ou ponto-e-vírgula?

### CSV — Itens de Licitação

- **Pergunta 6:** Preferência por dois arquivos CSV separados (itens + licitantes) ou arquivo único com tipos de linha?
- **Pergunta 7:** Confirmar que múltiplos licitantes por item são representados como múltiplas linhas com o mesmo `numero_item`.

---

## Sugestões

1. **Widget `_SectionCard` compartilhado:** Como `_SectionCard` será idêntico em todos os formulários após as Etapas 1 e 2, considerar extraí-lo para `lib/shared/widgets/section_card.dart` para evitar duplicação. Pode ser feito junto a qualquer etapa ou como tarefa separada de limpeza.

2. **Serviço Gemini genérico:** O `GeminiService` pode ser construído de forma agnóstica ao formulário e reutilizado futuramente em outros módulos (ex.: importar um contrato de ajuste via PDF).

3. **Preview CSV com DataTable:** Usar `DataTable` do Flutter (com scroll horizontal via `SingleChildScrollView`) para exibir o preview das linhas importadas — solução nativa, sem dependência extra.

4. **Feedback de progresso no Gemini:** A chamada ao Gemini pode levar alguns segundos. Exibir um `LinearProgressIndicator` ou `CircularProgressIndicator` com mensagem "Analisando PDF..." durante a chamada.

5. **Formato de datas no CSV:** Definir explicitamente o formato esperado (sugestão: `dd/MM/yyyy`) e exibir mensagem de erro clara se o parse falhar.

6. **Modo draft antes da API:** O botão "Importar do PDF" não deve exigir que o usuário já tenha salvo um rascunho — deve funcionar em formulário novo.

---

## Ordem de Execução Recomendada

```
Etapa 1  →  Etapa 2  →  Etapa 3  →  Etapa 4  →  Etapa 5  →  Etapa 6
 (Ata)     (Ajuste)   (Draft)    (Gemini)    (CSV Edital) (CSV Licit.)
```

As Etapas 1 e 2 são independentes entre si e podem ser executadas em qualquer ordem. A Etapa 3 é independente de todas. As Etapas 5 e 6 dependem da instalação do pacote `csv` (instalado na Etapa 5; a Etapa 6 reutiliza). A Etapa 4 é independente das demais.
