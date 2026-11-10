import '../app_database.dart';
import '../database_service.dart';

class AjustesDao {
  final DatabaseService _db;
  AjustesDao(this._db);

  Future<List<Ajuste>> watchAll() async {
    final result = await _db.execute(
      'SELECT * FROM ajustes ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> watchByEdital(int editalId) async {
    final result = await _db.executePrepared(
      'SELECT * FROM ajustes WHERE edital_id = (?) ORDER BY updated_at DESC',
      [editalId],
    );
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> watchByAta(int ataId) async {
    final result = await _db.executePrepared(
      'SELECT * FROM ajustes WHERE ata_id = (?) ORDER BY updated_at DESC',
      [ataId],
    );
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<Ajuste?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM ajustes WHERE id = (?)',
      [id],
    );
    final rows = result.rows;
    return rows.isEmpty ? null : Ajuste.fromMap(rows.first.typedAssoc());
  }

  Future<int> insertAjuste({
    required int? editalId,
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
    final result = await _db.executePrepared(
      'INSERT INTO ajustes (edital_id, ata_id, municipio, entidade, codigo_edital, codigo_ata, codigo_contrato, retificacao, status, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
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
      ],
    );
    return result.lastInsertID.toInt();
  }

  Future<bool> updateAjuste({
    required int id,
    required int? editalId,
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
    final result = await _db.executePrepared(
      'UPDATE ajustes SET edital_id = ?, ata_id = ?, municipio = ?, entidade = ?, codigo_edital = ?, codigo_ata = ?, codigo_contrato = ?, retificacao = ?, status = ?, documento_json = ?, updated_at = ? WHERE id = ?',
      [
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
      ],
    );
    return result.affectedRows.toInt() > 0;
  }

  Future<List<Ajuste>> watchByStatus(String status) async {
    final result = await _db.executePrepared(
      'SELECT * FROM ajustes WHERE status = (?) ORDER BY updated_at DESC',
      [status],
    );
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Ajuste>> getAll() async {
    final result = await _db.execute(
      'SELECT * FROM ajustes ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Ajuste.fromMap(r.typedAssoc())).toList();
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE ajustes SET status = ?, updated_at = ? WHERE id = ?',
      ['sent', now, id],
    );
  }

  /// Documento armazenado volta a rascunho como retificação;
  /// [documentoJson] já vem com `descritor.retificacao = true`.
  Future<void> iniciarRetificacao(int id, String documentoJson) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE ajustes SET status = ?, retificacao = 1, documento_json = ?, updated_at = ? WHERE id = ?',
      ['draft', documentoJson, now, id],
    );
  }

  /// Descarta a retificação: volta a "enviado" com o documento do envio
  /// armazenado e marca o momento, para os envios da retificação
  /// descartada deixarem de ser pendência.
  Future<void> descartarRetificacao(
    int id, {
    required String documentoJson,
    required bool retificacao,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE ajustes SET status = ?, retificacao = ?, documento_json = ?, retificacao_descartada_em = ?, updated_at = ? WHERE id = ?',
      ['sent', retificacao ? 1 : 0, documentoJson, now, now, id],
    );
  }

  Future<void> markAsDraft(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE ajustes SET status = ?, updated_at = ? WHERE id = ?',
      ['draft', now, id],
    );
  }

  Future<int> deleteById(int id) async {
    final result = await _db.executePrepared(
      'DELETE FROM ajustes WHERE id = ?',
      [id],
    );
    return result.affectedRows.toInt();
  }
}
