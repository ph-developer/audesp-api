import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/termos_contrato_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/environments.dart';

final termoServiceProvider = Provider<TermoService>((ref) {
  return TermoService(
    apiService: ref.watch(apiServiceProvider),
    logService: ref.watch(logServiceProvider),
    termosDao: ref.watch(termosContratoDaoProvider),
    currentEnv: ref.watch(environmentProvider),
  );
});

class TermoService {
  final ApiService _api;
  final LogService _log;
  final TermosContratoDao _termosDao;
  final Environment _currentEnv;

  TermoService({
    required ApiService apiService,
    required LogService logService,
    required TermosContratoDao termosDao,
    required Environment currentEnv,
  })  : _api = apiService,
        _log = logService,
        _termosDao = termosDao,
        _currentEnv = currentEnv;

  /// Envia termo de contrato ao AUDESP via multipart/form-data.
  Future<String> enviarTermo({
    required int termoId,
    required String documentoJson,
    int? userId,
  }) async {
    final endpoint =
        '${_currentEnv.baseUrl}/recepcao-fase-4/f4/enviar-termo-contrato';

    final formData = FormData.fromMap({
      'documentoJSON': MultipartFile.fromString(
        documentoJson,
        filename: 'termo_contrato.json',
      ),
    });

    late Response<dynamic> response;
    try {
      response = await _api.dio.post(endpoint, data: formData);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data?.toString() ?? e.message ?? '';
      await _log.record(
        endpoint: endpoint,
        request: documentoJson,
        response: body,
        statusCode: statusCode,
        userId: userId,
      );
      throw Exception(_parseError(statusCode, body));
    }

    final respBody = jsonEncode(response.data);
    await _log.record(
      endpoint: endpoint,
      request: documentoJson,
      response: respBody,
      statusCode: response.statusCode ?? 200,
      userId: userId,
    );

    await _termosDao.markAsSent(termoId);

    return response.data?['message']?.toString() ??
        'Termo de contrato enviado com sucesso.';
  }

  String _parseError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos: $body';
      case 401:
        return 'Não autorizado. Reconecte ao AUDESP.';
      case 403:
        return 'Acesso negado pelo AUDESP.';
      case 422:
        return 'Erro de validação: $body';
      case 500:
        return 'Erro interno do servidor AUDESP.';
      default:
        return 'Erro $statusCode: $body';
    }
  }
}
