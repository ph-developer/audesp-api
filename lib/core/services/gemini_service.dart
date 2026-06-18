import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:docx_to_text/docx_to_text.dart';

import '../database/daos/app_settings_dao.dart';

/// Resultado de uma extração Gemini: mapeamento campo → valor sugerido.
/// Os valores são sempre [String] (ou null se o campo não foi identificado).
typedef GeminiExtractionResult = Map<String, String?>;

/// Definição de um campo que o Gemini deve tentar extrair.
class GeminiField {
  /// Identificador do campo (ex.: `codigoEdital`).
  final String key;

  /// Rótulo legível exibido ao usuário (ex.: `Código do Edital`).
  final String label;

  /// Dicas adicionais para o prompt (ex.: formato esperado, valores válidos).
  final String? hint;

  const GeminiField({required this.key, required this.label, this.hint});
}

/// Serviço agnóstico de formulário para extração de campos via Gemini.
///
/// Recebe um arquivo PDF, uma lista de [GeminiField] a extrair e delega
/// a análise ao modelo configurado nas [AppSettings].
///
/// Pode ser reutilizado por qualquer módulo que precise de extração de dados
/// a partir de PDFs (Edital, Ajuste, Contrato, etc.).
class GeminiService {
  final AppSettingsDao _settings;

  GeminiService(this._settings);

  /// Extrai campos de [pdfPath] usando o modelo e chave configurados.
  /// Deprecated: Utilize [extractFromFile] para suporte a múltiplos formatos.
  Future<GeminiExtractionResult> extractFromPdf({
    required String pdfPath,
    required List<GeminiField> fields,
  }) async {
    return extractFromFile(filePath: pdfPath, fields: fields);
  }

  /// Extrai campos de um arquivo usando o modelo e chave configurados.
  ///
  /// Suporta arquivos PDF, DOC e DOCX.
  /// Retorna [GeminiExtractionResult] com um valor por campo (null = não
  /// encontrado) ou lança [GeminiException] em caso de erro.
  Future<GeminiExtractionResult> extractFromFile({
    required String filePath,
    required List<GeminiField> fields,
  }) async {
    final apiKey = await _settings.get(SettingsKeys.geminiApiKey);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw GeminiException(
        'Chave de API do Gemini não configurada. '
        'Configure-a no painel de Administração → IA / Gemini.',
      );
    }

    final modelName = await _settings.get(SettingsKeys.geminiModel);
    final model = (modelName != null && modelName.trim().isNotEmpty)
        ? modelName.trim()
        : 'gemini-3.1-flash-lite';

    final fieldDescriptions = fields.map((f) {
      final hint = f.hint != null ? ' (${f.hint})' : '';
      return '- "${f.key}": ${f.label}$hint';
    }).join('\n');

    final prompt = '''
Você é um assistente especializado em licitações públicas brasileiras.
Analise o documento fornecido e extraia os seguintes campos no formato JSON.
Retorne APENAS um objeto JSON válido, sem markdown, sem texto adicional.
Se um campo não for encontrado ou não puder ser determinado, use null como valor.

Campos a extrair:
$fieldDescriptions

Exemplo de resposta esperada:
{
  "campo1": "valor encontrado",
  "campo2": null
}
''';

    final generativeModel = GenerativeModel(
      model: model,
      apiKey: apiKey.trim(),
    );

    final lowerPath = filePath.toLowerCase();
    final isWordDoc = lowerPath.endsWith('.docx') || lowerPath.endsWith('.doc');

    Part filePart;
    if (isWordDoc) {
      final bytes = await File(filePath).readAsBytes();
      final text = docxToText(bytes);
      filePart = TextPart(text);
    } else {
      final pdfBytes = await File(filePath).readAsBytes();
      filePart = DataPart('application/pdf', pdfBytes);
    }

    final content = [
      Content.multi([
        filePart,
        TextPart(prompt),
      ]),
    ];

    final response = await generativeModel.generateContent(content);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return _parseResult(text.trim(), fields);
  }

  /// Extrai e valida o JSON retornado pelo modelo.
  GeminiExtractionResult _parseResult(String raw, List<GeminiField> fields) {
    // Remove possível bloco ```json ... ``` caso o modelo ignore a instrução.
    var cleaned = raw;
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }

    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(cleaned);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Root element is not a JSON object.');
      }
      decoded = parsed;
    } catch (e) {
      throw GeminiException(
        'Resposta do Gemini não é JSON válido: $e\n\nResposta original:\n$raw',
      );
    }

    final result = <String, String?>{};
    for (final field in fields) {
      final value = decoded[field.key];
      result[field.key] = value?.toString();
    }
    return result;
  }
}

/// Exceção específica do [GeminiService].
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}
