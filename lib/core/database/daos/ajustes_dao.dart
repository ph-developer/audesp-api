import '../app_database.dart';
import '../database_service.dart';

class AjustesDao {
  final DatabaseService _db;
  AjustesDao(this._db);

  Future<List<Ajuste>> watchAll() async {
    final result = await _db.pool
        .execute('SELECT * FROM ajustes ORDER BY updated_at DESC');
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> watchByEdital(int editalId) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM ajustes WHERE edital_id = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([editalId]);
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> watchByAta(int ataId) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM ajustes WHERE ata_id = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([ataId]);
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<Ajuste?> findById(int id) async {
    final stmt =
        await _db.pool.prepare('SELECT * FROM ajustes WHERE id = (?)');
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : Ajuste.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertAjuste({
    required int editalId,
    int? ataId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO ajustes (edital_id, ata_id, municipio, entidade, codigo_edital, codigo_ata, codigo_contrato, retificacao, status, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      editalId,
      ataId,
      municipio,
      entidade,
      codigoEdital,
      codigoAta,
      codigoContrato,
      retificacao ? 1 : 0,
      status,
      documentoJson,
      now,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateAjuste({
    required int id,
    required int editalId,
    int? ataId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE ajustes SET edital_id = ?, ata_id = ?, municipio = ?, entidade = ?, codigo_edital = ?, codigo_ata = ?, codigo_contrato = ?, retificacao = ?, status = ?, documento_json = ?, updated_at = ? WHERE id = ?',
    );
    final result = await stmt.execute([
      editalId,
      ataId,
      municipio,
      entidade,
      codigoEdital,
      codigoAta,
      codigoContrato,
      retificacao ? 1 : 0,
      status,
      documentoJson,
      now,
      id,
    ]);
    return result.affectedRows.toInt() > 0;
  }

  Future<List<Ajuste>> watchByStatus(String status) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM ajustes WHERE status = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([status]);
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> getAll() async {
    final result = await _db.pool
        .execute('SELECT * FROM ajustes ORDER BY updated_at DESC');
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE ajustes SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute(['sent', now, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM ajustes WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }
}
