import 'package:drift/drift.dart';

import '../app_database.dart';

/// Chaves conhecidas usadas em [AppSettings].
abstract class SettingsKeys {
  static const geminiApiKey = 'gemini_api_key';
  static const geminiModel = 'gemini_model';
}

class AppSettingsDao {
  final AppDatabase _db;
  AppSettingsDao(this._db);

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(AppSettingsCompanion(
          key: Value(key),
          value: Value(value),
        ));
  }

  Future<void> delete(String key) async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
  }
}
