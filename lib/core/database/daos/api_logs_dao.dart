import '../app_database.dart';
import '../database_service.dart';

class ApiLogsDao {
  final DatabaseService _db;
  ApiLogsDao(this._db);

  Future<List<ApiLog>> watchAll() async {
    final result = await _db.pool
        .execute('SELECT * FROM api_logs ORDER BY timestamp DESC');
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<List<ApiLog>> watchByEndpoint(String endpoint) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM api_logs WHERE endpoint = (?) ORDER BY timestamp DESC',
    );
    final result = await stmt.execute([endpoint]);
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<List<ApiLog>> watchByUser(int userId) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM api_logs WHERE user_id = (?) ORDER BY timestamp DESC',
    );
    final result = await stmt.execute([userId]);
    return result.rows.map((r) => ApiLog.fromMap(r.typedAssoc())).toList();
  }

  Future<ApiLog?> findById(int id) async {
    final stmt =
        await _db.pool.prepare('SELECT * FROM api_logs WHERE id = (?)');
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : ApiLog.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertLog({
    required String endpoint,
    required String request,
    String? response,
    int? statusCode,
    int? userId,
    DateTime? timestamp,
  }) async {
    final ts =
        (timestamp ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO api_logs (endpoint, request, response, status_code, user_id, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt
        .execute([endpoint, request, response, statusCode, userId, ts]);
    return result.lastInsertID.toInt();
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
