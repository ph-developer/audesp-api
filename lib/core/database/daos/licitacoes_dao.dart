import 'package:drift/drift.dart';

import '../app_database.dart';

class LicitacoesDao {
  final AppDatabase _db;
  LicitacoesDao(this._db);

  Stream<List<Licitacoe>> watchAll() =>
      (_db.select(_db.licitacoes)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Stream<List<Licitacoe>> watchByEdital(int editalId) =>
      (_db.select(_db.licitacoes)
            ..where((t) => t.editalId.equals(editalId)))
          .watch();

  Future<Licitacoe?> findById(int id) =>
      (_db.select(_db.licitacoes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertLicitacao(LicitacoesCompanion entry) =>
      _db.into(_db.licitacoes).insert(entry);

  Future<bool> updateLicitacao(LicitacoesCompanion entry) =>
      _db.update(_db.licitacoes).replace(entry);

  Future<int> deleteById(int id) =>
      (_db.delete(_db.licitacoes)..where((t) => t.id.equals(id))).go();
}
