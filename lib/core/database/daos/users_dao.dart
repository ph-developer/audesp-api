import '../app_database.dart';

class UsersDao {
  final AppDatabase _db;
  UsersDao(this._db);

  Stream<List<User>> watchAll() => _db.select(_db.users).watch();

  Future<User?> findById(int id) =>
      (_db.select(_db.users)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<User?> findByEmail(String email) =>
      (_db.select(_db.users)..where((t) => t.email.equals(email)))
          .getSingleOrNull();

  Future<int> insertUser(UsersCompanion entry) =>
      _db.into(_db.users).insert(entry);

  Future<bool> updateUser(UsersCompanion entry) =>
      _db.update(_db.users).replace(entry);

  Future<int> deleteById(int id) =>
      (_db.delete(_db.users)..where((t) => t.id.equals(id))).go();
}
