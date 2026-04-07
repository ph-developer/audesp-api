import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Variáveis de ambiente carregadas do arquivo assets/.env.
/// Chamar [AppEnv.load] antes de [runApp].
class AppEnv {
  AppEnv._();

  static Future<void> load() => dotenv.load(fileName: 'assets/.env');

  /// Senha do usuário administrador definida no .env.
  static String get adminPassword =>
      dotenv.env['ADMIN_PASSWORD'] ?? 'admin@1234';

  /// Senha padrão atribuída a novos usuários criados pelo administrador.
  static String get defaultUserPassword =>
      dotenv.env['DEFAULT_USER_PASSWORD'] ?? 'Mudar@1234';
}
