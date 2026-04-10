import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

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
      final config = await DbConfigHelper.loadConfig();
      final driver = config?.get('Database', 'Driver')?.toLowerCase() ?? 'sqlite';

      if (driver == 'postgres') {
        final host = config?.get('Postgres', 'Host') ?? 'localhost';
        final port = int.tryParse(config?.get('Postgres', 'Port') ?? '5432') ?? 5432;
        final dbName = config?.get('Postgres', 'Database') ?? 'audesp';
        final user = config?.get('Postgres', 'User') ?? 'postgres';
        final password = config?.get('Postgres', 'Password') ?? '';

        return PgDatabase(
          endpoint: Endpoint(
            host: host,
            port: port,
            database: dbName,
            username: user,
            password: password,
          ),
        );
      }

      final dbPath = await DbConfigHelper.getSqlitePath(config);
      final file = File(dbPath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      return NativeDatabase.createInBackground(
        file,
        setup: (db) async {
          db.execute('PRAGMA busy_timeout = 10000;');
        },
      );
    });
  }
}
