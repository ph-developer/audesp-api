import '../app_database.dart';
import '../database_service.dart';

class EditaisDao {
  final DatabaseService _db;
  EditaisDao(this._db);

  Future<List<Edital>> watchAll() async {
    final result = await _db.pool.execute(
      'SELECT * FROM editais ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Edital.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Edital>> watchByStatus(String status) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM editais WHERE status = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([status]);
    return result.rows.map((r) => Edital.fromMap(r.typedAssoc())).toList();
  }

  Future<Edital?> findById(int id) async {
    final stmt = await _db.pool.prepare('SELECT * FROM editais WHERE id = (?)');
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : Edital.fromMap(rows.first.typedAssoc());
  }

  Future<Edital?> findByCodigoEdital(
    String municipio,
    String entidade,
    String codigoEdital,
  ) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM editais WHERE municipio = (?) AND entidade = (?) AND codigo_edital = (?)',
    );
    final result = await stmt.execute([municipio, entidade, codigoEdital]);
    final rows = result.rows;
    return rows.isEmpty ? null : Edital.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertEdital({
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
    required String status,
    String? pdfPath,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO editais (municipio, entidade, codigo_edital, retificacao, status, pdf_path, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      municipio,
      entidade,
      codigoEdital,
      retificacao ? 1 : 0,
      status,
      pdfPath,
      documentoJson,
      now,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateEdital({
    required int id,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
    required String status,
    String? pdfPath,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE editais SET municipio = ?, entidade = ?, codigo_edital = ?, retificacao = ?, status = ?, pdf_path = ?, documento_json = ?, updated_at = ? WHERE id = ?',
    );
    final result = await stmt.execute([
      municipio,
      entidade,
      codigoEdital,
      retificacao ? 1 : 0,
      status,
      pdfPath,
      documentoJson,
      now,
      id,
    ]);
    return result.affectedRows.toInt() > 0;
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE editais SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute(['sent', now, id]);
  }

  Future<void> updateJson(int id, String json) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE editais SET documento_json = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute([json, now, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM editais WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }
}
