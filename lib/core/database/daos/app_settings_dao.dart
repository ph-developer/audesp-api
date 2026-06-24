import '../database_service.dart';

abstract class SettingsKeys {
  static const geminiApiKey = 'gemini_api_key';
  static const geminiModel = 'gemini_model';
  static const codigoMunicipio = 'codigo_municipio';
  static const codigoEntidade = 'codigo_entidade';
  static const environment = 'environment';
}

class AppSettingsDao {
  final DatabaseService _db;
  AppSettingsDao(this._db);

  Future<String?> get(String key) async {
    final stmt = await _db.pool.prepare(
      'SELECT value FROM app_settings WHERE `key` = (?)',
    );
    final result = await stmt.execute([key]);
    final rows = result.rows;
    return rows.isEmpty ? null : rows.first.typedAssoc()['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final stmt = await _db.pool.prepare(
      'INSERT INTO app_settings (`key`, `value`) VALUES (?, ?) '
      'ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)',
    );
    await stmt.execute([key, value]);
  }

  Future<void> delete(String key) async {
    final stmt = await _db.pool.prepare(
      'DELETE FROM app_settings WHERE `key` = (?)',
    );
    await stmt.execute([key]);
  }
}
