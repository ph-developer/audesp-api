import '../database_service.dart';
import '../models/pncp_compra.dart';

class PncpComprasDao {
  final DatabaseService _db;
  PncpComprasDao(this._db);

  Future<List<PncpCompra>> listAll() async {
    final result = await _db.execute(
      'SELECT * FROM pncp_compras ORDER BY ano DESC, sequencial DESC',
    );
    return result.rows.map((r) => PncpCompra.fromMap(r.typedAssoc())).toList();
  }

  Future<PncpCompra?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM pncp_compras WHERE id = (?)',
      [id],
    );
    final rows = result.rows;
    return rows.isEmpty ? null : PncpCompra.fromMap(rows.first.typedAssoc());
  }

  /// Insere a compra ou atualiza os dados vindos do PNCP, preservando a
  /// dispensa. Retorna true quando a compra ainda não existia.
  Future<bool> upsert(PncpCompra compra) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final result = await _db.executePrepared(
      'INSERT INTO pncp_compras (cnpj, ano, sequencial, numero_controle, '
      'modalidade_id, numero_compra, objeto, valor_total_estimado, '
      'data_publicacao, dados_json, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON DUPLICATE KEY UPDATE modalidade_id = VALUES(modalidade_id), '
      'numero_compra = VALUES(numero_compra), objeto = VALUES(objeto), '
      'valor_total_estimado = VALUES(valor_total_estimado), '
      'data_publicacao = VALUES(data_publicacao), '
      'dados_json = VALUES(dados_json), updated_at = VALUES(updated_at)',
      [
        compra.cnpj,
        compra.ano,
        compra.sequencial,
        compra.numeroControle,
        compra.modalidadeId,
        compra.numeroCompra,
        compra.objeto,
        compra.valorTotalEstimado,
        compra.dataPublicacao == null
            ? null
            : compra.dataPublicacao!.millisecondsSinceEpoch ~/ 1000,
        compra.dadosJson,
        now,
        now,
      ],
    );
    // MySQL informa 1 linha afetada na inserção e 2 na atualização.
    return result.affectedRows.toInt() == 1;
  }

  Future<void> dispensar(int id, {required int? userId, String? motivo}) async {
    await _db.executePrepared(
      'UPDATE pncp_compras SET dispensada_em = (?), dispensada_por = (?), '
      'motivo_dispensa = (?) WHERE id = (?)',
      [
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        userId,
        motivo == null || motivo.trim().isEmpty ? null : motivo.trim(),
        id,
      ],
    );
  }

  Future<void> restaurar(int id) async {
    await _db.executePrepared(
      'UPDATE pncp_compras SET dispensada_em = NULL, dispensada_por = NULL, '
      'motivo_dispensa = NULL WHERE id = (?)',
      [id],
    );
  }
}
