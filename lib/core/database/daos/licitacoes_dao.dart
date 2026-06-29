import '../app_database.dart';
import '../database_service.dart';

class LicitacoesDao {
  final DatabaseService _db;
  LicitacoesDao(this._db);

  Future<List<Licitacao>> watchAll() async {
    final result = await _db.pool.execute(
      'SELECT * FROM licitacoes ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Licitacao>> watchByStatus(String status) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM licitacoes WHERE status = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([status]);
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Licitacao>> watchByEdital(int editalId) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM licitacoes WHERE edital_id = (?) ORDER BY updated_at DESC',
    );
    final result = await stmt.execute([editalId]);
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<Licitacao?> findById(int id) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM licitacoes WHERE id = (?)',
    );
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : Licitacao.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertLicitacao({
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO licitacoes (edital_id, municipio, entidade, codigo_edital, retificacao, status, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      editalId,
      municipio,
      entidade,
      codigoEdital,
      retificacao ? 1 : 0,
      status,
      documentoJson,
      now,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateLicitacao({
    required int id,
    required int editalId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE licitacoes SET edital_id = ?, municipio = ?, entidade = ?, codigo_edital = ?, retificacao = ?, status = ?, documento_json = ?, updated_at = ? WHERE id = ?',
    );
    final result = await stmt.execute([
      editalId,
      municipio,
      entidade,
      codigoEdital,
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
      'UPDATE licitacoes SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute(['sent', now, id]);
  }

  Future<void> markAsDraft(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE licitacoes SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute(['draft', now, id]);
  }

  Future<void> updateJson(int id, String json) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE licitacoes SET documento_json = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute([json, now, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM licitacoes WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }
}
