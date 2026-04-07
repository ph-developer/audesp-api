import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Utilitário para hash e verificação da senha do sistema (login local).
/// Usa SHA-256 com email + pepper como entrada, evitando colisões entre usuários.
class PasswordHasher {
  PasswordHasher._();

  static const _pepper = 'audesp_api_sys_2026';

  /// Retorna o hash SHA-256 em formato hexadecimal.
  static String hash(String email, String password) {
    final input = '${email.toLowerCase()}:$password:$_pepper';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Verifica se [password] corresponde ao [storedHash].
  static bool verify(String email, String password, String storedHash) {
    return hash(email, password) == storedHash;
  }
}
