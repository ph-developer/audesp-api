import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/licitacoes_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/environments.dart';

final licitacaoServiceProvider = Provider<LicitacaoService>((ref) {
  return LicitacaoService(
    apiService: ref.watch(apiServiceProvider),
    logService: ref.watch(logServiceProvider),
    licitacoesDao: ref.watch(licitacoesDaoProvider),
    currentEnv: ref.watch(environmentProvider),
  );
});

class LicitacaoService {
  final ApiService _api;
  final LogService _log;
  final LicitacoesDao _licitacoesDao;
  final Environment _currentEnv;

  LicitacaoService({
    required ApiService apiService,
    required LogService logService,
    required LicitacoesDao licitacoesDao,
    required Environment currentEnv,
  })  : _api = apiService,
        _log = logService,
        _licitacoesDao = licitacoesDao,
        _currentEnv = currentEnv;

  /// Envia licitação ao AUDESP via multipart/form-data.
  /// Retorna a mensagem de sucesso do servidor.
  Future<String> enviarLicitacao({
    required int licitacaoId,
    required String documentoJson,
    int? userId,
  }) async {
    final endpoint =
        '${_currentEnv.baseUrl}/recepcao-fase-4/f4/enviar-licitacao';

    final formData = FormData.fromMap({
      'documentoJSON': MultipartFile.fromString(
        documentoJson,
        filename: 'licitacao.json',
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

    await _licitacoesDao.markAsSent(licitacaoId);

    return response.data?['message']?.toString() ??
        'Licitação enviada com sucesso.';
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
