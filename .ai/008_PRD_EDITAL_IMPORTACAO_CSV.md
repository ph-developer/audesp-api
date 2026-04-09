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

**Objetivo:** Permitir que o usuário importe os itens do Edital usando a **mesma planilha** já utilizada na Licitação, com o mínimo de colunas adicionais necessárias, respeitando as regras de negócio específicas de valores para cada módulo.

---

## 2. Escopo

### Incluso
- Novo botão "Importar Itens via CSV" na seção de itens do `EditalFormPage`.
- Parser de CSV que lê as colunas já existentes na planilha complementar da Licitação **e** colunas opcionais específicas do Edital.
- Diálogo de confirmação/revisão antes de aplicar os itens importados.
- Tratamento de erros (colunas ausentes, valores inválidos, encoding).
- **Tratamento rigoroso de Valores:** Separação entre "Menor Valor" (Edital) e "Média de Valores" (Licitação).

### Excluído
- Importação a partir dos portais BLL/BrConectado (os portais não exportam metadados de edital).
- Geração automática de planilha a partir de dados existentes no sistema.

---

## 3. Dados: Campos do Item e Regra de Valores

**Atenção Crítica:** Existe uma diferença fundamental na regra de negócio dos valores entre os módulos:
- **Edital:** O campo `valorUnitarioEstimado` deve conter sempre o **menor valor orçado**.
- **Licitação:** O campo `valor` na lista de itens deve conter a **média dos valores orçados**.

### Edital (`Item de Compra`)

| Campo AUDESP | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `numeroItem` | int | Sim | Número sequencial do item |
| `descricao` | String | Sim | Descrição do item |
| `materialOuServico` | String (M/S) | Sim | M = Material, S = Serviço |
| `quantidade` | double | Sim | Quantidade estimada |
| `unidadeMedida` | String | Sim | Ex: UN, KG, M² |
| `valorUnitarioEstimado` | double | Não | **Menor valor orçado** (Teto de referência) |
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
| `ValorEstimado` | `valor` (**média dos orçamentos**) | ❌ **Não** (O edital exige o Menor Valor, não a média) |
| `DataOrcamento` | `dataOrcamento` | ❌ Não |
| `SituacaoCompraItem` | `situacaoCompraItemId` | ❌ Não |
| `DataSituacao` | `dataSituacaoItem` | ❌ Não |
| `TipoValor` | `tipoValor` | ❌ Não |
| `TipoProposta` | `tipoProposta` | ❌ Não |

---

## 4. Proposta de Template CSV Estendido

A solução adotada é **estender o template existente** com colunas opcionais para o Edital. Para evitar inconsistências fiscais e de auditoria, as colunas de valor serão estritamente separadas, sem fallbacks matematicamente incorretos.

### Template CSV proposto

```csv
NumeroItem;Descricao;MaterialOuServico;Quantidade;UnidadeMedida;ValorUnitarioMenor;CriterioJulgamento;TipoBeneficio;TipoOrcamento;ValorEstimadoMedia;DataOrcamento;SituacaoCompraItem;DataSituacao;TipoValor;TipoProposta
1;Cadeira ergonômica;M;10;UN;800,00;MENOR_PRECO;SEM_BENEFICIO;GLOBAL;850,00;01/01/2025;HOMOLOGADO;15/01/2025;MOEDA;GLOBAL
```

*(Nota: Na linha acima, o menor orçado foi 800,00, que vai pro Edital. A média foi 850,00, que vai pra Licitação).*

#### Mapeamento de coluna → campo

| Coluna | Edital | Licitação |
|---|---|---|
| `NumeroItem` | `numeroItem` | `numeroItem` |
| `Descricao` | `descricao` | — (ignorado) |
| `MaterialOuServico` | `materialOuServico` (M/S) | — (ignorado) |
| `Quantidade` | `quantidade` | — (ignorado) |
| `UnidadeMedida` | `unidadeMedida` | — (ignorado) |
| `ValorUnitarioMenor` | `valorUnitarioEstimado` (**Menor**) | — (ignorado) |
| `CriterioJulgamento` | `criterioJulgamentoId` (código ou texto) | — (ignorado) |
| `TipoBeneficio` | `tipoBeneficioId` (código ou texto) | — (ignorado) |
| `TipoOrcamento` | — (ignorado) | `tipoOrcamento` |
| `ValorEstimadoMedia`| — (ignorado) | `valor` (**Média**) |
| `DataOrcamento` | — (ignorado) | `dataOrcamento` |
| `SituacaoCompraItem` | — (ignorado) | `situacaoCompraItemId` |
| `DataSituacao` | — (ignorado) | `dataSituacaoItem` |
| `TipoValor` | — (ignorado) | `tipoValor` |
| `TipoProposta` | — (ignorado) | `tipoProposta` |

