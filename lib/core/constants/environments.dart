import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_providers.dart';
import '../database/daos/app_settings_dao.dart';

/// Ambientes disponíveis para comunicação com a API AUDESP.
enum Environment { piloto, oficial }

extension EnvironmentExtension on Environment {
  String get label => switch (this) {
        Environment.piloto => 'Piloto',
        Environment.oficial => 'Oficial',
      };

  String get baseUrl => switch (this) {
        Environment.piloto => 'https://audesp-piloto.tce.sp.gov.br',
        Environment.oficial => 'https://audesp.tce.sp.gov.br',
      };
}

/// Provider global do ambiente ativo. O valor é persistido em [AppSettings].
final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, Environment>(
  (ref) => EnvironmentNotifier(ref.watch(appSettingsDaoProvider)),
);

class EnvironmentNotifier extends StateNotifier<Environment> {
  final AppSettingsDao _dao;

  EnvironmentNotifier(this._dao) : super(Environment.piloto) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _dao.get(SettingsKeys.environment);
    if (saved != null && mounted) {
      state = Environment.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => Environment.piloto,
      );
    }
  }

  Future<void> setEnvironment(Environment env) async {
    await _dao.set(SettingsKeys.environment, env.name);
    state = env;
  }
}
