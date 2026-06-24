String normalizeSearchText(String value) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'Á': 'a',
    'À': 'a',
    'Â': 'a',
    'Ã': 'a',
    'Ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'É': 'e',
    'È': 'e',
    'Ê': 'e',
    'Ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'Í': 'i',
    'Ì': 'i',
    'Î': 'i',
    'Ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'Ó': 'o',
    'Ò': 'o',
    'Ô': 'o',
    'Õ': 'o',
    'Ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'Ú': 'u',
    'Ù': 'u',
    'Û': 'u',
    'Ü': 'u',
    'ç': 'c',
    'Ç': 'c',
  };

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char.toLowerCase());
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool matchesLikeSearch(String value, String query) {
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) return true;

  final normalizedValue = normalizeSearchText(value);
  final terms = normalizedQuery
      .split(RegExp(r'[%\s]+'))
      .where((term) => term.isNotEmpty);

  var start = 0;
  for (final term in terms) {
    final index = normalizedValue.indexOf(term, start);
    if (index == -1) return false;
    start = index + term.length;
  }
  return true;
}
