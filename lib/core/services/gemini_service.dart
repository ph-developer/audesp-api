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
  /// Suporta arquivos PDF e DOCX.
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

    final prompt = generatePromptFromFields(fields);

    final generativeModel = GenerativeModel(
      model: model,
      apiKey: apiKey.trim(),
    );

    final lowerPath = filePath.toLowerCase();
    final isWordDoc = lowerPath.endsWith('.docx');
    final isPdf = lowerPath.endsWith('.pdf');
    if (!isWordDoc && !isPdf) {
      throw const GeminiException('Formato não suportado. Use PDF ou DOCX.');
    }

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
      Content.multi([filePart, TextPart(prompt)]),
    ];

    final response = await generativeModel.generateContent(content);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return parseResult(text.trim(), fields);
  }

  /// Gera o prompt para extração de campos baseados numa lista de [GeminiField].
  String generatePromptFromFields(List<GeminiField> fields) {
    final fieldDescriptions = fields
        .map((f) {
          final hint = f.hint != null ? ' (${f.hint})' : '';
          return '- "${f.key}": ${f.label}$hint';
        })
        .join('\n');

    return '''
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
  }

  /// Extrai e valida o JSON retornado pelo modelo.
  GeminiExtractionResult parseResult(String raw, List<GeminiField> fields) {
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
      if (value is List || value is Map) {
        result[field.key] = jsonEncode(value);
      } else {
        result[field.key] = value?.toString();
      }
    }
    return result;
  }

  String getOrcamentoPrompt(List<Map<String, dynamic>> itensEstimativa) {
    final itensJson = jsonEncode(itensEstimativa);
    return '''
Você é um assistente especializado em licitações públicas brasileiras.
Analise o documento de orçamento fornecido e extraia as seguintes informações no formato JSON:
1. "razaoSocial": Razão social da empresa fornecedora.
2. "cnpj": CNPJ da empresa fornecedora (formatado). IMPORTANTE: Ignore o CNPJ 49.576.416/0001-41 (e suas variações de formatação), pois pertence à prefeitura e não ao fornecedor.
3. "data": Data da emissão do orçamento (formato dd/MM/yyyy).
4. "itens": Uma lista de objetos para os itens encontrados no documento que correspondam aos itens da estimativa abaixo. Para cada item cotado com valor maior que zero, retorne "id" (string, conforme a lista abaixo) e "valorUnitario" (número de ponto flutuante, ex: 15.50). Valores iguais a zero significam item não cotado e devem ser omitidos.

Itens da estimativa para cruzar:
$itensJson

Retorne APENAS um objeto JSON válido, sem markdown, sem texto adicional.
Se um campo global não for encontrado (razaoSocial, cnpj, data), use null.

Exemplo de resposta esperada:
{
  "razaoSocial": "Empresa Fictícia LTDA",
  "cnpj": "12.345.678/0001-90",
  "data": "10/05/2026",
  "itens": [
    { "id": "1", "valorUnitario": 1500.50 },
    { "id": "L1-I2", "valorUnitario": 45.0 }
  ]
}
''';
  }

  /// Extrai dados de fornecedor e valores unitários de itens a partir de um PDF de orçamento.
  Future<GeminiOrcamentoResult> extractOrcamentoFromFile({
    required String filePath,
    required List<Map<String, dynamic>> itensEstimativa,
  }) async {
    final model = await _buildModel();
    final filePart = await _readFilePart(filePath);

    final prompt = getOrcamentoPrompt(itensEstimativa);

    final content = [
      Content.multi([filePart, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return parseOrcamentoResult(text.trim());
  }

  String getMultiOrcamentoPrompt(List<Map<String, dynamic>> itensEstimativa) {
    final itensJson = jsonEncode(itensEstimativa);
    return '''
Você é um assistente especializado em licitações públicas brasileiras.
Analise o documento de orçamento fornecido. Este documento contém orçamentos de MÚLTIPLAS empresas em sequência.
Para CADA empresa identificada, extraia:
1. "razaoSocial": Razão social da empresa fornecedora.
2. "cnpj": CNPJ da empresa fornecedora (formatado). IMPORTANTE: Ignore o CNPJ 49.576.416/0001-41 (e suas variações de formatação), pois pertence à prefeitura e não ao fornecedor.
3. "data": Data da emissão do orçamento (formato dd/MM/yyyy).
4. "itens": Uma lista de objetos para os itens encontrados no documento que correspondam aos itens da estimativa abaixo. Para cada item cotado com valor maior que zero, retorne "id" (string, conforme a lista abaixo) e "valorUnitario" (número de ponto flutuante, ex: 15.50). Valores iguais a zero significam item não cotado e devem ser omitidos.

Itens da estimativa para cruzar:
$itensJson

Retorne APENAS um objeto JSON válido, sem markdown, sem texto adicional, com a seguinte estrutura:
{
  "empresas": [
    {
      "razaoSocial": "Empresa A LTDA",
      "cnpj": "12.345.678/0001-90",
      "data": "10/05/2026",
      "itens": [
        { "id": "1", "valorUnitario": 1500.50 },
        { "id": "2", "valorUnitario": 45.0 }
      ]
    },
    {
      "razaoSocial": "Empresa B LTDA",
      "cnpj": "98.765.432/0001-10",
      "data": "15/05/2026",
      "itens": [
        { "id": "1", "valorUnitario": 1600.00 }
      ]
    }
  ]
}

Se um campo (razaoSocial, cnpj, data) não for encontrado para uma empresa, use null.
Se nenhuma empresa for encontrada, retorne {"empresas": []}.
''';
  }

  /// Extrai dados de MÚLTIPLOS fornecedores de um único documento (orçamentos
  /// compilados de várias empresas em sequência).
  Future<List<GeminiOrcamentoResult>> extractMultiOrcamentoFromFile({
    required String filePath,
    required List<Map<String, dynamic>> itensEstimativa,
  }) async {
    final model = await _buildModel();
    final filePart = await _readFilePart(filePath);

    final prompt = getMultiOrcamentoPrompt(itensEstimativa);

    final content = [
      Content.multi([filePart, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return parseMultiOrcamentoResult(text.trim());
  }

  /// Constrói o [GenerativeModel] com base nas configurações do banco.
  Future<GenerativeModel> _buildModel() async {
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

    return GenerativeModel(model: model, apiKey: apiKey.trim());
  }

  /// Lê o arquivo e retorna a [Part] correspondente (PDF ou DOCX).
  Future<Part> _readFilePart(String filePath) async {
    final lowerPath = filePath.toLowerCase();
    final isWordDoc = lowerPath.endsWith('.docx');
    final isPdf = lowerPath.endsWith('.pdf');
    if (!isWordDoc && !isPdf) {
      throw const GeminiException('Formato não suportado. Use PDF ou DOCX.');
    }

    if (isWordDoc) {
      final bytes = await File(filePath).readAsBytes();
      final text = docxToText(bytes);
      return TextPart(text);
    } else {
      final pdfBytes = await File(filePath).readAsBytes();
      return DataPart('application/pdf', pdfBytes);
    }
  }

  GeminiOrcamentoResult parseOrcamentoResult(String raw) {
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

    final mapItens = <String, double>{};
    final listItens = decoded['itens'] as List<dynamic>? ?? [];
    for (final item in listItens) {
      if (item is Map<String, dynamic>) {
        final idVal = item['id'];
        final val = item['valorUnitario'];
        if (idVal != null && val != null) {
          final strId = idVal.toString();
          final doubleVal = val is num
              ? val.toDouble()
              : double.tryParse(val.toString());
          if (doubleVal != null && doubleVal > 0) {
            mapItens[strId] = doubleVal;
          }
        }
      }
    }

    if (mapItens.isEmpty) {
      throw const GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return GeminiOrcamentoResult(
      razaoSocial: decoded['razaoSocial']?.toString(),
      cnpj: decoded['cnpj']?.toString(),
      data: decoded['data']?.toString(),
      itens: mapItens,
    );
  }

  List<GeminiOrcamentoResult> parseMultiOrcamentoResult(String raw) {
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

    final empresas = decoded['empresas'] as List<dynamic>? ?? [];
    if (empresas.isEmpty) {
      throw const GeminiException(
        'Nenhum orçamento foi identificado no documento.',
      );
    }

    final results = <GeminiOrcamentoResult>[];
    for (final rawEmpresa in empresas) {
      if (rawEmpresa is! Map<String, dynamic>) continue;

      final mapItens = <String, double>{};
      final listItens = rawEmpresa['itens'] as List<dynamic>? ?? [];
      for (final item in listItens) {
        if (item is Map<String, dynamic>) {
          final idVal = item['id'];
          final val = item['valorUnitario'];
          if (idVal != null && val != null) {
            final strId = idVal.toString();
            final doubleVal = val is num
                ? val.toDouble()
                : double.tryParse(val.toString());
            if (doubleVal != null && doubleVal > 0) {
              mapItens[strId] = doubleVal;
            }
          }
        }
      }

      if (mapItens.isNotEmpty) {
        results.add(
          GeminiOrcamentoResult(
            razaoSocial: rawEmpresa['razaoSocial']?.toString(),
            cnpj: rawEmpresa['cnpj']?.toString(),
            data: rawEmpresa['data']?.toString(),
            itens: mapItens,
          ),
        );
      }
    }

    if (results.isEmpty) {
      throw const GeminiException(
        'Nenhum item de orçamento foi identificado no documento.',
      );
    }

    return results;
  }

  String getItensEstimativaPrompt() {
    return '''
Você é um assistente especializado em licitações públicas brasileiras.
Analise o documento fornecido (provavelmente um Termo de Referência ou edital) e extraia a lista de ITENS a serem contratados/adquiridos.
Para cada item identificado, retorne um objeto com os seguintes campos:
1. "descricao": String com a descrição detalhada do item.
2. "quantidade": Número (int ou float) com a quantidade total.
3. "unidade": String com a unidade de medida (ex: "UN", "Mês", "Serviço", "KG").
4. "materialOuServico": String sendo obrigatoriamente "M" (para material/produto) ou "S" (para serviço).
5. "itemCategoriaId": Inteiro representando a categoria do item, devendo ser APENAS um dos seguintes valores (deduza o mais adequado):
   - 1 para "Bens Imóveis"
   - 2 para "Bens Móveis" (materiais, produtos em geral)
   - 3 para "Não se aplica" (serviços em geral)

Retorne APENAS um objeto JSON válido, sem markdown, com a seguinte estrutura:
{
  "itens": [
    {
      "descricao": "Caneta esferográfica azul...",
      "quantidade": 1000,
      "unidade": "UN",
      "materialOuServico": "M",
      "itemCategoriaId": 2
    },
    {
      "descricao": "Serviço de limpeza...",
      "quantidade": 12,
      "unidade": "Mês",
      "materialOuServico": "S",
      "itemCategoriaId": 3
    }
  ]
}

Se nenhum item for encontrado, retorne {"itens": []}.
''';
  }

  /// Extrai lista de itens para uma estimativa a partir de um PDF (Termo de Referência, etc).
  Future<List<GeminiEstimativaItemResult>> extractItensEstimativaFromFile({
    required String filePath,
  }) async {
    final model = await _buildModel();
    final filePart = await _readFilePart(filePath);

    final prompt = getItensEstimativaPrompt();

    final content = [
      Content.multi([filePart, TextPart(prompt)]),
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw GeminiException('O modelo não retornou nenhuma resposta.');
    }

    return parseItensEstimativaResult(text.trim());
  }

  List<GeminiEstimativaItemResult> parseItensEstimativaResult(String raw) {
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

    final itens = decoded['itens'] as List<dynamic>? ?? [];
    if (itens.isEmpty) {
      throw const GeminiException('Nenhum item foi identificado no documento.');
    }

    final results = <GeminiEstimativaItemResult>[];
    for (final rawItem in itens) {
      if (rawItem is! Map<String, dynamic>) continue;

      final desc = rawItem['descricao']?.toString();
      final quantRaw = rawItem['quantidade'];
      final unid = rawItem['unidade']?.toString();
      final ms = rawItem['materialOuServico']?.toString().toUpperCase();
      final catId = rawItem['itemCategoriaId'];

      if (desc != null && quantRaw != null && unid != null) {
        final doubleQuant = quantRaw is num
            ? quantRaw.toDouble()
            : double.tryParse(quantRaw.toString()) ?? 0.0;

        final finalMs = (ms == 'M' || ms == 'S') ? ms! : 'M';
        final finalCatId = catId is int
            ? catId
            : int.tryParse(catId.toString()) ?? 2;

        results.add(
          GeminiEstimativaItemResult(
            descricao: desc,
            quantidade: doubleQuant,
            unidade: unid,
            materialOuServico: finalMs,
            itemCategoriaId: finalCatId,
          ),
        );
      }
    }

    if (results.isEmpty) {
      throw const GeminiException(
        'Não foi possível extrair os itens com os campos obrigatórios.',
      );
    }

    return results;
  }
}

/// Resultado da extração de um orçamento via Gemini.
class GeminiOrcamentoResult {
  final String? razaoSocial;
  final String? cnpj;
  final String? data;
  final Map<String, double> itens;

  const GeminiOrcamentoResult({
    this.razaoSocial,
    this.cnpj,
    this.data,
    required this.itens,
  });
}

/// Resultado da extração de um item de estimativa via Gemini.
class GeminiEstimativaItemResult {
  final String descricao;
  final double quantidade;
  final String unidade;
  final String materialOuServico;
  final int itemCategoriaId;

  const GeminiEstimativaItemResult({
    required this.descricao,
    required this.quantidade,
    required this.unidade,
    required this.materialOuServico,
    required this.itemCategoriaId,
  });
}

/// Exceção específica do [GeminiService].
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}
