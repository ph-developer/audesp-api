import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final Dio _dio;
  final DateTime Function() _agora;
  String? _bearerToken;
  int? _userId;
  String? _baseUrl;
  DateTime? _expiraEm;

  AuthService({Dio? dio, DateTime Function()? agora})
    : _dio = dio ?? Dio(),
      _agora = agora ?? DateTime.now;

  String? get bearerToken => _bearerToken;
  DateTime? get expiraEm => _expiraEm;

  bool get isAuthenticated => _bearerToken != null;

  String? tokenValido({
    required int userId,
    required String baseUrl,
    DateTime? agora,
  }) {
    if (_userId != userId || _baseUrl != baseUrl) return null;
    final limite = (agora ?? _agora()).add(const Duration(seconds: 60));
    if (_expiraEm != null && !_expiraEm!.isAfter(limite)) return null;
    return _bearerToken;
  }

  /// Autentica no AUDESP via POST /login.
  /// Header: x-authorization = "email:password"
  /// Retorna o Bearer token e o armazena em memória (por sessão).
  Future<String> loginAudesp({
    required int userId,
    required String email,
    required String password,
    required String baseUrl,
  }) async {
    clearToken();
    final response = await _dio.post(
      '$baseUrl/login',
      options: Options(headers: {'x-authorization': '$email:$password'}),
    );
    final token = response.data['access_token'] as String;
    final valor = response.data['expire_in'];
    final segundos = valor is num ? valor : num.tryParse('$valor');
    _expiraEm = segundos == null
        ? null
        : segundos > 1e9
        ? DateTime.fromMillisecondsSinceEpoch(
            (segundos * 1000).toInt(),
            isUtc: true,
          )
        : _agora().add(Duration(milliseconds: (segundos * 1000).toInt()));
    _bearerToken = token;
    _userId = userId;
    _baseUrl = baseUrl;
    return token;
  }

  void clearToken() {
    _bearerToken = null;
    _userId = null;
    _baseUrl = null;
    _expiraEm = null;
  }
}
