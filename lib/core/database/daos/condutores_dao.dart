import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/licitacao/models/condutor.dart';
import '../database_service.dart';
import '../database_providers.dart';

final condutoresDaoProvider = Provider<CondutoresDao>((ref) {
  return CondutoresDao(ref.watch(databaseServiceProvider));
});

class CondutoresDao {
  final DatabaseService db;

  CondutoresDao(this.db);

  Future<List<Condutor>> getAll() async {
    final result = await db.execute(
      'SELECT id, nome, cpf FROM condutores ORDER BY nome ASC',
    );
    return result.rows
        .map((row) => Condutor.fromMap(row.typedAssoc()))
        .toList();
  }

  Future<Condutor> insert(String nome, String cpf) async {
    final result = await db.execute(
      'INSERT INTO condutores (nome, cpf) VALUES (:nome, :cpf)',
      {'nome': nome, 'cpf': cpf},
    );
    final id = result.lastInsertID.toInt();
    return Condutor(id: id, nome: nome, cpf: cpf);
  }

  Future<void> delete(int id) async {
    await db.execute('DELETE FROM condutores WHERE id = :id', {'id': id});
  }
}
