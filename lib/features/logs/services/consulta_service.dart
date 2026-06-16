import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';
import '../../../core/services/api_service.dart';

final consultaServiceProvider = Provider<ConsultaService>((ref) {
  return ConsultaService(
    apiService: ref.watch(apiServiceProvider),
    currentEnv: ref.watch(environmentProvider),
  );
});

class ConsultaService {
  final ApiService _api;
  final Environment _currentEnv;

  ConsultaService({
    required ApiService apiService,
    required Environment currentEnv,
  })  : _api = apiService,
        _currentEnv = currentEnv;

  Future<String> consultarStatus(String protocolo) async {
    final endpoint = '${_currentEnv.baseUrl}/f4/consulta/$protocolo';

    try {
      final response = await _api.dio.get(endpoint);
      return jsonEncode(response.data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final body = e.response?.data?.toString() ?? e.message ?? '';
      throw Exception('Erro $statusCode: $body');
    }
  }
}
