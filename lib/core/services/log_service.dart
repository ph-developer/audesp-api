import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_providers.dart';
import '../database/daos/api_logs_dao.dart';

final logServiceProvider = Provider<LogService>(
  (ref) => LogService(ref.watch(apiLogsDaoProvider)),
);

class LogService {
  final ApiLogsDao _dao;
  LogService(this._dao);

  Future<void> record({
    required String endpoint,
    required String request,
    required String response,
    required int statusCode,
    int? userId,
  }) async {
    String? protocolo;
    String? statusProtocolo;

    if (statusCode >= 200 && statusCode < 300 && response.isNotEmpty) {
      try {
        final json = jsonDecode(response);
        if (json is Map<String, dynamic> && json.containsKey('protocolo')) {
          protocolo = json['protocolo']?.toString();
          statusProtocolo = 'Pendente'; // Status inicial
        }
      } catch (_) {
        // Ignora erro de parsing
      }
    }

    await _dao.insertLog(
      endpoint: endpoint,
      request: request,
      response: response,
      statusCode: statusCode,
      userId: userId,
      protocolo: protocolo,
      statusProtocolo: statusProtocolo,
    );
  }
}
