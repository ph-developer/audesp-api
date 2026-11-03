import 'dart:convert';

/// Páginas da documentação oficial do AUDESP acompanhadas pelo sistema.
abstract final class DocumentacaoFontes {
  static final paginaTce = Uri.parse(
    'https://www.tce.sp.gov.br/audesp/documentacao/'
    'reformulacao-fase-iv-jsonschemas-e-documentacao-xlsx',
  );

  /// Página do Swagger; o conteúdo dela é só a casca do Swagger UI.
  static final paginaApi = Uri.parse('https://audesp.tce.sp.gov.br/api');

  /// Especificação carregada pela página do Swagger (swagger-initializer.js).
  static final especificacaoApi = Uri.parse(
    'https://audesp.tce.sp.gov.br/api/audesp.yaml',
  );
}

/// Período do dia em que a documentação é verificada: um de 0h a 12h e
/// outro de 12h a 0h, no horário local.
String periodoVerificacao(DateTime agora) {
  final dia =
      '${agora.year.toString().padLeft(4, '0')}-'
      '${agora.month.toString().padLeft(2, '0')}-'
      '${agora.day.toString().padLeft(2, '0')}';
  return '$dia-${agora.hour < 12 ? 'manha' : 'tarde'}';
}

class PaginaTceExtraida {
  /// Texto da seção da documentação, sem tags e com espaços normalizados.
  final String texto;

  /// Anexos da seção, já resolvidos contra o endereço da página.
  final List<Uri> anexos;

  const PaginaTceExtraida({required this.texto, required this.anexos});
}

/// Extrai do HTML só a seção `<article>` da documentação. Menu, rodapé e
/// cabeçalhos mudam sem relação com a documentação e gerariam alertas falsos.
PaginaTceExtraida extrairPaginaTce(String html, {required Uri pagina}) {
  final inicio = html.indexOf('<article');
  final fim = inicio < 0 ? -1 : html.indexOf('</article>', inicio);
  if (fim < 0) {
    throw const FormatException(
      'Seção da documentação não encontrada na página do TCE.',
    );
  }
  final artigo = html.substring(inicio, fim);

  final anexos = <Uri>[];
  final link = RegExp(r'''<a\s[^>]*href\s*=\s*["']([^"']+)["']''');
  for (final m in link.allMatches(artigo)) {
    final href = m.group(1)!.replaceAll('&amp;', '&');
    if (!href.contains('/sites/default/files/')) continue;
    final uri = pagina.resolve(href);
    if (!anexos.contains(uri)) anexos.add(uri);
  }

  final texto = artigo
      .replaceAll(RegExp(r'<(script|style)\b[^>]*>.*?</\1>', dotAll: true), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return PaginaTceExtraida(texto: texto, anexos: anexos);
}

/// Nome do anexo como aparece na página (último trecho do endereço).
String nomeAnexo(Uri uri) {
  final segmentos = uri.pathSegments.where((s) => s.isNotEmpty);
  return segmentos.isEmpty ? uri.toString() : segmentos.last;
}

/// Impressão digital da documentação: hashes SHA-256 do que interessa.
class DocumentacaoSnapshot {
  final String textoPagina;

  /// Nome do anexo → hash do arquivo.
  final Map<String, String> anexos;
  final String especificacaoApi;

  const DocumentacaoSnapshot({
    required this.textoPagina,
    required this.anexos,
    required this.especificacaoApi,
  });

  factory DocumentacaoSnapshot.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return DocumentacaoSnapshot(
      textoPagina: map['textoPagina'] as String,
      anexos: (map['anexos'] as Map<String, dynamic>).cast<String, String>(),
      especificacaoApi: map['especificacaoApi'] as String,
    );
  }

  String toJson() => jsonEncode({
    'textoPagina': textoPagina,
    'anexos': anexos,
    'especificacaoApi': especificacaoApi,
  });
}

/// Lê um snapshot salvo; valor ausente ou corrompido conta como ausente.
DocumentacaoSnapshot? lerSnapshot(String? json) {
  if (json == null || json.isEmpty) return null;
  try {
    return DocumentacaoSnapshot.fromJson(json);
  } catch (_) {
    return null;
  }
}

/// Descreve o que mudou de [referencia] (última conferida pelo TI) para
/// [atual]. Lista vazia quando nada mudou.
List<String> compararDocumentacao(
  DocumentacaoSnapshot referencia,
  DocumentacaoSnapshot atual,
) {
  final alteracoes = <String>[];
  if (referencia.textoPagina != atual.textoPagina) {
    alteracoes.add('Texto da página de documentação do TCE alterado');
  }
  for (final nome in atual.anexos.keys) {
    final anterior = referencia.anexos[nome];
    if (anterior == null) {
      alteracoes.add('Novo anexo: $nome');
    } else if (anterior != atual.anexos[nome]) {
      alteracoes.add('Anexo alterado: $nome');
    }
  }
  for (final nome in referencia.anexos.keys) {
    if (!atual.anexos.containsKey(nome)) {
      alteracoes.add('Anexo removido: $nome');
    }
  }
  if (referencia.especificacaoApi != atual.especificacaoApi) {
    alteracoes.add('Especificação da API (audesp.yaml) alterada');
  }
  return alteracoes;
}
