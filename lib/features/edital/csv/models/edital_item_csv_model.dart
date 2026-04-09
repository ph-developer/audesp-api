/// Representa um item de edital extraído de um arquivo CSV.
///
/// Os campos obrigatórios correspondem às colunas mínimas exigidas pelo parser.
/// Os campos opcionais são preenchidos quando as colunas correspondentes
/// estão presentes na planilha (ex: [valorUnitarioEstimado], [criterioJulgamentoId]).
class EditalItemCsvModel {
  final int numeroItem;
  final String descricao;

  /// "M" = Material, "S" = Serviço.
  final String materialOuServico;

  final double quantidade;
  final String unidadeMedida;

  /// Menor valor unitário orçado (teto de referência).
  /// Mapeado a partir da coluna `ValorUnitarioMenor`.
  /// Nulo quando a coluna estiver ausente ou em branco.
  final double? valorUnitarioEstimado;

  /// Calculado como [quantidade] × [valorUnitarioEstimado].
  /// Nulo quando [valorUnitarioEstimado] for nulo.
  final double? valorTotal;

  /// Código AUDESP criterioJulgamentoId.
  /// Mapeado a partir da coluna `CriterioJulgamento`.
  final int? criterioJulgamentoId;

  /// Código AUDESP tipoBeneficioId.
  /// Mapeado a partir da coluna `TipoBeneficio`.
  final int? tipoBeneficioId;

  const EditalItemCsvModel({
    required this.numeroItem,
    required this.descricao,
    required this.materialOuServico,
    required this.quantidade,
    required this.unidadeMedida,
    this.valorUnitarioEstimado,
    this.valorTotal,
    this.criterioJulgamentoId,
    this.tipoBeneficioId,
  });

  @override
  String toString() =>
      'EditalItemCsvModel(#$numeroItem, $descricao, '
      'qtd=$quantidade $unidadeMedida, valor=$valorUnitarioEstimado)';
}
