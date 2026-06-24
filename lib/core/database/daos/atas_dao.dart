import '../app_database.dart';
import '../database_service.dart';

class AtasDao {
  final DatabaseService _db;
  AtasDao(this._db);

  Future<List<Ata>> watchAll() async {
    final result = await _db.pool.execute(
      'SELECT * FROM atas ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Ata.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ata>> watchByStatus(String status) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM atas WHERE status = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([status]);
    return result.rows.map((r) => Ata.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ata>> watchByEdital(int editalId) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM atas WHERE edital_id = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([editalId]);
    return result.rows.map((r) => Ata.fromMap(r.typedAssoc())).toList();
  }

  Future<Ata?> findById(int id) async {
    final stmt = await _db.pool.prepare('SELECT * FROM atas WHERE id = (?)');
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : Ata.fromMap(rows.first.typedAssoc());
  }

  Future<Ata?> findByCodigoAta(
    String municipio,
    String entidade,
    String codigoAta,
  ) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM atas WHERE municipio = (?) AND entidade = (?) AND codigo_ata = (?)',
    );
    final result = await stmt.execute([municipio, entidade, codigoAta]);
    final rows = result.rows;
    return rows.isEmpty ? null : Ata.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertAta({
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO atas (edital_id, municipio, entidade, codigo_edital, codigo_ata, retificacao, status, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      editalId,
      municipio,
      entidade,
      codigoEdital,
      codigoAta,
      retificacao ? 1 : 0,
      status,
      documentoJson,
      now,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateAta({
    required int id,
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required String codigoAta,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE atas SET edital_id = ?, municipio = ?, entidade = ?, codigo_edital = ?, codigo_ata = ?, retificacao = ?, status = ?, documento_json = ?, updated_at = ? WHERE id = ?',
    );
    final result = await stmt.execute([
      editalId,
      municipio,
      entidade,
      codigoEdital,
      codigoAta,
      retificacao ? 1 : 0,
      status,
      documentoJson,
      now,
      id,
    ]);
    return result.affectedRows.toInt() > 0;
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE atas SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute(['sent', now, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM atas WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }
}
