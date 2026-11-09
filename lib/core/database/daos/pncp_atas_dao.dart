import '../database_service.dart';
import '../models/pncp_ata.dart';

class PncpAtasDao {
  final DatabaseService _db;
  PncpAtasDao(this._db);

  Future<List<PncpAta>> listAll() async {
    final result = await _db.execute(
      'SELECT * FROM pncp_atas ORDER BY ano_compra DESC, sequencial_compra DESC, sequencial_ata DESC',
    );
    return result.rows.map((r) => PncpAta.fromMap(r.typedAssoc())).toList();
  }

  Future<PncpAta?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM pncp_atas WHERE id = (?)',
      [id],
    );
    return result.rows.isEmpty
        ? null
        : PncpAta.fromMap(result.rows.first.typedAssoc());
  }

  /// Atualiza inclusive cancelamento e vigência, preservando a dispensa.
  /// MySQL informa 1 linha afetada na inserção e 2 na atualização.
  Future<bool> upsert(PncpAta ata) async {
    final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final result = await _db.executePrepared(
      'INSERT INTO pncp_atas (cnpj, ano_compra, sequencial_compra, sequencial_ata, '
      'numero_controle, numero_controle_compra, numero_ata, ano_ata, cancelada, '
      'data_cancelamento, data_assinatura, vigencia_inicio, vigencia_fim, '
      'data_publicacao, objeto, dados_json, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON DUPLICATE KEY UPDATE cnpj = VALUES(cnpj), ano_compra = VALUES(ano_compra), '
      'sequencial_compra = VALUES(sequencial_compra), sequencial_ata = VALUES(sequencial_ata), '
      'numero_controle_compra = VALUES(numero_controle_compra), numero_ata = VALUES(numero_ata), '
      'ano_ata = VALUES(ano_ata), cancelada = VALUES(cancelada), '
      'data_cancelamento = VALUES(data_cancelamento), data_assinatura = VALUES(data_assinatura), '
      'vigencia_inicio = VALUES(vigencia_inicio), vigencia_fim = VALUES(vigencia_fim), '
      'data_publicacao = VALUES(data_publicacao), objeto = VALUES(objeto), '
      'dados_json = VALUES(dados_json), updated_at = VALUES(updated_at)',
      [
        ata.cnpj,
        ata.anoCompra,
        ata.sequencialCompra,
        ata.sequencialAta,
        ata.numeroControle,
        ata.numeroControleCompra,
        ata.numeroAta,
        ata.anoAta,
        ata.cancelada ? 1 : 0,
        _epoch(ata.dataCancelamento),
        _epoch(ata.dataAssinatura),
        _epoch(ata.vigenciaInicio),
        _epoch(ata.vigenciaFim),
        _epoch(ata.dataPublicacao),
        ata.objeto,
        ata.dadosJson,
        agora,
        agora,
      ],
    );
    return result.affectedRows.toInt() == 1;
  }

  Future<void> dispensar(int id, {int? userId, String? motivo}) async {
    final texto = motivo?.trim();
    await _db.executePrepared(
      'UPDATE pncp_atas SET dispensada_em = (?), dispensada_por = (?), motivo_dispensa = (?) WHERE id = (?)',
      [
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        userId,
        texto == null || texto.isEmpty ? null : texto,
        id,
      ],
    );
  }

  Future<void> restaurar(int id) async {
    await _db.executePrepared(
      'UPDATE pncp_atas SET dispensada_em = NULL, dispensada_por = NULL, motivo_dispensa = NULL WHERE id = (?)',
      [id],
    );
  }

  static int? _epoch(DateTime? data) =>
      data == null ? null : data.millisecondsSinceEpoch ~/ 1000;
}
