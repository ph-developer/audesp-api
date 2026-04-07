import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/editais_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/environments.dart';

final editalServiceProvider = Provider<EditalService>((ref) {
  return EditalService(
    apiService: ref.watch(apiServiceProvider),
    logService: ref.watch(logServiceProvider),
    editaisDao: ref.watch(editaisDaoProvider),
    currentEnv: ref.watch(environmentProvider),
  );
});

class EditalService {
  final ApiService _api;
  final LogService _log;
  final EditaisDao _editaisDao;
  final Environment _currentEnv;

  EditalService({
    required ApiService apiService,
    required LogService logService,
    required EditaisDao editaisDao,
    required Environment currentEnv,
  })  : _api = apiService,
        _log = logService,
        _editaisDao = editaisDao,
        _currentEnv = currentEnv;

  /// Envia edital ao AUDESP via multipart/form-data.
  /// Retorna a mensagem de sucesso do servidor.
  Future<String> enviarEdital({
    required int editalId,
    required String documentoJson,
    required String? pdfPath,
    int? userId,
  }) async {
    final endpoint =
        '${_currentEnv.baseUrl}/recepcao-fase-4/f4/enviar-edital';

    final fields = <String, dynamic>{
      'documentoJSON': MultipartFile.fromString(
        documentoJson,
        filename: 'edital.json',
      ),
    };
    if (pdfPath != null) {
      fields['arquivoPDF'] = await MultipartFile.fromFile(
        pdfPath,
        filename: pdfPath.split(RegExp(r'[/\\]')).last,
      );
    }
    final formData = FormData.fromMap(fields);

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

    await _editaisDao.markAsSent(editalId);

    return response.data?['message']?.toString() ??
        'Edital enviado com sucesso.';
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
