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

  /// Código PNCP situacaoCompraItemId:
  /// 1 = Em Andamento, 2 = Homologado, 3 = Anulado/Revogado/Cancelado,
  /// 4 = Deserto, 5 = Fracassado.
  final int situacaoCompraItemId;

  final List<LicitanteCsvModel> licitantes;

  const LicitacaoItemCsvModel({
    required this.numeroItem,
    required this.situacaoCompraItemId,
    required this.licitantes,
  });

  @override
  String toString() =>
      'LicitacaoItemCsvModel(item=$numeroItem, situacao=$situacaoCompraItemId, '
      'licitantes=${licitantes.length})';
}
