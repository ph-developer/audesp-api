# Plano: estimativa por lote

## Objetivo

Alterar a experiencia da feature de estimativa para que o modo "Por Lote" organize a tabela por cabecalhos de lote, sem repetir uma coluna de lote em cada item, mantendo edicao, reordenacao e regras de ME/EPP coerentes com o tipo de estimativa selecionado.

## Estado atual observado

- `estimativa_form_page.dart` guarda conteudo em duas listas separadas:
  - `_itens`, usada quando `_tipoEstimativa == 'item'`.
  - `_lotes`, usada quando `_tipoEstimativa == 'lote'`, com itens dentro de cada lote.
- A troca de tipo atualmente confirma e apaga todos os itens/lotes.
- A tabela usa `DataTable`; no modo lote, cada linha de item recebe uma coluna "Lote".
- `showEstimativaLoteDialog` edita dados do lote e tambem gerencia os itens internos.
- `showEstimativaItemDialog` ja possui campos de material/servico e categoria no modelo, mas hoje esses campos so aparecem quando `estimativaTipo == 'item'`.
- `showEstimativaExclusividadeDialog` ja alterna entre itens e lotes conforme o tipo de estimativa.
- Os dados de item/lote sao persistidos em `documento_json`, entao nao deve ser necessaria migracao de schema para estes ajustes.

## Regras de negocio desejadas

1. No modo "Por Lote", remover a coluna visual de lote e exibir cada lote como um cabecalho/separador acima de seus itens.
2. O cabecalho do lote deve ser clicavel para editar apenas os campos do lote.
3. O dialog de lote nao deve editar, incluir, excluir ou reordenar itens.
4. O botao de incluir item novo no lote deve ficar no canto direito do cabecalho do lote.
5. No modo "Por Item", o botao principal continua incluindo item.
6. No modo "Por Lote", o botao principal deve incluir lote, nao item.
7. A troca de "Por Item" para "Por Lote" deve:
   - sempre pedir confirmacao quando houver itens;
   - explicar que sera criado um lote unico;
   - criar `LOTE 01` com quantidade `1`, unidade `LOTE`, material/servico e categoria iguais aos do primeiro item;
   - mover todos os itens existentes para esse lote, preservando os itens e seus orcamentos.
8. A troca de "Por Lote" para "Por Item" deve:
   - sempre pedir confirmacao quando houver lotes ou itens em lotes;
   - explicar que os itens ficarao avulsos;
   - achatar os itens na ordem atual dos lotes e, dentro deles, na ordem atual dos itens;
   - renumerar os itens sequencialmente.
9. Tanto lote quanto item devem sempre expor material/servico e categoria, independente do tipo da estimativa.
10. Deve ser possivel reordenar itens avulsos.
11. Deve ser possivel reordenar itens dentro de um lote.
12. Deve ser possivel reordenar lotes.
13. Por enquanto, nao implementar mover item de um lote para outro.
14. A selecao ME/EPP deve operar sobre itens quando a estimativa for por item e sobre lotes quando a estimativa for por lote.

## Decisoes de implementacao

### Conversao de tipo

Criar helpers em `estimativa_form_page.dart`:

- `_confirmTipoEstimativaChange(String novoTipo)`
- `_convertItensToSingleLote()`
- `_convertLotesToItens()`
- `_renumerarItens(List<EstimativaItem> itens)`
- `_renumerarLotes(List<EstimativaLote> lotes)`

Fluxo proposto:

- No `onChanged` do dropdown de tipo, chamar `_confirmTipoEstimativaChange`.
- Se nao houver conteudo, apenas trocar o tipo.
- Se `item -> lote`, confirmar com texto explicito e criar lote unico:
  - `numero: 1`
  - `descricao: 'LOTE 01'`
  - `quantidade: 1`
  - `unidade: 'LOTE'`
  - `materialOuServico: _itens.first.materialOuServico`
  - `itemCategoriaId: _itens.first.itemCategoriaId`
  - `itens: _renumerarItens(_itens)`
