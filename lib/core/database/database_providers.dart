import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_service.dart';
import '../database/daos/users_dao.dart';
import '../database/daos/editais_dao.dart';
import '../database/daos/licitacoes_dao.dart';
import '../database/daos/atas_dao.dart';
import '../database/daos/ajustes_dao.dart';
import '../database/daos/api_logs_dao.dart';
import '../database/daos/app_settings_dao.dart';
import '../database/daos/estimativas_dao.dart';
import '../services/gemini_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final db = openConnection();
  unawaited(db.initialize());
  ref.onDispose(db.close);
  return db;
});

final usersDaoProvider = Provider<UsersDao>(
  (ref) => UsersDao(ref.watch(databaseServiceProvider)),
);

final editaisDaoProvider = Provider<EditaisDao>(
  (ref) => EditaisDao(ref.watch(databaseServiceProvider)),
);

final licitacoesDaoProvider = Provider<LicitacoesDao>(
  (ref) => LicitacoesDao(ref.watch(databaseServiceProvider)),
);

final atasDaoProvider = Provider<AtasDao>(
  (ref) => AtasDao(ref.watch(databaseServiceProvider)),
);

final ajustesDaoProvider = Provider<AjustesDao>(
  (ref) => AjustesDao(ref.watch(databaseServiceProvider)),
);

final apiLogsDaoProvider = Provider<ApiLogsDao>(
  (ref) => ApiLogsDao(ref.watch(databaseServiceProvider)),
);

final appSettingsDaoProvider = Provider<AppSettingsDao>(
  (ref) => AppSettingsDao(ref.watch(databaseServiceProvider)),
);

final estimativasDaoProvider = Provider<EstimativasDao>(
  (ref) => EstimativasDao(ref.watch(databaseServiceProvider)),
);

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(ref.watch(appSettingsDaoProvider)),
);

abstract class StringSettingNotifier extends Notifier<String> {
  String get settingsKey;

  AppSettingsDao get _dao => ref.read(appSettingsDaoProvider);

  @override
  String build() {
    _load();
    return '';
  }

  Future<void> _load() async {
    final v = await _dao.get(settingsKey);
    if (v != null) state = v;
  }

  Future<void> setValue(String v) async {
    if (v.isEmpty) {
      await _dao.delete(settingsKey);
    } else {
      await _dao.set(settingsKey, v);
    }
    state = v;
  }
}

class CodigoMunicipioNotifier extends StringSettingNotifier {
  @override
  String get settingsKey => SettingsKeys.codigoMunicipio;
}

class CodigoEntidadeNotifier extends StringSettingNotifier {
  @override
  String get settingsKey => SettingsKeys.codigoEntidade;
}

final codigoMunicipioProvider =
    NotifierProvider<CodigoMunicipioNotifier, String>(
  CodigoMunicipioNotifier.new,
);

final codigoEntidadeProvider =
    NotifierProvider<CodigoEntidadeNotifier, String>(
  CodigoEntidadeNotifier.new,
);
