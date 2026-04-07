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
  Empenhos,
  TermosContrato,
  ApiLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(users, users.isAdmin);
      }
      if (from < 3) {
        await m.addColumn(users, users.passwordHash);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'audesp_api');
  }
}
