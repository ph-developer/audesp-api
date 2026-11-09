import '../app_database.dart';
import '../database_service.dart';

class EditaisDao {
  final DatabaseService _db;
  EditaisDao(this._db);

  Future<List<Edital>> watchAll() async {
    final result = await _db.execute(
      'SELECT * FROM editais ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Edital.fromMap(r.typedAssoc())).toList();
  }

  /// Editais visíveis com o status informado (os ocultos ficam de fora).
  Future<List<Edital>> watchByStatus(String status) async {
    final result = await _db.executePrepared(
      'SELECT * FROM editais WHERE status = (?) AND oculto_em IS NULL '
      'ORDER BY updated_at DESC',
      [status],
    );
    return result.rows.map((r) => Edital.fromMap(r.typedAssoc())).toList();
  }

  Future<Edital?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM editais WHERE id = (?)',
      [id],
    );
    final rows = result.rows;
    return rows.isEmpty ? null : Edital.fromMap(rows.first.typedAssoc());
  }

  Future<Edital?> findByCodigoEdital(
    String municipio,
    String entidade,
    String codigoEdital,
  ) async {
    final result = await _db.executePrepared(
      'SELECT * FROM editais WHERE municipio = (?) AND entidade = (?) AND codigo_edital = (?)',
      [municipio, entidade, codigoEdital],
    );
    final rows = result.rows;
    return rows.isEmpty ? null : Edital.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertEdital({
    int? estimativaId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    bool semPncp = false,
    required bool retificacao,
    required String status,
    String? pdfPath,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final result = await _db.executePrepared(
      'INSERT INTO editais (municipio, entidade, codigo_edital, sem_pncp, retificacao, status, pdf_path, documento_json, updated_at, estimativa_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        municipio,
        entidade,
        codigoEdital,
        semPncp ? 1 : 0,
        retificacao ? 1 : 0,
        status,
        pdfPath,
        documentoJson,
        now,
        estimativaId,
      ],
    );
    return result.lastInsertID.toInt();
  }

  Future<bool> updateEdital({
    required int id,
    int? estimativaId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    bool semPncp = false,
    required bool retificacao,
    required String status,
    String? pdfPath,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    final now = (updatedAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final result = await _db.executePrepared(
      'UPDATE editais SET municipio = ?, entidade = ?, codigo_edital = ?, sem_pncp = ?, retificacao = ?, status = ?, pdf_path = ?, documento_json = ?, updated_at = ?, estimativa_id = ? WHERE id = ?',
      [
        municipio,
        entidade,
        codigoEdital,
        semPncp ? 1 : 0,
        retificacao ? 1 : 0,
        status,
        pdfPath,
        documentoJson,
        now,
        estimativaId,
        id,
      ],
    );
    return result.affectedRows.toInt() > 0;
  }

  Future<int> countByEstimativa(int estimativaId) async {
    final result = await _db.executePrepared(
      'SELECT COUNT(*) AS c FROM editais WHERE estimativa_id = ?',
      [estimativaId],
    );
    return result.rows.first.typedAssoc()['c'] as int;
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE editais SET status = ?, updated_at = ? WHERE id = ?',
      ['sent', now, id],
    );
  }

  Future<void> markAsDraft(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE editais SET status = ?, updated_at = ? WHERE id = ?',
      ['draft', now, id],
    );
  }

  Future<void> updateJson(int id, String json) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE editais SET documento_json = ?, updated_at = ? WHERE id = ?',
      [json, now, id],
    );
  }

  Future<int> deleteById(int id) async {
    final result = await _db.executePrepared(
      'DELETE FROM editais WHERE id = ?',
      [id],
    );
    return result.affectedRows.toInt();
  }
}
