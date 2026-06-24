/// Definição de uma coluna do template de importação.
class TemplateColumn {
  /// Nome interno do campo (usado pelos parsers).
  final String name;

  /// Título exibido no cabeçalho da planilha (humanizado).
  final String title;

  /// Descrição/instrução exibida na linha 2.
  final String description;

  /// Valor de exemplo (linha 3).
  final String example;

  const TemplateColumn({
    required this.name,
    required this.title,
    required this.description,
    required this.example,
  });
}

/// Definição completa de um template de planilha.
class TemplateDefinition {
  final String sheetName;
  final List<TemplateColumn> columns;

  const TemplateDefinition({required this.sheetName, required this.columns});

  int get columnCount => columns.length;

  List<String> get headerRow => columns.map((c) => c.title).toList();

  List<String> get descriptionRow => columns.map((c) => c.description).toList();

  List<String> get exampleRow => columns.map((c) => c.example).toList();

  /// Mapa de título humanizado (lowercase) → nome interno (lowercase) para
  /// permitir que os parsers encontrem colunas independentemente do texto
  /// exibido no cabeçalho.
  Map<String, String> get headerAliases {
    final result = <String, String>{};
    for (final col in columns) {
      final lowerTitle = col.title.trim().toLowerCase();
      final lowerName = col.name.toLowerCase();
      if (lowerTitle != lowerName) {
        result[lowerTitle] = lowerName;
      }
    }
    return result;
  }
}

/// Template único utilizado tanto pelo Edital quanto pela Licitação.
///
/// Contém todas as colunas dos dois módulos. Colunas específicas de cada um
/// (ex: ItemCategoria do Edital) são simplesmente ignoradas pelo parser
/// do módulo que não as utiliza.
const templateItens = TemplateDefinition(
  sheetName: 'Itens',
  columns: [
    TemplateColumn(
      name: 'NumeroItem',
      title: 'Número do Item',
      description: 'Número sequencial do item. Deve ser um inteiro único.',
      example: '1',
    ),
    TemplateColumn(
      name: 'Descricao',
      title: 'Descrição',
      description: 'Descrição detalhada do item.',
      example: 'Cadeira ergonômica',
    ),
    TemplateColumn(
      name: 'MaterialOuServico',
      title: 'Material ou Serviço',
      description: 'M (Material) ou S (Serviço).',
      example: 'M',
    ),
    TemplateColumn(
      name: 'Quantidade',
      title: 'Quantidade',
      description:
          'Quantidade do item. Use vírgula como decimal. Ex: 10 ou 1,5',
      example: '10',
    ),
    TemplateColumn(
      name: 'UnidadeMedida',
      title: 'Unidade de Medida',
      description: 'Unidade de medida. Ex: UN, KG, M, L, SERV',
      example: 'UN',
    ),
    TemplateColumn(
      name: 'ValorUnitarioMenor',
      title: 'Valor Unitário (Menor)',
      description:
          'Menor valor orçado (Edital). Use vírgula como decimal. Ex: 800,00',
      example: '800,00',
    ),
    TemplateColumn(
      name: 'CriterioJulgamento',
      title: 'Critério de Julgamento',
      description:
          'MENOR_PRECO, MAIOR_DESCONTO, TECNICA_PRECO, MAIOR_LANCE, '
          'MAIOR_RETORNO, NAO_SE_APLICA, MELHOR_TECNICA, CONTEUDO_ARTISTICO',
      example: 'MENOR_PRECO',
    ),
    TemplateColumn(
      name: 'TipoBeneficio',
      title: 'Tipo de Benefício',
      description:
          'EXCLUSIVO_ME_EPP, SUBCONTRATACAO_ME_EPP, COTA_RESERVADA_ME_EPP, '
          'SEM_BENEFICIO, NAO_SE_APLICA',
      example: 'SEM_BENEFICIO',
    ),
    TemplateColumn(
      name: 'ItemCategoria',
      title: 'Categoria do Item',
      description: 'BENS_IMOVEIS, BENS_MOVEIS, NAO_SE_APLICA',
      example: 'BENS_MOVEIS',
    ),
    TemplateColumn(
      name: 'TipoOrcamento',
      title: 'Tipo de Orçamento',
      description: 'NAO, GLOBAL, UNITARIO, DESCONTO',
      example: 'GLOBAL',
    ),
    TemplateColumn(
      name: 'ValorEstimadoMedia',
      title: 'Valor Estimado (Média)',
      description:
          'Média dos valores orçados (Licitação). Use vírgula como decimal.',
      example: '850,00',
    ),
    TemplateColumn(
      name: 'DataOrcamento',
      title: 'Data do Orçamento',
      description: 'Data do orçamento. Formato DD/MM/AAAA.',
      example: '01/01/2025',
    ),
    TemplateColumn(
      name: 'SituacaoCompraItem',
      title: 'Situação do Item',
      description:
          'ANDAMENTO, HOMOLOGADO, DESERTO, FRACASSADO, ANULADO, '
          'REVOGADO, CANCELADO',
      example: 'HOMOLOGADO',
    ),
    TemplateColumn(
      name: 'DataSituacao',
      title: 'Data da Situação',
      description: 'Data da situação. Formato DD/MM/AAAA.',
      example: '15/01/2025',
    ),
    TemplateColumn(
      name: 'TipoValor',
      title: 'Tipo de Valor',
      description: 'MOEDA, PERCENTUAL',
      example: 'MOEDA',
    ),
    TemplateColumn(
      name: 'TipoProposta',
      title: 'Tipo de Proposta',
      description: 'GLOBAL, UNITARIO, DESCONTO',
      example: 'GLOBAL',
    ),
  ],
);
