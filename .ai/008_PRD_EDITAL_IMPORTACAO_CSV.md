# PRD – Importação de Itens do Edital via Planilha CSV

**Módulo:** Edital (Fase 4 – Módulo 1)  
**Solicitante:** Serviço de Licitações  
**Data:** 2026-04-09  

---

## 1. Contexto e Problema

O Serviço de Licitações lança o **Edital** e a **Licitação** na AUDESP ao mesmo tempo, após o encerramento do certame. Atualmente:

- A **Licitação** já suporta importação de itens via planilha CSV ("Planilha de Itens" / complemento + portais BLL/BrConectado).
- O **Edital** exige que os itens sejam preenchidos manualmente, um a um, através do diálogo `ItemCompraDialog`.

Isso significa que o usuário precisa digitar os mesmos itens duas vezes (ou mais), o que gera retrabalho e risco de inconsistências entre Edital e Licitação.

**Objetivo:** Permitir que o usuário importe os itens do Edital usando a **mesma planilha** já utilizada na Licitação, com o mínimo de colunas adicionais necessárias.

---

## 2. Escopo

### Incluso
- Novo botão "Importar Itens via CSV" na seção de itens do `EditalFormPage`.
- Parser de CSV que lê as colunas já existentes na planilha complementar da Licitação **e** colunas opcionais específicas do Edital.
- Diálogo de confirmação/revisão antes de aplicar os itens importados.
- Tratamento de erros (colunas ausentes, valores inválidos, encoding).

### Excluído
- Importação a partir dos portais BLL/BrConectado (os portais não exportam metadados de edital).
- Geração automática de planilha a partir de dados existentes no sistema.

---

## 3. Dados: Campos do Item

### Edital (`Item de Compra`)

| Campo AUDESP | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `numeroItem` | int | Sim | Número sequencial do item |
| `descricao` | String | Sim | Descrição do item |
| `materialOuServico` | String (M/S) | Sim | M = Material, S = Serviço |
| `quantidade` | double | Sim | Quantidade estimada |
| `unidadeMedida` | String | Sim | Ex: UN, KG, M² |
| `valorUnitarioEstimado` | double | Não | Valor unitário médio |
| `valorTotal` | double | Calculado | `quantidade × valorUnitarioEstimado` |
| `criterioJulgamentoId` | int | Não | 1=Menor Preço, 2=Maior Desconto… |
| `tipoBeneficioId` | int | Não | Benefício ME/EPP |
| `incentivoProdutivoBasico` | bool | Não | Default: false |
| `orcamentoSigiloso` | bool | Não | Default: false |
| `itemCategoriaId` | int | Não | Categoria do item |

### Planilha Complementar da Licitação (existente)

| Coluna CSV | Mapeamento Licitação | Reutilizável para Edital? |
|---|---|---|
| `NumeroItem` | `numeroItem` | ✅ Sim |
| `TipoOrcamento` | `tipoOrcamento` | ❌ Não (campo de licitação) |
| `ValorEstimado` | `valor` (médio dos orçamentos) | ✅ → `valorUnitarioEstimado` |
| `DataOrcamento` | `dataOrcamento` | ❌ Não |
| `SituacaoCompraItem` | `situacaoCompraItemId` | ❌ Não |
| `DataSituacao` | `dataSituacaoItem` | ❌ Não |
| `TipoValor` | `tipoValor` | ❌ Não |
| `TipoProposta` | `tipoProposta` | ❌ Não |

**Conclusão:** apenas `NumeroItem` e `ValorEstimado` podem ser reutilizados diretamente. As demais colunas de Edital são específicas e precisam ser adicionadas.

---

## 4. Proposta de Template CSV Estendido

A solução adotada é **estender o template existente** com colunas opcionais para o Edital. Colunas que o Edital não precisa são simplesmente ignoradas no parser da Licitação (já funciona assim). Colunas que o Edital precisa e que a Licitação não usa ficam em branco para usuários que só preenchem a Licitação.

### Template CSV proposto

```
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitario;CriterioJulgamento;TipoBeneficio;TipoOrcamento;ValorEstimado;DataOrcamento;SituacaoCompraItem;DataSituacao;TipoValor;TipoProposta
1;Cadeira ergonômica;M;10;UN;850,00;MENOR_PRECO;SEM_BENEFICIO;GLOBAL;850,00;01/01/2025;HOMOLOGADO;15/01/2025;MOEDA;GLOBAL
```

#### Mapeamento de coluna → campo

| Coluna | Edital | Licitação |
|---|---|---|
| `NumeroItem` | `numeroItem` | `numeroItem` |
| `Descricao` | `descricao` | — (ignorado) |
| `MaterialOuServico` | `materialOuServico` (M/S) | — (ignorado) |
| `Quantidade` | `quantidade` | — (ignorado) |
| `UnidadeMedida` | `unidadeMedida` | — (ignorado) |
| `ValorUnitario` | `valorUnitarioEstimado` | — (ignorado) |
| `CriterioJulgamento` | `criterioJulgamentoId` (código ou texto) | — (ignorado) |
| `TipoBeneficio` | `tipoBeneficioId` (código ou texto) | — (ignorado) |
| `TipoOrcamento` | — (ignorado) | `tipoOrcamento` |
| `ValorEstimado` | fallback para `valorUnitarioEstimado` se `ValorUnitario` ausente | `valor` |
| `DataOrcamento` | — (ignorado) | `dataOrcamento` |
| `SituacaoCompraItem` | — (ignorado) | `situacaoCompraItemId` |
| `DataSituacao` | — (ignorado) | `dataSituacaoItem` |
| `TipoValor` | — (ignorado) | `tipoValor` |
| `TipoProposta` | — (ignorado) | `tipoProposta` |

