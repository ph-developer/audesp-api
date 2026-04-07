import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  String? _bearerToken;

  String? get bearerToken => _bearerToken;

  bool get isAuthenticated => _bearerToken != null;

  /// Autentica no AUDESP via POST /login.
  /// Header: x-authorization = "email:password"
  /// Retorna o Bearer token e o armazena em memória (por sessão).
  Future<String> loginAudesp({
    required String email,
    required String password,
    required String baseUrl,
  }) async {
    final dio = Dio();
    final response = await dio.post(
      '$baseUrl/login',
      options: Options(
        headers: {'x-authorization': '$email:$password'},
      ),
    );
    final token = response.data['access_token'] as String;
    _bearerToken = token;
    return token;
  }

  void clearToken() {
    _bearerToken = null;
  }
}

