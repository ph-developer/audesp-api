import 'package:drift/drift.dart';

import '../app_database.dart';

class AjustesDao {
  final AppDatabase _db;
  AjustesDao(this._db);

  Stream<List<Ajuste>> watchAll() =>
      (_db.select(_db.ajustes)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<Ajuste>> watchByEdital(int editalId) =>
      (_db.select(_db.ajustes)
            ..where((t) => t.editalId.equals(editalId)))
          .watch();

  Stream<List<Ajuste>> watchByAta(int ataId) =>
      (_db.select(_db.ajustes)
            ..where((t) => t.ataId.equals(ataId)))
          .watch();

  Future<Ajuste?> findById(int id) =>
      (_db.select(_db.ajustes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertAjuste(AjustesCompanion entry) =>
      _db.into(_db.ajustes).insert(entry);

  Future<bool> updateAjuste(AjustesCompanion entry) =>
      _db.update(_db.ajustes).replace(entry);

  Stream<List<Ajuste>> watchByStatus(String status) =>
      (_db.select(_db.ajustes)
            ..where((t) => t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<Ajuste>> getAll() =>
      (_db.select(_db.ajustes)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<void> markAsSent(int id) async {
    await (_db.update(_db.ajustes)..where((t) => t.id.equals(id))).write(
      AjustesCompanion(
        status: const Value('sent'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteById(int id) =>
      (_db.delete(_db.ajustes)..where((t) => t.id.equals(id))).go();
}