- Se `lote -> item`, confirmar com texto explicito, achatar:
  - `_lotes.expand((lote) => lote.itens)`
  - aplicar renumeracao sequencial
  - limpar `_lotes`

### Tabela e cabecalhos de lote

`DataTable` nao encaixa bem em "cabecalhos entre linhas" com botoes e reordenacao. Substituir a renderizacao interna por uma estrutura propria mantendo o mesmo visual de grade:

- Um cabecalho comum com colunas:
  - Item
  - Descricao
  - Quantidade
  - Unidade
  - Fornecedores dinamicos
  - Valor Unitario
  - Valor Total
  - Acoes
- No modo item:
  - lista reordenavel de linhas de item avulso.
- No modo lote:
  - lista reordenavel de blocos de lote;
  - cada bloco tem um header clicavel com numero, descricao, material/servico, categoria, subtotal e acoes;
  - no canto direito do header, incluir botao "Incluir Item";
  - abaixo do header, lista reordenavel dos itens daquele lote.

Se a substituicao completa por widgets proprios ficar grande demais para uma primeira entrega, uma alternativa aceitavel e usar `Table`/`Column` dentro de um `SingleChildScrollView` horizontal, preservando as larguras constantes ja existentes.

### Reordenacao

Adicionar handlers em `estimativa_form_page.dart`:

- `_reorderItens(int oldIndex, int newIndex)` para `_itens`.
- `_reorderLotes(int oldIndex, int newIndex)` para `_lotes`.
- `_reorderLoteItens(int loteIndex, int oldIndex, int newIndex)` para itens dentro de lote.

Regras:

- Ajustar `newIndex` quando vier de `ReorderableListView`.
- Apos reordenar itens avulsos ou itens dentro de lote, renumerar os itens daquele escopo.
- Apos reordenar lotes, renumerar os lotes.
- Usar keys estaveis o suficiente para evitar colisao durante reorder. Como os modelos nao possuem id persistente para item/lote, considerar keys compostas por indice/numero/descricao ou introduzir `ObjectKey(item)` nos widgets de lista.

### Dialog de lote

Alterar `estimativa_lote_dialog.dart` para editar somente:

- numero, somente leitura;
- descricao;
- quantidade;
- unidade;
- material/servico;
- categoria;
- exclusividade ME/EPP, se for decidido expor no proprio dialog;
- resumo de valor do lote, se recebido externamente ou mantido sem depender de edicao interna dos itens.

Remover do dialog:

- lista de itens;
- botao "Adicionar Item";
- edicao/exclusao/reordenacao de itens.

Como o valor do lote depende dos itens, ha duas opcoes:

- manter `lote.itens` ao salvar, sem alterar a lista;
- ou passar um lote completo para o dialog e permitir que ele retorne `copyWith` preservando `itens`.

Preferencia: preservar `itens` no proprio `EstimativaLote` retornado para reduzir mudancas no chamador.

### Dialog de item

Alterar `estimativa_item_dialog.dart` para sempre exibir:

- material/servico;
- categoria do item.

Remover a condicao `if (widget.estimativaTipo == 'item')` desses campos. O parametro `estimativaTipo` pode continuar existindo se ainda for util para textos, mas nao deve ocultar campos obrigatorios.

### Acoes de item/lote

No modo item:

- botao do topo: "Incluir Item" -> `_addItem`.
- linha do item: editar, excluir, reordenar.

No modo lote:

- botao do topo: "Incluir Lote" -> `_addLote`.
- header do lote: clique abre `_editLote`.
- header do lote: botao "Incluir Item" -> novo helper `_addLoteItem(int loteIndex)`.
- linha do item dentro de lote: editar, excluir, reordenar dentro do lote.
- nao adicionar controles para mover entre lotes nesta etapa.

### ME/EPP

Manter a regra atual de `showEstimativaExclusividadeDialog`:

- `tipoEstimativa == 'item'`: checkboxes de itens.
- `tipoEstimativa == 'lote'`: checkboxes de lotes.

Revisar impacto das conversoes:

