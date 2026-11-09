import '../database_service.dart';
import '../models/pncp_contrato.dart';

class PncpContratosDao {
  final DatabaseService _db;
  PncpContratosDao(this._db);

  Future<List<PncpContrato>> listAll() async {
    final result = await _db.execute(
      'SELECT * FROM pncp_contratos ORDER BY ano DESC, sequencial DESC',
    );
    return result.rows
        .map((r) => PncpContrato.fromMap(r.typedAssoc()))
        .toList();
  }

  Future<PncpContrato?> findById(int id) async {
    final result = await _db.executePrepared(
      'SELECT * FROM pncp_contratos WHERE id = (?)',
      [id],
    );
    return result.rows.isEmpty
        ? null
        : PncpContrato.fromMap(result.rows.first.typedAssoc());
  }

  /// Atualiza os dados do PNCP sem alterar a dispensa nem a data de criação.
  /// MySQL informa 1 linha afetada na inserção e 2 na atualização.
  Future<bool> upsert(PncpContrato contrato) async {
    final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final result = await _db.executePrepared(
      'INSERT INTO pncp_contratos (cnpj, ano, sequencial, numero_controle, '
      'numero_controle_compra, numero_controle_ata, fruto_adesao, '
      'numero_contrato, tipo_contrato_id, ni_fornecedor, nome_fornecedor, '
      'objeto, valor_global, data_assinatura, vigencia_inicio, vigencia_fim, '
      'data_publicacao, dados_json, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON DUPLICATE KEY UPDATE numero_controle = VALUES(numero_controle), '
      'numero_controle_compra = VALUES(numero_controle_compra), '
      'numero_controle_ata = VALUES(numero_controle_ata), '
      'fruto_adesao = VALUES(fruto_adesao), numero_contrato = VALUES(numero_contrato), '
      'tipo_contrato_id = VALUES(tipo_contrato_id), ni_fornecedor = VALUES(ni_fornecedor), '
      'nome_fornecedor = VALUES(nome_fornecedor), objeto = VALUES(objeto), '
      'valor_global = VALUES(valor_global), data_assinatura = VALUES(data_assinatura), '
      'vigencia_inicio = VALUES(vigencia_inicio), vigencia_fim = VALUES(vigencia_fim), '
      'data_publicacao = VALUES(data_publicacao), dados_json = VALUES(dados_json), '
      'updated_at = VALUES(updated_at)',
      [
        contrato.cnpj,
        contrato.ano,
        contrato.sequencial,
        contrato.numeroControle,
        contrato.numeroControleCompra,
        contrato.numeroControleAta,
        contrato.frutoAdesao ? 1 : 0,
        contrato.numeroContrato,
        contrato.tipoContratoId,
        contrato.niFornecedor,
        contrato.nomeFornecedor,
        contrato.objeto,
        contrato.valorGlobal,
        _epoch(contrato.dataAssinatura),
        _epoch(contrato.vigenciaInicio),
        _epoch(contrato.vigenciaFim),
        _epoch(contrato.dataPublicacao),
        contrato.dadosJson,
        agora,
        agora,
      ],
    );
    return result.affectedRows.toInt() == 1;
  }

  Future<void> dispensar(int id, {required int? userId, String? motivo}) async {
    final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.executePrepared(
      'UPDATE pncp_contratos SET dispensada_em = (?), dispensada_por = (?), '
      'motivo_dispensa = (?), updated_at = (?) WHERE id = (?)',
      [
        agora,
        userId,
        motivo == null || motivo.trim().isEmpty ? null : motivo.trim(),
        agora,
        id,
      ],
    );
  }

  Future<void> restaurar(int id) async {
    await _db.executePrepared(
      'UPDATE pncp_contratos SET dispensada_em = NULL, dispensada_por = NULL, '
      'motivo_dispensa = NULL, updated_at = (?) WHERE id = (?)',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, id],
    );
  }

  static int? _epoch(DateTime? data) =>
      data == null ? null : data.millisecondsSinceEpoch ~/ 1000;
}
