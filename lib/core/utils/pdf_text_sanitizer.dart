/// Utilitário para sanitizar e normalizar textos antes de renderizá-los em documentos PDF.
///
/// As fontes padrão do pacote `pdf` (baseadas na especificação Type 1 / WinAnsi, como Helvetica)
/// não possuem suporte nativo a caracteres tipográficos Unicode estendidos (como aspas curvas “ ”,
/// travessões – —, reticências …, marcadores •, espaços especiais e símbolos matemáticos),
/// gerando warnings no log ("Unable to find a font to draw...") e renderizando
/// quadrados com 'X' no PDF final.
class PdfTextSanitizer {
  static const Map<String, String> _replacements = {
    // Aspas duplas tipográficas
    '“': '"',
    '”': '"',
    '„': '"',
    '‟': '"',
    '«': '"',
    '»': '"',

    // Aspas simples tipográficas / apóstrofos
    '‘': "'",
    '’': "'",
    '‚': "'",
    '‛': "'",
    '`': "'",
    '´': "'",

    // Traços, hífens e travessões
    '–': '-', // en dash (U+2013)
    '—': '-', // em dash (U+2014)
    '―': '-', // horizontal bar (U+2015)
    '‒': '-', // figure dash (U+2012)
    '−': '-', // minus sign (U+2212)
    '‐': '-', // hyphen (U+2010)
    '‑': '-', // non-breaking hyphen (U+2011)

    // Reticências
    '…': '...',

    // Marcadores / Bullets
    '•': '-',
    '◦': '-',
    '▪': '-',
    '▫': '-',
    '‣': '-',
    '⁃': '-',

    // Símbolos matemáticos e frações comuns
    '×': 'x',
    '÷': '/',
    '±': '+/-',
    '≤': '<=',
    '≥': '>=',
    '≠': '!=',
    '½': '1/2',
    '¼': '1/4',
    '¾': '3/4',

    // Espaços especiais
    '\u00A0': ' ', // Non-breaking space
    '\u202F': ' ', // Narrow no-break space
    '\u2009': ' ', // Thin space
    '\u200A': ' ', // Hair space
    '\u2002': ' ', // En space
    '\u2003': ' ', // Em space
    '\u3000': ' ', // Ideographic space

    // Caracteres invisíveis / zero-width
    '\u200B': '', // Zero-width space
    '\u200C': '', // Zero-width non-joiner
    '\u200D': '', // Zero-width joiner
    '\uFEFF': '', // Zero-width no-break space / BOM

    // Símbolos comerciais
    '№': 'Nº',
    '™': '(TM)',
    '©': '(c)',
    '®': '(R)',
  };

  static final RegExp _pattern = RegExp(
    _replacements.keys.map(RegExp.escape).join('|'),
  );

  /// Substitui caracteres tipográficos não suportados pelas fontes padrão do PDF
  /// pelos seus equivalentes seguros em ASCII/Latin-1.
  static String sanitize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(_pattern, (match) {
      return _replacements[match.group(0)] ?? match.group(0)!;
    });
  }
}

/// Extensão conveniente em [String] para sanitização direta de strings para PDF.
extension PdfTextSanitizerExtension on String {
  String toPdfSafe() => PdfTextSanitizer.sanitize(this);
}
