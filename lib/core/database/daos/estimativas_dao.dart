import 'dart:convert';
import '../database_service.dart';
import '../../../features/estimativa/models/estimativa_model.dart';

class EstimativasDao {
  final DatabaseService _db;
  EstimativasDao(this._db);

  Future<List<EstimativaModel>> watchAll() async {
    final result = await _db.pool.execute(
      'SELECT * FROM estimativas ORDER BY ano DESC, numero DESC',
    );
    return result.rows.map((r) {
      final map = r.typedAssoc();
      final id = map['id'] as int;
      final numero = map['numero'] as int;
      final ano = map['ano'] as int;
      final objeto = map['objeto'] as String;
      final jsonStr = map['documento_json'] as String;
      final createdAt = map['created_at'] as int;
      final updatedAt = map['updated_at'] as int;

      Map<String, dynamic> jsonMap = {};
      try {
        jsonMap = jsonDecode(jsonStr);
      } catch (_) {}

      // Retorna uma nova instância incorporando o id real e dados do banco
      return EstimativaModel.fromMap(jsonMap).copyWith(
        id: id,
        numero: numero,
        ano: ano,
        objeto: objeto,
        status: map['status'] as String,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }).toList();
  }

  /// Só as colunas, sem o documento: itens, lotes e fornecedores vêm vazios.
  Future<List<EstimativaModel>> listResumo() async {
    final result = await _db.pool.execute(
      'SELECT id, numero, ano, objeto, status, created_at, updated_at '
      'FROM estimativas ORDER BY ano DESC, numero DESC',
    );
    return result.rows.map((r) {
      final map = r.typedAssoc();
      return EstimativaModel(
        id: map['id'] as int,
        numero: map['numero'] as int,
        ano: map['ano'] as int,
        objeto: map['objeto'] as String,
        status: map['status'] as String,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
    }).toList();
  }

  Future<EstimativaModel?> findById(int id) async {
    final stmt = await _db.pool.prepare(
      'SELECT * FROM estimativas WHERE id = (?)',
    );
    final result = await stmt.execute([id]);
    final rows = result.rows;
    if (rows.isEmpty) return null;

    final map = rows.first.typedAssoc();
    final numero = map['numero'] as int;
    final ano = map['ano'] as int;
    final objeto = map['objeto'] as String;
    final jsonStr = map['documento_json'] as String;
    final createdAt = map['created_at'] as int;
    final updatedAt = map['updated_at'] as int;

    Map<String, dynamic> jsonMap = {};
    try {
      jsonMap = jsonDecode(jsonStr);
    } catch (_) {}

    return EstimativaModel.fromMap(jsonMap).copyWith(
      id: id,
      numero: numero,
      ano: ano,
      objeto: objeto,
      status: map['status'] as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<int> getNextNumero(int ano) async {
    final stmt = await _db.pool.prepare(
      'SELECT MAX(numero) as max_num FROM estimativas WHERE ano = ?',
    );
    final result = await stmt.execute([ano]);
    final rows = result.rows;
    if (rows.isEmpty || rows.first.typedAssoc()['max_num'] == null) {
      return 1;
    }
    return (rows.first.typedAssoc()['max_num'] as int) + 1;
  }

  Future<int> insertEstimativa(EstimativaModel estimativa) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Obter o próximo número do ano caso não tenha (ex: numero == 0)
    int numero = estimativa.numero;
    int ano = estimativa.ano;
    if (ano == 0) {
      ano = DateTime.now().year;
    }
    if (numero == 0) {
      numero = await getNextNumero(ano);
    }

    final estimativaToSave = estimativa.copyWith(
      numero: numero,
      ano: ano,
      createdAt: now,
      updatedAt: now,
    );
    final jsonStr = jsonEncode(estimativaToSave.toMap());

    final stmt = await _db.pool.prepare(
      'INSERT INTO estimativas (numero, ano, objeto, status, documento_json, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    );
    final result = await stmt.execute([
      numero,
      ano,
      estimativaToSave.objeto,
      EstimativaStatus.rascunho,
      jsonStr,
      now,
      now,
    ]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateEstimativa(EstimativaModel estimativa) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final estimativaToSave = estimativa.copyWith(updatedAt: now);
    final jsonStr = jsonEncode(estimativaToSave.toMap());

    final stmt = await _db.pool.prepare(
      'UPDATE estimativas SET numero = ?, ano = ?, objeto = ?, documento_json = ?, updated_at = ? WHERE id = ?',
    );
    final result = await stmt.execute([
      estimativaToSave.numero,
      estimativaToSave.ano,
      estimativaToSave.objeto,
      jsonStr,
      now,
      estimativa.id,
    ]);
    return result.affectedRows.toInt() > 0;
  }

  Future<void> setStatus(int id, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'UPDATE estimativas SET status = ?, updated_at = ? WHERE id = ?',
    );
    await stmt.execute([status, now, id]);
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM estimativas WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }

  Future<bool> checkNumeroExists(int numero, int ano, {int? excludeId}) async {
    if (excludeId != null && excludeId > 0) {
      final stmt = await _db.pool.prepare(
        'SELECT 1 FROM estimativas WHERE numero = ? AND ano = ? AND id != ? LIMIT 1',
      );
      final result = await stmt.execute([numero, ano, excludeId]);
      return result.rows.isNotEmpty;
    } else {
      final stmt = await _db.pool.prepare(
        'SELECT 1 FROM estimativas WHERE numero = ? AND ano = ? LIMIT 1',
      );
      final result = await stmt.execute([numero, ano]);
      return result.rows.isNotEmpty;
    }
  }
}
