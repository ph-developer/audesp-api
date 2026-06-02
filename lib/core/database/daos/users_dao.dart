import '../app_database.dart';
import '../database_service.dart';

class UsersDao {
  final DatabaseService _db;
  UsersDao(this._db);

  Future<List<User>> watchAll() async {
    final result = await _db.pool.execute('SELECT * FROM users');
    return result.rows.map((r) => User.fromMap(r.typedAssoc())).toList();
  }

  Future<User?> findById(int id) async {
    final stmt =
        await _db.pool.prepare('SELECT * FROM users WHERE id = (?)');
    final result = await stmt.execute([id]);
    final rows = result.rows;
    return rows.isEmpty ? null : User.fromMap(rows.first.typedAssoc());
  }

  Future<User?> findByEmail(String email) async {
    final stmt =
        await _db.pool.prepare('SELECT * FROM users WHERE email = (?)');
    final result = await stmt.execute([email]);
    final rows = result.rows;
    return rows.isEmpty ? null : User.fromMap(rows.first.typedAssoc());
  }

  Future<int> countUsers() async {
    final result = await _db.pool.execute('SELECT COUNT(*) FROM users');
    return result.rows.first.typedAssoc()['COUNT(*)'] as int;
  }

  Future<int> insertUser({
    required String nome,
    required String email,
    String? passwordHash,
    DateTime? createdAt,
  }) async {
    final now = (createdAt ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final stmt = await _db.pool.prepare(
      'INSERT INTO users (nome, email, password_hash, created_at) VALUES (?, ?, ?, ?)',
    );
    final result = await stmt.execute([nome, email, passwordHash, now]);
    return result.lastInsertID.toInt();
  }

  Future<bool> updateUser({
    required int id,
    required String nome,
    required String email,
    String? passwordHash,
  }) async {
    final stmt = await _db.pool.prepare(
      'UPDATE users SET nome = ?, email = ?, password_hash = ? WHERE id = ?',
    );
    final result = await stmt.execute([nome, email, passwordHash, id]);
    return result.affectedRows.toInt() > 0;
  }

  Future<int> deleteById(int id) async {
    final stmt = await _db.pool.prepare('DELETE FROM users WHERE id = ?');
    final result = await stmt.execute([id]);
    return result.affectedRows.toInt();
  }

  Future<void> setPasswordHash(int userId, String hash) async {
    final stmt =
        await _db.pool.prepare('UPDATE users SET password_hash = ? WHERE id = ?');
    await stmt.execute([hash, userId]);
  }
}
