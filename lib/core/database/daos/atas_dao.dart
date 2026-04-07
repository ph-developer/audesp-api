import 'package:drift/drift.dart';

import '../app_database.dart';

class AtasDao {
  final AppDatabase _db;
  AtasDao(this._db);

  Stream<List<Ata>> watchAll() =>
      (_db.select(_db.atas)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<Ata>> watchByStatus(String status) =>
      (_db.select(_db.atas)
            ..where((t) => t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<Ata>> watchByEdital(int editalId) =>
      (_db.select(_db.atas)..where((t) => t.editalId.equals(editalId)))
          .watch();

  Future<Ata?> findById(int id) =>
      (_db.select(_db.atas)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Ata?> findByCodigoAta(
          String municipio, String entidade, String codigoAta) =>
      (_db.select(_db.atas)
            ..where((t) =>
                t.municipio.equals(municipio) &
                t.entidade.equals(entidade) &
                t.codigoAta.equals(codigoAta)))
          .getSingleOrNull();

  Future<int> insertAta(AtasCompanion entry) =>
      _db.into(_db.atas).insert(entry);

  Future<bool> updateAta(AtasCompanion entry) =>
      _db.update(_db.atas).replace(entry);

  Future<void> markAsSent(int id) async {
    await (_db.update(_db.atas)..where((t) => t.id.equals(id))).write(
      AtasCompanion(
        status: const Value('sent'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteById(int id) =>
      (_db.delete(_db.atas)..where((t) => t.id.equals(id))).go();
}
