import '../app_database.dart';
import '../database_service.dart';

class LicitacoesDao {
  final DatabaseService _db;
  LicitacoesDao(this._db);

  Future<List<Licitacao>> watchAll() async {
    final result = await _db.execute(
      'SELECT * FROM licitacoes ORDER BY updated_at DESC',
    );
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Licitacao>> watchByStatus(String status) async {
    final result = await _db.executePrepared(
      'SELECT * FROM licitacoes WHERE status = (?) ORDER BY updated_at DESC',
      [status],
    );
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<List<Licitacao>> watchByEdital(int editalId) async {
    final result = await _db.executePrepared(
      'SELECT * FROM licitacoes WHERE edital_id = (?) ORDER BY updated_at DESC',
      [editalId],
    );
    return result.rows.map((r) => Licitacao.fromMap(r.typedAssoc())).toList();
  }

  Future<Licitacao?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM licitacoes WHERE id = (?)',
      [id],
    );
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
    final result = await _db.executePrepared(
      'INSERT INTO licitacoes (edital_id, municipio, entidade, codigo_edital, retificacao, status, documento_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        editalId,
        municipio,
        entidade,
        codigoEdital,
        retificacao ? 1 : 0,
        status,
        documentoJson,
        now,
      ],
    );
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
    final result = await _db.executePrepared(
      'UPDATE licitacoes SET edital_id = ?, municipio = ?, entidade = ?, codigo_edital = ?, retificacao = ?, status = ?, documento_json = ?, updated_at = ? WHERE id = ?',
      [
        editalId,
        municipio,
        entidade,
        codigoEdital,
        retificacao ? 1 : 0,
        status,
        documentoJson,
        now,
        id,
      ],
    );
    return result.affectedRows.toInt() > 0;
  }

  Future<void> markAsSent(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE licitacoes SET status = ?, updated_at = ? WHERE id = ?',
      ['sent', now, id],
    );
  }

  /// Documento armazenado volta a rascunho como retificação;
  /// [documentoJson] já vem com `descritor.retificacao = true`.
  Future<void> iniciarRetificacao(int id, String documentoJson) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE licitacoes SET status = ?, retificacao = 1, documento_json = ?, updated_at = ? WHERE id = ?',
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
      'UPDATE licitacoes SET status = ?, retificacao = ?, documento_json = ?, retificacao_descartada_em = ?, updated_at = ? WHERE id = ?',
      ['sent', retificacao ? 1 : 0, documentoJson, now, now, id],
    );
  }

  Future<void> markAsDraft(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE licitacoes SET status = ?, updated_at = ? WHERE id = ?',
      ['draft', now, id],
    );
  }

  Future<void> updateJson(int id, String json) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE licitacoes SET documento_json = ?, updated_at = ? WHERE id = ?',
      [json, now, id],
    );
  }

  Future<int> deleteById(int id) async {
    final result = await _db.executePrepared(
      'DELETE FROM licitacoes WHERE id = ?',
      [id],
    );
    return result.affectedRows.toInt();
  }
}
