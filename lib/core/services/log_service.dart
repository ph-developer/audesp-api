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
  }) =>
      _dao.insertLog(
        endpoint: endpoint,
        request: request,
        response: response,
        statusCode: statusCode,
        userId: userId,
      );
}

