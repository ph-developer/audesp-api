import 'package:drift/drift.dart';

import '../app_database.dart';

class TermosContratoDao {
  final AppDatabase _db;
  TermosContratoDao(this._db);

  Stream<List<TermosContratoData>> watchByAjuste(int ajusteId) =>
      (_db.select(_db.termosContrato)
            ..where((t) => t.ajusteId.equals(ajusteId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<TermosContratoData?> findById(int id) =>
      (_db.select(_db.termosContrato)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTermo(TermosContratoCompanion entry) =>
      _db.into(_db.termosContrato).insert(entry);

  Future<bool> updateTermo(TermosContratoCompanion entry) =>
      _db.update(_db.termosContrato).replace(entry);

  Future<void> markAsSent(int id) async {
    await (_db.update(_db.termosContrato)..where((t) => t.id.equals(id))).write(
      TermosContratoCompanion(
        status: const Value('sent'),
      ),
    );
  }

  Future<int> deleteById(int id) =>
      (_db.delete(_db.termosContrato)..where((t) => t.id.equals(id))).go();
}
