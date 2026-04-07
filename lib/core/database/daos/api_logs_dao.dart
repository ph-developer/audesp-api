import 'package:drift/drift.dart';

import '../app_database.dart';

class ApiLogsDao {
  final AppDatabase _db;
  ApiLogsDao(this._db);

  Stream<List<ApiLog>> watchAll() =>
      (_db.select(_db.apiLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Stream<List<ApiLog>> watchByEndpoint(String endpoint) =>
      (_db.select(_db.apiLogs)
            ..where((t) => t.endpoint.equals(endpoint))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Stream<List<ApiLog>> watchByUser(int userId) =>
      (_db.select(_db.apiLogs)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .watch();

  Future<ApiLog?> findById(int id) =>
      (_db.select(_db.apiLogs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertLog(ApiLogsCompanion entry) =>
      _db.into(_db.apiLogs).insert(entry);

  Future<int> deleteById(int id) =>
      (_db.delete(_db.apiLogs)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.apiLogs).go();
}