- `item -> lote`: o lote unico deve receber `exclusivoMeEpp: _itens.any((i) => i.exclusivoMeEpp)` somente se isso fizer sentido para preservar uma reserva existente; caso contrario, iniciar `false`. Decisao recomendada: preservar como `true` se qualquer item estava reservado, para evitar perda silenciosa.
- `lote -> item`: itens resultantes devem receber `exclusivoMeEpp: lote.exclusivoMeEpp || item.exclusivoMeEpp`, para preservar reserva existente quando o lote era reservado.

## Arquivos previstos

- `lib/features/estimativa/pages/estimativa_form_page.dart`
  - troca de tipo;
  - nova renderizacao da secao de itens/lotes;
  - helpers de conversao, inclusao e reordenacao;
  - remocao da coluna visual de lote.
- `lib/features/estimativa/widgets/estimativa_lote_dialog.dart`
  - simplificar dialog para dados do lote apenas.
- `lib/features/estimativa/widgets/estimativa_item_dialog.dart`
  - exibir material/servico e categoria em todos os contextos.
- `lib/features/estimativa/widgets/estimativa_exclusividade_dialog.dart`
  - possivelmente apenas pequenos ajustes de label, se necessario.
- `lib/features/estimativa/services/estimativa_pdf_service.dart`
  - revisar se a nova numeracao e dados de material/categoria exigem exibicao adicional no PDF. Nao e obrigatorio para a primeira etapa, mas deve ser conferido.

## Sequencia sugerida

1. Implementar helpers puros de renumeracao e conversao no form.
2. Trocar o `onChanged` do tipo de estimativa para usar confirmacoes e conversoes sem apagar dados.
3. Ajustar `estimativa_item_dialog.dart` para sempre mostrar material/servico e categoria.
4. Simplificar `estimativa_lote_dialog.dart` para nao gerenciar itens.
5. Criar helpers de adicionar/editar item dentro de lote no form.
6. Substituir a tabela atual por uma renderizacao com header comum, blocos de lote e reorder.
7. Ajustar acoes do topo: item no modo item, lote no modo lote.
8. Revisar ME/EPP nas conversoes e no dialog de exclusividade.
9. Rodar `dart format` nos arquivos alterados.
10. Rodar `flutter analyze`.
11. Rodar `flutter test`.

## Criterios de aceite

- Trocar de item para lote com itens existentes nao perde dados e cria exatamente um lote `LOTE 01`.
- Trocar de lote para item nao perde itens/orcamentos e renumera pela ordem dos lotes e dos itens.
- O modo lote nao mostra coluna "Lote" por linha; os lotes aparecem como cabecalhos.
- O cabecalho do lote abre edicao de lote e nao edita itens.
- O botao de incluir item dentro do lote fica no lado direito do header do lote.
- O botao principal da secao muda para "Incluir Lote" quando o tipo for lote.
- Itens avulsos podem ser reordenados e renumerados.
- Itens dentro do lote podem ser reordenados e renumerados.
- Lotes podem ser reordenados e renumerados.
- Material/servico e categoria aparecem para itens mesmo dentro de lote.
- Material/servico e categoria aparecem para lotes.
- A selecao ME/EPP atua sobre itens no modo item e sobre lotes no modo lote.
- `flutter analyze` nao aponta novos erros.
- `flutter test` continua passando.

## Pontos de atencao

- O codigo atual tem textos com caracteres acentuados corrompidos em alguns arquivos. Ao editar, evitar churn amplo de encoding e tocar apenas nos trechos necessarios.
- Como item e lote nao possuem ids estaveis, reordenacao com keys baseadas apenas em `numero` pode gerar instabilidade durante renumeracao. Testar a UI manualmente apos implementar.
- A importacao de orcamento via IA usa ids baseados em numero de lote e item. Como a reordenacao renumera, isso e aceitavel, mas a importacao deve sempre usar o estado numerado atual.
- A remocao da lista de itens do dialog de lote muda o fluxo atual: qualquer logica de item que estava encapsulada no dialog precisa migrar para o form.
- Ao converter ME/EPP entre tipos, preservar marcacoes existentes sempre que possivel para evitar perda silenciosa de decisao do usuario.
