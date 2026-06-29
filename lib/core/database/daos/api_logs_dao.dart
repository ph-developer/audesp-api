import 'dart:convert';

import '../app_database.dart';
import '../database_service.dart';

class ApiLogsDao {
  final DatabaseService _db;
  ApiLogsDao(this._db);

  Future<List<ApiLog>> watchAll() async {
    final result = await _db.pool.execute(
      'SELECT a.*, u.nome AS user_name FROM api_logs a LEFT JOIN users u ON a.user_id = u.id ORDER BY a.timestamp DESC',
    );
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<List<ApiLog>> watchByEndpoint(String endpoint) async {
    final stmt = await _db.pool.prepare(
      'SELECT a.*, u.nome AS user_name FROM api_logs a LEFT JOIN users u ON a.user_id = u.id WHERE a.endpoint = (?) ORDER BY a.timestamp DESC',
    );
    final result = await stmt.execute([endpoint]);
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<List<ApiLog>> watchByUser(int userId) async {
    final stmt = await _db.pool.prepare(
      'SELECT a.*, u.nome AS user_name FROM api_logs a LEFT JOIN users u ON a.user_id = u.id WHERE a.user_id = (?) ORDER BY a.timestamp DESC',
    );
    final result = await stmt.execute([userId]);
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<ApiLog?> findById(int id) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM api_logs WHERE id = (?)',
    );
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : ApiLog.fromMap(rows.first.typedAssoc());
  }

  Future<ApiLog?> findLatestEditalSendLog({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
  }) async {
    return _findLatestSendLogByDescritor(
      endpointContains: 'enviar-edital',
      expected: {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': codigoEdital,
        'retificacao': retificacao,
      },
    );
  }

  Future<ApiLog?> findLatestLicitacaoSendLog({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
  }) async {
    return _findLatestSendLogByDescritor(
      endpointContains: 'enviar-licitacao',
      expected: {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': codigoEdital,
        'retificacao': retificacao,
      },
    );
  }

  Future<ApiLog?> findLatestAtaSendLog({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    required bool retificacao,
  }) async {
    return _findLatestSendLogByDescritor(
      endpointContains: 'enviar-ata',
      expected: {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': codigoEdital,
        'codigoAta': codigoAta,
        'retificacao': retificacao,
      },
    );
  }

  Future<ApiLog?> findLatestAjusteSendLog({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
  }) async {
    return _findLatestSendLogByDescritor(
      endpointContains: 'enviar-ajuste',
      expected: {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': codigoEdital,
        if (codigoAta != null && codigoAta.isNotEmpty) 'codigoAta': codigoAta,
        'codigoContrato': codigoContrato,
        'retificacao': retificacao,
      },
    );
  }

  Future<ApiLog?> _findLatestSendLogByDescritor({
    required String endpointContains,
    required Map<String, Object?> expected,
  }) async {
    final stmt = await _db.pool.prepare(
      "SELECT * FROM api_logs WHERE endpoint LIKE ? ORDER BY timestamp DESC, id DESC",
    );
    final result = await stmt.execute(['%$endpointContains%']);

    for (final row in result.rows) {
      final log = ApiLog.fromMap(row.typedAssoc());
      try {
        final doc = jsonDecode(log.request) as Map<String, dynamic>;
        final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
        final matches = expected.entries.every((entry) {
          final actual = descritor[entry.key];
          final expectedValue = entry.value;
          if (expectedValue is bool) return actual == expectedValue;
          return actual?.toString() == expectedValue?.toString();
        });
        if (matches) {
          return log;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<int> insertLog({
    required String endpoint,
    required String request,
    String? response,
    int? statusCode,
    int? userId,
    DateTime? timestamp,
    String? protocolo,
    String? statusProtocolo,
  }) async {
    final ts = (timestamp ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO api_logs (endpoint, request, response, status_code, user_id, timestamp, protocolo, status_protocolo) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      endpoint,
      request,
      response,
      statusCode,
      userId,
      ts,
      protocolo,
      statusProtocolo,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<void> updateProtocoloInfo(
    int id,
    String statusProtocolo,
    String retornoStatus,
  ) async {
    final stmt = await _db.pool.prepare(
      'UPDATE api_logs SET status_protocolo = ?, retorno_status = ? WHERE id = ?',
    );
    await stmt.execute([statusProtocolo, retornoStatus, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM api_logs WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }

  Future<int> clearAll() async {
    final result = await _db.pool.execute('DELETE FROM api_logs');
    return result.affectedRows.toInt();
  }
}
