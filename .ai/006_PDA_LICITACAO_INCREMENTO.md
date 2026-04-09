# Fluxo Unificado de Importação CSV (Portal + Complementar)

## 📌 Objetivo
Permitir a importação de uma planilha CSV auxiliar ("Template Padrão") no **mesmo diálogo** de importação dos portais. Ela servirá para preencher automaticamente os campos que não são trazidos pelas planilhas dos portais, fazendo um merge com os dados do BLL/BRConectado antes de jogar pra tela.

## 🛠️ 1. Mapeamento de Domínios (Regras de Negócio)
* **Arquivo:** `complemento_csv_mapper.dart`
* **Domínios (String -> Int/String AUDESP):**
  * Tipo Orçamento: "NAO" (0), "GLOBAL" (1), "UNITARIO" (2), "DESCONTO" (3)
  * Situação: "ANDAMENTO" (1), "HOMOLOGADO" (2), "DESERTO" (4), "FRACASSADO" (5), "ANULADO" (3), "REVOGADO" (3), "CANCELADO" (3)
  * Tipo Valor: "MOEDA" ou "MONETARIO" ("M"), "PERCENTUAL" ("P")
  * Tipo Proposta: "GLOBAL" (1), "UNITARIO" (2), "DESCONTO" (3)

## 🏗️ 2. Atualização do Modelo e Parsers
* **Modelo (`licitacao_item_csv_model.dart`):** Adicionar os campos (`tipoOrcamento`, `valorEstimado`, `dataOrcamento`, `dataSituacao`, `tipoValor`, `tipoProposta`) e atualizar o `copyWith`.
* **Parser (`complemento_csv_parser.dart`):** Criar parser que ignora linhas inúteis e retorna um `Map<int, LicitacaoItemCsvModel>` (onde a chave é o número do item).

## 🧩 3. Unificação na UI (`portal_import_dialog.dart`)
* **Ação UI:** Adicionar um campo extra de "File Picker" no início do diálogo: `Planilha de Itens (Opcional)`.
* **Ação UI:** Adicionar botão/ícone de "Baixar Template" ao lado desse novo campo para o usuário baixar o CSV padrão vazio (latin-1, para ser compatível com o excel).
* **Lógica de Merge no Submit:** 1. Chama o parser do portal escolhido (gerando `List<LicitacaoItemCsvModel> itensPortal`).
  2. Se o usuário anexou o complementar, chama o parser dele (gerando `Map`).
  3. Itera sobre `itensPortal` e faz o merge das propriedades baseadas no `numeroItem`.
  4. Devolve a lista final unificada pro `licitacao_form_page.dart`.

---

# Ajuste Global de ME/EPP em Lote

## 📌 Objetivo
Criar um botão na tela de formulário da licitação que abra um diálogo com a lista única de licitantes participantes. Permitir ao usuário corrigir o enquadramento ME/EPP via Checkbox e aplicar essa correção em **todos** os itens onde aquele licitante aparece.

## 🏗️ 1. Adição do Botão na UI Principal (`licitacao_form_page.dart`)
* **Local:** Ao lado do botão "Importar Portal" (na seção de Itens).
* **Botão:** `FilledButton.tonal` (ou `OutlinedButton`) com ícone e texto "Ajustar ME/EPP".
* **Regra de Habilitação:** O botão **só deve ficar habilitado** se a lista `_itens` não estiver vazia E se existir pelo menos um licitante cadastrado dentro de algum item.

## ⚙️ 2. Lógica de Extração de Dados (Unique Licitantes)
* Ao clicar no botão, o código deve varrer todos os `_itens` e construir um `Map<String, Map<String, dynamic>>` (usando `niPessoa` como chave para evitar duplicidade).
* Guardar o status atual de ME/EPP de cada CNPJ (considerando `1` como `ME`, `2` como `EPP`, e `3` como `NÃO`).

## 🧩 3. Diálogo de Ajuste (`ajuste_me_epp_dialog.dart`)
* **UI:** Um `ListView` simples. Cada linha mostra o `nomeRazaoSocial` e o CNPJ do licitante, seguido de uma forma de escolher entre  ME/EPP/NÃO.
* **Ação de Salvar:** Ao confirmar, o diálogo devolve o Map atualizado com o status de cada CNPJ.

## 🔄 4. O Efeito Cascata (Callback no Form)
* Ao receber o Map de CNPJs do diálogo, o `licitacao_form_page.dart` executa um `.map()` varrendo todos os itens e todos os licitantes.
* Se o CNPJ bater com um que teve o status alterado, atualiza o campo `declaracaoMEouEPP` no JSON (`1` se ME, `2` se EPP, `3` se NÃO).
* Dá um `setState()` na lista de itens para refletir na UI.