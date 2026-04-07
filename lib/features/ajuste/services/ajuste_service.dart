import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/ajustes_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/environments.dart';

final ajusteServiceProvider = Provider<AjusteService>((ref) {
  return AjusteService(
    apiService: ref.watch(apiServiceProvider),
    logService: ref.watch(logServiceProvider),
    ajustesDao: ref.watch(ajustesDaoProvider),
    currentEnv: ref.watch(environmentProvider),
  );
});

class AjusteService {
  final ApiService _api;
  final LogService _log;
  final AjustesDao _ajustesDao;
  final Environment _currentEnv;

  AjusteService({
    required ApiService apiService,
    required LogService logService,
    required AjustesDao ajustesDao,
    required Environment currentEnv,
  })  : _api = apiService,
        _log = logService,
        _ajustesDao = ajustesDao,
        _currentEnv = currentEnv;

  /// Envia ajuste ao AUDESP via multipart/form-data.
  Future<String> enviarAjuste({
    required int ajusteId,
    required String documentoJson,
    int? userId,
  }) async {
    final endpoint =
        '${_currentEnv.baseUrl}/recepcao-fase-4/f4/enviar-ajuste';

    final formData = FormData.fromMap({
      'documentoJSON': MultipartFile.fromString(
        documentoJson,
        filename: 'ajuste.json',
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

    await _ajustesDao.markAsSent(ajusteId);

    return response.data?['message']?.toString() ??
        'Ajuste enviado com sucesso.';
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
