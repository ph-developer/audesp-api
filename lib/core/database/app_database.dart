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
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy();

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'audesp_api');
  }
}
