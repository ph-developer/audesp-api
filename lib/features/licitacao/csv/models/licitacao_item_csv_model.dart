/// Representa um licitante extraído de um arquivo CSV de portal de compras.
class LicitanteCsvModel {
  /// Número de identificação limpo (sem pontos, traços e barras).
  final String niPessoa;

  /// 'PJ', 'PF' ou 'PE', derivado do comprimento de [niPessoa].
  final String tipoPessoaId;

  final String nomeRazaoSocial;

  /// 1 = ME, 2 = EPP, 3 = Não.
  ///
  /// Quando extraído como "SIM" do CSV, é mapeado para `1` (ME).
  // TODO: a UI deve permitir que o usuário corrija para 2 (EPP) caso necessário.
  final int declaracaoMEouEPP;

  final double valorProposta;

  /// Código AUDESP resultadoHabilitacao:
  /// 1 = Classificado Vencedor, 2 = Classificado,
  /// 3 = Habilitado, 4 = Desclassificado, 5 = Desistiu, 6 = Proposta não analisada, 7 = Inabilitado.
  final int resultadoHabilitacao;

  const LicitanteCsvModel({
    required this.niPessoa,
    required this.tipoPessoaId,
    required this.nomeRazaoSocial,
    required this.declaracaoMEouEPP,
    required this.valorProposta,
    required this.resultadoHabilitacao,
  });

  @override
  String toString() =>
      'LicitanteCsvModel(ni=$niPessoa, nome=$nomeRazaoSocial, '
      'resultado=$resultadoHabilitacao, valor=$valorProposta)';
}

/// Representa um item de licitação com seus licitantes, extraído de CSV.
class LicitacaoItemCsvModel {
  final int numeroItem;

  final List<LicitanteCsvModel> licitantes;

  // Campos opcionais preenchidos pela planilha complementar (Template Padrão).

  /// Código AUDESP tipoOrcamento: 0 = Não, 1 = Global, 2 = Unitário, 3 = Desconto.
  final int? tipoOrcamento;

  /// Valor estimado do item (R$).
  final double? valorEstimado;

  /// Data do orçamento no formato yyyy-MM-dd.
  final String? dataOrcamento;

  /// Código PNCP situacaoCompraItemId:
  /// 1 = Em Andamento, 2 = Homologado, 3 = Anulado/Revogado/Cancelado,
  /// 4 = Deserto, 5 = Fracassado.
  final int? situacaoCompraItemId;

  /// Data da situação do item no formato yyyy-MM-dd.
  final String? dataSituacao;

  /// Tipo de valor: "M" = Monetário, "P" = Percentual.
  final String? tipoValor;

  /// Código AUDESP tipoProposta: 1 = Global, 2 = Unitário, 3 = Desconto.
  final int? tipoProposta;

  const LicitacaoItemCsvModel({
    required this.numeroItem,
    required this.licitantes,
    this.tipoOrcamento,
    this.valorEstimado,
    this.dataOrcamento,
    this.situacaoCompraItemId,
    this.dataSituacao,
    this.tipoValor,
    this.tipoProposta,
  });

  LicitacaoItemCsvModel copyWith({
    int? numeroItem,
    List<LicitanteCsvModel>? licitantes,
    int? tipoOrcamento,
    double? valorEstimado,
    String? dataOrcamento,
    int? situacaoCompraItemId,
    String? dataSituacao,
    String? tipoValor,
    int? tipoProposta,
  }) {
    return LicitacaoItemCsvModel(
      numeroItem: numeroItem ?? this.numeroItem,
      licitantes: licitantes ?? this.licitantes,
      tipoOrcamento: tipoOrcamento ?? this.tipoOrcamento,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      dataOrcamento: dataOrcamento ?? this.dataOrcamento,
      situacaoCompraItemId: situacaoCompraItemId ?? this.situacaoCompraItemId,
      dataSituacao: dataSituacao ?? this.dataSituacao,
      tipoValor: tipoValor ?? this.tipoValor,
      tipoProposta: tipoProposta ?? this.tipoProposta,
    );
  }

  @override
  String toString() =>
      'LicitacaoItemCsvModel(item=$numeroItem, situacao=$situacaoCompraItemId, '
      'licitantes=${licitantes.length})';
}
