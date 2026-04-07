import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Editais,
  Licitacoes,
  Atas,
  Ajustes,
  ApiLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(users, users.isAdmin);
      }
      if (from < 3) {
        await m.addColumn(users, users.passwordHash);
      }
      if (from < 4) {
        await customStatement('DROP TABLE IF EXISTS termos_contrato');
        await customStatement('DROP TABLE IF EXISTS empenhos');
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'audesp_api');
  }
}
