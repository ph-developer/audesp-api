/// Mapeamentos de domínio para a planilha de itens do Edital.
///
/// Converte os textos presentes nas colunas do CSV para os códigos
/// numéricos esperados pelo AUDESP.
class EditalComplementoCsvMapper {
  EditalComplementoCsvMapper._();

  // ---------------------------------------------------------------------------
  // materialOuServico
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `MaterialOuServico` para "M" ou "S".
  ///
  /// - "M" / "MATERIAL"   → "M"
  /// - "S" / "SERVICO" / "SERVIÇO" / "SERVIÇO" → "S"
  /// - demais             → null (campo ignorado)
  static String? materialOuServico(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'M':
      case 'MATERIAL':
        return 'M';
      case 'S':
      case 'SERVICO':
      case 'SERVIÇO':
        return 'S';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // criterioJulgamentoId
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `CriterioJulgamento` para o código AUDESP.
  ///
  /// Aceita tanto o texto legível quanto o valor numérico diretamente.
  ///
  /// | Texto             | Código |
  /// |---|---|
  /// | MENOR_PRECO       | 1      |
  /// | MAIOR_DESCONTO    | 2      |
  /// | TECNICA_PRECO     | 4      |
  /// | MAIOR_LANCE       | 5      |
  /// | MAIOR_RETORNO     | 6      |
  /// | NAO_SE_APLICA     | 7      |
  /// | MELHOR_TECNICA    | 8      |
  /// | CONTEUDO_ARTISTICO| 9      |
  static int? criterioJulgamentoId(String raw) {
    final normalized = raw.trim().toUpperCase();
    // Tenta parse numérico direto primeiro.
    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;

    switch (normalized) {
      case 'MENOR_PRECO':
      case 'MENOR PRECO':
      case 'MENOR PREÇO':
        return 1;
      case 'MAIOR_DESCONTO':
      case 'MAIOR DESCONTO':
        return 2;
      case 'TECNICA_PRECO':
      case 'TÉCNICA E PREÇO':
      case 'TECNICA E PRECO':
        return 4;
      case 'MAIOR_LANCE':
      case 'MAIOR LANCE':
        return 5;
      case 'MAIOR_RETORNO':
      case 'MAIOR RETORNO ECONOMICO':
      case 'MAIOR RETORNO ECONÔMICO':
        return 6;
      case 'NAO_SE_APLICA':
      case 'NÃO SE APLICA':
      case 'NAO SE APLICA':
        return 7;
      case 'MELHOR_TECNICA':
      case 'MELHOR TECNICA':
      case 'MELHOR TÉCNICA':
        return 8;
      case 'CONTEUDO_ARTISTICO':
      case 'CONTEÚDO ARTÍSTICO':
      case 'CONTEUDO ARTISTICO':
        return 9;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // tipoBeneficioId
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `TipoBeneficio` para o código AUDESP.
  ///
  /// Aceita tanto o texto legível quanto o valor numérico diretamente.
  ///
  /// | Texto                    | Código |
  /// |---|---|
  /// | EXCLUSIVO_ME_EPP         | 1      |
  /// | SUBCONTRATACAO_ME_EPP    | 2      |
  /// | COTA_RESERVADA_ME_EPP    | 3      |
  /// | SEM_BENEFICIO            | 4      |
  /// | NAO_SE_APLICA            | 5      |
  static int? tipoBeneficioId(String raw) {
    final normalized = raw.trim().toUpperCase();
    // Tenta parse numérico direto primeiro.
    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;

    switch (normalized) {
      case 'EXCLUSIVO_ME_EPP':
      case 'EXCLUSIVO ME EPP':
        return 1;
      case 'SUBCONTRATACAO_ME_EPP':
      case 'SUBCONTRATAÇÃO ME EPP':
      case 'SUBCONTRATACAO ME EPP':
        return 2;
      case 'COTA_RESERVADA_ME_EPP':
      case 'COTA RESERVADA ME EPP':
        return 3;
      case 'SEM_BENEFICIO':
      case 'SEM BENEFICIO':
      case 'SEM BENEFÍCIO':
        return 4;
      case 'NAO_SE_APLICA':
      case 'NÃO SE APLICA':
      case 'NAO SE APLICA':
        return 5;
      default:
        return null;
    }
  }
}
