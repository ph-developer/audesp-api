/// Mapeamentos específicos do portal BLL para os domínios PNCP/AUDESP.
class BllMapper {
  BllMapper._();

  // ---------------------------------------------------------------------------
  // resultadoHabilitacao  (colunas "Posição" e "Classificado")
  // ---------------------------------------------------------------------------

  /// Calcula o resultadoHabilitacao AUDESP a partir da posição na classificação
  /// e dos flags "Classificado" e "Habilitado" exportados pelo BLL.
  ///
  /// Regras:
  /// - [classificado] != "SIM" → 4 (Desclassificado)
  /// - [habilitado] != "SIM"   → 7 (Inabilitado)
  /// - [posicao] == 1           → 1 (Classificado Vencedor)
  /// - demais casos             → 2 (Classificado)
  static int resultadoHabilitacao({
    required int posicao,
    required String classificado,
    required String habilitado,
  }) {
    if (classificado.trim().toUpperCase() != 'SIM') return 4;
    if (habilitado.trim().toUpperCase() != 'SIM') return 7;
    if (posicao == 1) return 1;
    return 2;
  }
}
