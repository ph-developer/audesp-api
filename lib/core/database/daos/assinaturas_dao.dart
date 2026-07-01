import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/estimativa/models/assinatura_model.dart';
import '../database_service.dart';
import '../database_providers.dart';

final assinaturasDaoProvider = Provider<AssinaturasDao>((ref) {
  return AssinaturasDao(ref.watch(databaseServiceProvider));
});

class AssinaturasDao {
  final DatabaseService db;

  AssinaturasDao(this.db);

  Future<List<AssinaturaModel>> getAll() async {
    final result = await db.pool.execute(
      'SELECT * FROM assinaturas_predefinidas ORDER BY nome ASC'
    );
    return result.rows.map((row) {
      final map = row.typedAssoc();
      return AssinaturaModel.fromMap(map);
    }).toList();
  }

  Future<AssinaturaModel> insert(String nome, String cargo) async {
    final result = await db.pool.execute(
      'INSERT INTO assinaturas_predefinidas (nome, cargo) VALUES (:nome, :cargo)',
      {
        'nome': nome,
        'cargo': cargo,
      }
    );
    final id = result.lastInsertID.toInt();
    return AssinaturaModel(id: id, nome: nome, cargo: cargo);
  }

  Future<void> delete(int id) async {
    await db.pool.execute(
      'DELETE FROM assinaturas_predefinidas WHERE id = :id',
      {'id': id}
    );
  }
}
