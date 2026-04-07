import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/users_dao.dart';
import '../database/daos/editais_dao.dart';
import '../database/daos/licitacoes_dao.dart';
import '../database/daos/atas_dao.dart';
import '../database/daos/ajustes_dao.dart';
import '../database/daos/api_logs_dao.dart';

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
