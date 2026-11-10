import 'dart:convert';

/// Nomes de campo do documento de Ajuste que divergem da documentação.
///
/// O schema e a planilha do TCE (15/10/2026) chamam o início da vigência de
/// `dataVigenciaInicio`, mas o AUDESP só reconhece `datavigenciaInicio`: com
/// o nome documentado ele rejeita o ajuste pela RN012_AJUSTE ("deve ser
/// informada a data de início da vigência ... ou a quantidade de meses").
/// Documentos salvos antes desta correção usam o nome documentado.
abstract final class AjusteDocumento {
  static const campoVigenciaInicio = 'datavigenciaInicio';
  static const campoVigenciaInicioDocumentado = 'dataVigenciaInicio';

  static String? vigenciaInicio(Map<String, dynamic> doc) =>
      (doc[campoVigenciaInicio] ?? doc[campoVigenciaInicioDocumentado])
          as String?;

  /// Troca o nome documentado pelo aceito, mantendo a ordem dos campos.
  static Map<String, dynamic> paraEnvio(Map<String, dynamic> doc) {
    if (!doc.containsKey(campoVigenciaInicioDocumentado)) return doc;
    final temAceito = doc.containsKey(campoVigenciaInicio);
    return {
      for (final MapEntry(:key, :value) in doc.entries)
        if (key != campoVigenciaInicioDocumentado)
          key: value
        else if (!temAceito)
          campoVigenciaInicio: value,
    };
  }

  /// Versão de [paraEnvio] para o JSON salvo (reenvios usam o documento do
  /// banco). Um texto que não é objeto JSON segue como está.
  static String paraEnvioJson(String json) {
    try {
      final doc = jsonDecode(json);
      if (doc is! Map<String, dynamic> ||
          !doc.containsKey(campoVigenciaInicioDocumentado)) {
        return json;
      }
      return jsonEncode(paraEnvio(doc));
    } on FormatException {
      return json;
    }
  }
}
