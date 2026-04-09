/// Mapeamentos específicos do portal BLL para os domínios PNCP/AUDESP.
class BllMapper {
  BllMapper._();

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
