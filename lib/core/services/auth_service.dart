import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  String? _bearerToken;

  String? get bearerToken => _bearerToken;

  bool get isAuthenticated => _bearerToken != null;

  /// Autentica no AUDESP e armazena o Bearer token em memória (por sessão).
  Future<void> login(String email, String password) async {
    // TODO: implementar POST de autenticação ao AUDESP
    _bearerToken = null;
  }

  void logout() {
    _bearerToken = null;
  }
}
