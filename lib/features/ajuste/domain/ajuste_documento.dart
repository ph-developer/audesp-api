import 'dart:convert';

/// Compatibilidade com as grafias do início da vigência do Ajuste.
///
/// A RN010_AJUSTE cita `dataVigenciaInicio`, como o schema do TCE, e a
/// RN012_AJUSTE cita `datavigenciaInicio`. O envio inclui ambas as grafias.
abstract final class AjusteDocumento {
  static const campoVigenciaInicio = 'datavigenciaInicio';
  static const campoVigenciaInicioDocumentado = 'dataVigenciaInicio';

  static String? vigenciaInicio(Map<String, dynamic> doc) {
    final inicio =
        doc[campoVigenciaInicio] ?? doc[campoVigenciaInicioDocumentado];
    return inicio is String ? inicio : null;
  }

  /// Inclui as duas grafias com a data informada no documento.
  static Map<String, dynamic> paraEnvio(Map<String, dynamic> doc) {
    final inicio = vigenciaInicio(doc);
    if (inicio == null || inicio.trim().isEmpty) return doc;
    if (doc[campoVigenciaInicio] == inicio &&
        doc[campoVigenciaInicioDocumentado] == inicio) {
      return doc;
    }
    return {
      ...doc,
      campoVigenciaInicio: inicio,
      campoVigenciaInicioDocumentado: inicio,
    };
  }

  /// Versão de [paraEnvio] para o JSON salvo (reenvios usam o documento do
  /// banco). Um texto que não é objeto JSON segue como está.
  static String paraEnvioJson(String json) {
    try {
      final doc = jsonDecode(json);
      if (doc is! Map<String, dynamic>) return json;
      final documento = paraEnvio(doc);
      return identical(documento, doc) ? json : jsonEncode(documento);
    } on FormatException {
      return json;
    }
  }
}
