/// Mapeamentos de domínio para a planilha complementar (Template Padrão).
///
/// Converte os textos presentes nas colunas do CSV para os códigos
/// numéricos/string esperados pelo AUDESP.
class ComplementoCsvMapper {
  ComplementoCsvMapper._();

  // ---------------------------------------------------------------------------
  // tipoOrcamento
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `TipoOrcamento` para o código AUDESP.
  ///
  /// - "NAO" / "NÃO" / ""  → 0
  /// - "GLOBAL"             → 1
  /// - "UNITARIO"           → 2
  /// - "DESCONTO"           → 3
  /// - demais               → null (campo ignorado)
  static int? tipoOrcamento(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'NAO':
      case 'NÃO':
      case '':
        return 0;
      case 'GLOBAL':
        return 1;
      case 'UNITARIO':
      case 'UNITÁRIO':
        return 2;
      case 'DESCONTO':
        return 3;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // tipoValor
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `TipoValor` para o código AUDESP.
  ///
  /// - "MOEDA" / "MONETARIO"  → "M"
  /// - "PERCENTUAL"           → "P"
  /// - demais                 → null (campo ignorado)
  static String? tipoValor(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'MOEDA':
      case 'MONETARIO':
      case 'MONETÁRIO':
        return 'M';
      case 'PERCENTUAL':
        return 'P';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // tipoProposta
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `TipoProposta` para o código AUDESP.
  ///
  /// - "GLOBAL"    → 1
  /// - "UNITARIO"  → 2
  /// - "DESCONTO"  → 3
  /// - demais      → null (campo ignorado)
  static int? tipoProposta(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'GLOBAL':
        return 1;
      case 'UNITARIO':
      case 'UNITÁRIO':
        return 2;
      case 'DESCONTO':
        return 3;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // situacaoCompraItemId
  // ---------------------------------------------------------------------------

  /// Converte o texto da coluna `SituacaoCompraItem` para o código AUDESP.
  ///
  /// - "ANDAMENTO"   → 1
  /// - "HOMOLOGADO"  → 2
  /// - "CANCELADO"   → 3
  /// - "ANULADO"     → 3
  /// - "REVOGADO"    → 3
  /// - "DESERTO"     → 4
  /// - "FRACASSADO"  → 5
  /// - demais        → null (campo ignorado)
  static int? situacaoCompraItemId(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'ANDAMENTO':
        return 1;
      case 'HOMOLOGADO':
        return 2;
      case 'CANCELADO':
      case 'ANULADO':
      case 'REVOGADO':
        return 3;
      case 'DESERTO':
        return 4;
      case 'FRACASSADO':
        return 5;
      default:
        return null;
    }
  }
}
