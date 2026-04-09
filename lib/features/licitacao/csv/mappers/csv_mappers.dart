/// Funções de mapeamento compartilhadas entre os parsers de portais.
class CsvMappers {
  CsvMappers._();

  // ---------------------------------------------------------------------------
  // NI / TipoPessoa
  // ---------------------------------------------------------------------------

  /// Remove máscara de documento (pontos, barras e traços).
  static String cleanNiPessoa(String raw) =>
      raw.replaceAll(RegExp(r'[.\-/]'), '').trim();

  /// Determina o [tipoPessoaId] a partir do NI já limpo (sem máscara).
  ///
  /// - 14 dígitos → 'PJ'  (CNPJ)
  /// - 11 dígitos → 'PF'  (CPF)
  /// - demais     → 'PE'  (estrangeiro)
  static String tipoPessoaFromCleanNi(String cleanNi) {
    if (cleanNi.length == 14) return 'PJ';
    if (cleanNi.length == 11) return 'PF';
    return 'PE';
  }

  // ---------------------------------------------------------------------------
  // ME / EPP
  // ---------------------------------------------------------------------------

  /// Converte a coluna `ME` ou `ME/EPP` (texto) para o código AUDESP.
  ///
  /// - "NÃO" / "NAO" / "" → 3 (Não)
  /// - "SIM"              → 1 (ME)
  ///
  /// **Atenção**: o valor `1` é provisório — o portal não distingue ME de EPP.
  static int declaracaoMEouEPP(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'SIM') return 1;
    return 3;
  }

  // ---------------------------------------------------------------------------
  // Valores monetários no formato brasileiro
  // ---------------------------------------------------------------------------

  /// Converte uma string no formato monetário BR (ex: "19.600,00" ou "19600,0000")
  /// para [double].
  ///
  /// Lança [FormatException] se a string não for um número válido após limpeza.
  static double parseBrCurrency(String raw) {
    // Remove separadores de milhar (ponto) e converte vírgula decimal em ponto.
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.parse(normalized);
  }
}
