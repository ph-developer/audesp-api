import 'package:flutter_riverpod/flutter_riverpod.dart';

final logServiceProvider = Provider<LogService>((ref) => LogService());

class LogService {
  /// Grava uma chamada à API na tabela api_logs.
  Future<void> record({
    required String endpoint,
    required String request,
    required String response,
    required int statusCode,
    required int userId,
  }) async {
    // TODO: implementar persistência em SQLite
  }
}
