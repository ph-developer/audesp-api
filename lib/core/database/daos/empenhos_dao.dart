import 'package:drift/drift.dart';

import '../app_database.dart';

class EmpenhosDao {
  final AppDatabase _db;
  EmpenhosDao(this._db);

  Stream<List<Empenho>> watchByAjuste(int ajusteId) =>
      (_db.select(_db.empenhos)
            ..where((t) => t.ajusteId.equals(ajusteId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<Empenho?> findById(int id) =>
      (_db.select(_db.empenhos)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertEmpenho(EmpenhosCompanion entry) =>
      _db.into(_db.empenhos).insert(entry);

  Future<bool> updateEmpenho(EmpenhosCompanion entry) =>
      _db.update(_db.empenhos).replace(entry);

  Future<void> markAsSent(int id) async {
    await (_db.update(_db.empenhos)..where((t) => t.id.equals(id))).write(
      EmpenhosCompanion(
        status: const Value('sent'),
      ),
    );
  }

  Future<int> deleteById(int id) =>
      (_db.delete(_db.empenhos)..where((t) => t.id.equals(id))).go();
}
