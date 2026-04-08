/// Mapeamentos específicos do portal BLL para os domínios PNCP/AUDESP.
class BllMapper {
  BllMapper._();

  // ---------------------------------------------------------------------------
  // situacaoCompraItemId  (coluna "Status" do Relatorio de vencedores.csv)
  // ---------------------------------------------------------------------------

  /// Converte o status textual do item no BLL para o código PNCP.
  ///
  /// Valores conhecidos:
  /// - "HOMOLOGADO"          → 2
  /// - "ANULADO" / "REVOGADO" / "CANCELADO" → 3
  /// - "DESERTO"             → 4
  /// - "FRACASSADO"          → 5
  /// - demais                → 1 (Em Andamento)
  static int situacaoCompraItemId(String status) {
    switch (status.trim().toUpperCase()) {
      case 'HOMOLOGADO':
        return 2;
      case 'ANULADO':
      case 'REVOGADO':
      case 'CANCELADO':
        return 3;
      case 'DESERTO':
        return 4;
      case 'FRACASSADO':
        return 5;
      default:
        return 1;
    }
  }

  // ---------------------------------------------------------------------------
  // resultadoHabilitacao  (colunas "Posição" e "Classificado")
  // ---------------------------------------------------------------------------

  /// Calcula o resultadoHabilitacao AUDESP a partir da posição na classificação
  /// e do flag "Classificado" exportado pelo BLL.
  ///
  /// Regras:
  /// - [posicao] == 1              → 1 (Classificado Vencedor)
  /// - [posicao] > 1 e [classificado] == "SIM" → 2 (Classificado)
  /// - [classificado] == "NÃO"    → 4 (Desclassificado)
  static int resultadoHabilitacao({
    required int posicao,
    required String classificado,
  }) {
    if (posicao == 1) return 1;
    if (classificado.trim().toUpperCase() == 'SIM') return 2;
    return 4;
  }
}
