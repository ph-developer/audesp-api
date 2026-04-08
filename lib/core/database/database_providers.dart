import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/users_dao.dart';
import '../database/daos/editais_dao.dart';
import '../database/daos/licitacoes_dao.dart';
import '../database/daos/atas_dao.dart';
import '../database/daos/ajustes_dao.dart';
import '../database/daos/api_logs_dao.dart';
import '../database/daos/app_settings_dao.dart';
import '../services/gemini_service.dart';

/// Instância única do banco de dados para toda a sessão do app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final usersDaoProvider = Provider<UsersDao>(
  (ref) => UsersDao(ref.watch(appDatabaseProvider)),
);

final editaisDaoProvider = Provider<EditaisDao>(
  (ref) => EditaisDao(ref.watch(appDatabaseProvider)),
);

final licitacoesDaoProvider = Provider<LicitacoesDao>(
  (ref) => LicitacoesDao(ref.watch(appDatabaseProvider)),
);

final atasDaoProvider = Provider<AtasDao>(
  (ref) => AtasDao(ref.watch(appDatabaseProvider)),
);

final ajustesDaoProvider = Provider<AjustesDao>(
  (ref) => AjustesDao(ref.watch(appDatabaseProvider)),
);

final apiLogsDaoProvider = Provider<ApiLogsDao>(
  (ref) => ApiLogsDao(ref.watch(appDatabaseProvider)),
);

final appSettingsDaoProvider = Provider<AppSettingsDao>(
  (ref) => AppSettingsDao(ref.watch(appDatabaseProvider)),
);

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(ref.watch(appSettingsDaoProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Configurações globais de texto (municipio, entidade)
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier genérico para configurações de texto persistidas em [AppSettings].
class StringSettingNotifier extends StateNotifier<String> {
  final AppSettingsDao _dao;
  final String _key;

  StringSettingNotifier(this._dao, this._key) : super('') {
    _load();
  }

  Future<void> _load() async {
    final v = await _dao.get(_key);
    if (v != null && mounted) state = v;
  }

  Future<void> setValue(String v) async {
    if (v.isEmpty) {
      await _dao.delete(_key);
    } else {
      await _dao.set(_key, v);
    }
    state = v;
  }
}

final codigoMunicipioProvider =
    StateNotifierProvider<StringSettingNotifier, String>(
  (ref) => StringSettingNotifier(
    ref.watch(appSettingsDaoProvider),
    SettingsKeys.codigoMunicipio,
  ),
);

final codigoEntidadeProvider =
    StateNotifierProvider<StringSettingNotifier, String>(
  (ref) => StringSettingNotifier(
    ref.watch(appSettingsDaoProvider),
    SettingsKeys.codigoEntidade,
  ),
);