**Retrocompatibilidade:** O template antigo (sem as novas colunas) continua funcionando no parser da Licitação — nenhuma quebra.

---

## 5. Fluxo de Uso

```
[Usuário abre o Edital] 
  → Seção "Itens de Compra"
  → Botão "Importar via Planilha"
  → FilePicker abre seleção de CSV
  → Parser lê e valida colunas obrigatórias (NumeroItem, Descricao, MaterialOuServico, Quantidade, UnidadeMedida)
  → Exibe resumo: "N itens encontrados – X com valor, Y sem valor"
  → Se houver itens já preenchidos → diálogo "Substituir itens existentes?"
  → Confirma → lista de itens preenchida no estado
```

---

## 6. Arquitetura Técnica

### 6.1 Novos arquivos

```
lib/features/edital/
  csv/
    edital_csv.dart          # barrel file
    models/
      edital_item_csv_model.dart
    parsers/
      edital_complemento_csv_parser.dart
    mappers/
      edital_complemento_csv_mapper.dart
```

### 6.2 Reutilização

- `CsvUtils` (`lib/features/licitacao/csv/parsers/_csv_utils.dart`) — reutilizar diretamente (mover para `lib/core/utils/csv_utils.dart` ou importar cross-feature).
- `ComplementoCsvParser` — NÃO herdar; criar parser independente para o Edital que apenas lê as colunas relevantes.

### 6.3 Widget

Um novo `edital_import_csv_dialog.dart` (ou integração direta via `FilePicker` sem diálogo intermediário) dentro de `lib/features/edital/widgets/`.

---

## 7. Decisões Arquiteturais e Questionamentos

### ❓ D1 – Mover `CsvUtils` para `core/`?

**Contexto:** `_csv_utils.dart` está em `lib/features/licitacao/csv/parsers/` e é privado (prefixo `_`). Para reutilizá-lo no Edital, precisamos:
- **Opção A:** Mover para `lib/core/utils/csv_utils.dart` e tornar público.
- **Opção B:** Duplicar a lógica no parser do Edital (má prática).
- **Opção C:** Mudar o arquivo para `lib/features/licitacao/csv/parsers/csv_utils.dart` (sem `_`) mas mantê-lo na feature de Licitação — e importar cross-feature.

**Recomendação:** Opção A (mover para `core/`). O `CsvUtils` é genérico o suficiente para ser compartilhado.

**Decisão necessária:** ✅ Mover para `core/utils/csv_utils.dart`? Ou manter na Licitação e importar cross-feature?

---

### ❓ D2 – Representação de `CriterioJulgamento` e `TipoBeneficio` no CSV

**Contexto:** Esses campos são enums da AUDESP com IDs inteiros. No CSV atual, `TipoOrcamento` e `SituacaoCompraItem` usam strings legíveis (`GLOBAL`, `HOMOLOGADO`) mapeadas para inteiros.

**Opções para o CSV do Edital:**
- **Opção A:** Usar strings legíveis mapeadas (ex: `MENOR_PRECO` → 1, `SEM_BENEFICIO` → 0).
- **Opção B:** Usar os códigos inteiros diretamente (ex: `1`, `0`).
- **Opção C:** Aceitar ambos.

**Recomendação:** Opção A com fallback numérico (Opção C), igual ao padrão já usado na Licitação.

---

### ❓ D3 – `valorTotal` calculado ou importado?

**Contexto:** O campo `valorTotal` do Edital pode ser calculado como `quantidade × valorUnitarioEstimado`, mas em alguns casos pode precisar de arredondamento específico.

**Recomendação:** Calcular automaticamente no parser; o usuário pode editar manualmente após a importação via `ItemCompraDialog`.

---

### ❓ D4 – Revisão por item antes de confirmar?

**Contexto:** O diálogo de importação da Licitação mostra um SnackBar de confirmação mas não permite revisar item a item. Para o Edital, faz sentido mostrar uma prévia em lista antes de confirmar, pois os dados (descrição, quantidade) são mais críticos.

**Sugestão:** Mostrar diálogo com DataTable resumindo os itens encontrados, com a opção de confirmar ou cancelar.

**Decisão necessária:** ✅ Revisão prévia em diálogo (mais segura) ou importação direta com SnackBar (mais ágil)?

---

## 8. Campos Obrigatórios vs. Opcionais no CSV

Para o parser aceitar uma linha como válida:

| Campo | Obrigatório no CSV |
|---|---|
| `NumeroItem` | Sim |
| `Descricao` | Sim |
| `MaterialOuServico` | Sim |
| `Quantidade` | Sim |
| `UnidadeMedida` | Sim |
| `ValorUnitario` ou `ValorEstimado` | Não (item importado sem valor) |
| `CriterioJulgamento` | Não |
| `TipoBeneficio` | Não |

---

## 9. Alterações no Template de Planilha

Atualizar o arquivo `docs/template_itens.csv` com as novas colunas (mantendo retrocompatibilidade). Publicar uma nova versão do template para os usuários.

---

## 10. Plano de Implementação

| # | Tarefa | Complexidade |
|---|---|---|
| 1 | Mover `CsvUtils` para `core/utils/` (ou decisão D1 alternativa) | Baixa |
| 2 | Criar `EditalItemCsvModel` | Baixa |
| 3 | Criar `EditalComplementoCsvParser` | Média |
| 4 | Criar `EditalComplementoCsvMapper` | Baixa |
| 5 | Criar widget de importação no Edital | Média |
| 6 | Integrar botão na `EditalFormPage` | Baixa |
| 7 | Atualizar `template_itens.csv` com novas colunas | Baixa |
| 8 | Testes unitários do parser | Média |
