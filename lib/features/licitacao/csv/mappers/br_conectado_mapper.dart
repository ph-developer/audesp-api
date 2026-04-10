/// Mapeamentos específicos do portal BRConectado para os domínios PNCP/AUDESP.
class BrConectadoMapper {
  BrConectadoMapper._();

  // ---------------------------------------------------------------------------
  // resultadoHabilitacao  (coluna "Situação" do relatclassificacao.csv ou propostas.csv)
  // ---------------------------------------------------------------------------

  /// Converte o status da proposta/classificação para o código AUDESP.
  ///
  /// Valores conhecidos:
  /// - "ADJUDICADO" / "ARREMATANTE"      → 1 (Classificado Vencedor)
  /// - "CLASSIFICADA/HABILITADA" (ou similar contendo "CLASSIFICA" e/ou "HABILITA") → 2 (Classificado)
  /// - "DESCLASSIFICADO" / "DESCLASSIFICADA" → 4 (Desclassificado)
  /// - demais                            → 6 (Proposta não Analisada)
  static int resultadoHabilitacao(String situacao) {
    final upper = situacao.trim().toUpperCase();
    if (upper == 'ADJUDICADO' || upper == 'ARREMATANTE') return 1;
    if (upper == 'DESCLASSIFICADO' || upper == 'DESCLASSIFICADA') return 4;
    if (upper.contains('CLASSIFICA') || upper.contains('HABILITA')) return 2;
    return 6;
  }

  // ---------------------------------------------------------------------------
  // numeroItem  (coluna "Lote/Item" ou "Número")
  // ---------------------------------------------------------------------------

  /// Converte a string do item (ex: "001") para inteiro.
  ///
  /// Lança [FormatException] se o valor não for numérico.
  static int parseNumeroItem(String raw) => int.parse(raw.trim());
}
