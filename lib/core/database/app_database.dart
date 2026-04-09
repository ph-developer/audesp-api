import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'db_config_helper.dart';
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
    return LazyDatabase(() async {
      final dbPath = await DbConfigHelper.getDatabasePath();
      final file = File(dbPath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      return NativeDatabase.createInBackground(file);
    });
  }
}
