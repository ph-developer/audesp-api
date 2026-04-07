import 'package:drift/drift.dart';

import '../app_database.dart';

class EditaisDao {
  final AppDatabase _db;
  EditaisDao(this._db);

  Stream<List<Editai>> watchAll() =>
      (_db.select(_db.editais)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<Editai>> watchByStatus(String status) =>
      (_db.select(_db.editais)
            ..where((t) => t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<Editai?> findById(int id) =>
      (_db.select(_db.editais)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Editai?> findByCodigoEdital(
          String municipio, String entidade, String codigoEdital) =>
      (_db.select(_db.editais)
            ..where((t) =>
                t.municipio.equals(municipio) &
                t.entidade.equals(entidade) &
                t.codigoEdital.equals(codigoEdital)))
          .getSingleOrNull();

  Future<int> insertEdital(EditaisCompanion entry) =>
      _db.into(_db.editais).insert(entry);

  Future<bool> updateEdital(EditaisCompanion entry) =>
      _db.update(_db.editais).replace(entry);

  Future<int> deleteById(int id) =>
      (_db.delete(_db.editais)..where((t) => t.id.equals(id))).go();
}