**Retrocompatibilidade:** O template antigo continuará funcionando no parser da Licitação. Se as colunas do Edital faltarem, a Licitação simplesmente as ignora. Se a coluna `ValorUnitarioMenor` faltar no momento da importação do Edital, o item será importado sem valor (para preenchimento manual posterior).

---

## 5. Fluxo de Uso

```
[Usuário abre o Edital] 
  → Seção "Itens de Compra"
  → Botão "Importar via Planilha"
  → FilePicker abre seleção de CSV
  → Parser lê e valida colunas obrigatórias (NumeroItem, Descricao, MaterialOuServico, Quantidade, UnidadeMedida)
  → Exibe resumo: "N itens encontrados – X com valor unitário (menor preço), Y sem valor"
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
Sim (mover para `core/utils/csv_utils.dart`). O `CsvUtils` é genérico o suficiente para ser compartilhado entre Edital e Licitação.

### ❓ D2 – Representação de `CriterioJulgamento` e `TipoBeneficio` no CSV
Usar strings legíveis (ex: `MENOR_PRECO`) com fallback numérico, igual ao padrão já usado na Licitação.

### ❓ D3 – `valorTotal` calculado ou importado?
Calcular automaticamente no parser (`Quantidade` × `ValorUnitarioMenor`); o usuário pode editar manualmente após a importação via `ItemCompraDialog` caso haja arredondamentos em centavos.

### ❓ D4 – Revisão por item antes de confirmar?
Mostrar diálogo com DataTable resumindo os itens encontrados (foco especial em destacar itens onde o "Menor Valor" não foi preenchido), com a opção de confirmar ou cancelar, garantindo mais segurança na operação.

---

## 8. Campos Obrigatórios vs. Opcionais no CSV

Para o parser do Edital aceitar uma linha como válida:

| Campo | Obrigatório no CSV |
|---|---|
| `NumeroItem` | Sim |
| `Descricao` | Sim |
| `MaterialOuServico` | Sim |
| `Quantidade` | Sim |
| `UnidadeMedida` | Sim |
| `ValorUnitarioMenor` | Não (item importado com valor zerado/nulo) |
| `CriterioJulgamento` | Não |
| `TipoBeneficio` | Não |

---

## 9. Alterações no Template de Planilha

1. Renomear `ValorEstimado` para `ValorEstimadoMedia` (para clareza).
2. Adicionar `ValorUnitarioMenor`.
3. Atualizar o arquivo `docs/template_itens.csv` com as novas colunas (mantendo retrocompatibilidade). 
4. Publicar uma nova versão do template e notificar a equipe de suporte/usuários sobre a distinção dos valores.

---

## 10. Plano de Implementação

| # | Tarefa | Complexidade | Completo |
|---|---|---|---|
| 1 | Mover `CsvUtils` para `core/utils/` | Baixa | ✅ |
| 2 | Criar `EditalItemCsvModel` | Baixa | ✅ |
| 3 | Criar `EditalComplementoCsvParser` | Média | ✅ |
| 4 | Criar `EditalComplementoCsvMapper` | Baixa | ✅ |
| 5 | Criar widget de pré-visualização e importação no Edital | Média | ✅ |
| 6 | Integrar botão na `EditalFormPage` | Baixa | ✅ |
| 7 | Atualizar `template_itens.csv` com as novas colunas de valores | Baixa | ✅ |
| 8 | Escrever testes unitários do parser (foco na separação de valores) | Média | ✅ |
| 9 | Rescrever/corrigir testes unitários | Média | ✅ |
