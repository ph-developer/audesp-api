import 'package:mysql_client/mysql_client.dart';

import 'db_config_helper.dart';
import 'database_service.dart';

export 'models/user.dart';
export 'models/edital.dart';
export 'models/licitacoe.dart';
export 'models/ata.dart';
export 'models/ajuste.dart';
export 'models/api_log.dart';
export 'models/app_setting.dart';

DatabaseService openConnection() {
  final config = DbConfigHelper.loadConfigSync();

  final host = config?.get('MariaDB', 'Host') ?? 'localhost';
  final port =
      int.tryParse(config?.get('MariaDB', 'Port') ?? '3306') ?? 3306;
  final dbName = config?.get('MariaDB', 'Database') ?? 'audesp';
  final user = config?.get('MariaDB', 'User') ?? 'root';
  final password = config?.get('MariaDB', 'Password') ?? '';

  final pool = MySQLConnectionPool(
    host: host,
    port: port,
    userName: user,
    password: password,
    databaseName: dbName,
    maxConnections: 5,
  );

  return DatabaseService(pool);
}
