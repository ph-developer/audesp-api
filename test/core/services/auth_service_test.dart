import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/core/services/api_service.dart';
import 'package:audesp_api/core/services/auth_service.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/processo/processo_fixtures.dart';
import '../../helpers/json_http_adapter.dart';

class _MemorySettings implements AppSettingsDao {
  final values = <String, String>{};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final agora = DateTime.utc(2026, 10, 28, 12);
  final baseUrl = Environment.piloto.baseUrl;
  late JsonHttpAdapter adapter;
  late AuthService auth;

  Future<String> login() => auth.loginAudesp(
    userId: 1,
    email: 'teste@example.com',
    password: 'senha-teste',
    baseUrl: baseUrl,
  );

  String? valido({DateTime? instante, int userId = 1, String? ambiente}) =>
      auth.tokenValido(
        userId: userId,
        baseUrl: ambiente ?? baseUrl,
        agora: instante,
      );

  setUp(() {
    adapter = JsonHttpAdapter({
      'access_token': 'token-teste',
      'expire_in': 3600,
    });
    final dio = Dio()..httpClientAdapter = adapter;
    auth = AuthService(dio: dio, agora: () => agora);
    addTearDown(() => dio.close(force: true));
  });

  test('sem login não há token válido', () {
    expect(auth.bearerToken, isNull);
    expect(auth.isAuthenticated, isFalse);
    expect(valido(), isNull);
  });

  test(
    'login associa token ao usuário e ambiente e envia credenciais no header',
    () async {
      expect(await login(), 'token-teste');
      expect(auth.bearerToken, 'token-teste');
      expect(auth.isAuthenticated, isTrue);
      expect(valido(), 'token-teste');
      expect(valido(userId: 2), isNull);
      expect(valido(ambiente: Environment.oficial.baseUrl), isNull);
      expect(adapter.requests.single.uri.toString(), '$baseUrl/login');
      expect(
        adapter.requests.single.headers['x-authorization'],
        'teste@example.com:senha-teste',
      );
    },
  );

  test('expire_in relativo parte do instante de login', () async {
    await login();
    expect(auth.expiraEm, agora.add(const Duration(hours: 1)));
  });

  test('expire_in maior que 1e9 é epoch em segundos', () async {
    final vencimento = agora.add(const Duration(hours: 2));
    adapter.data['expire_in'] = vencimento.millisecondsSinceEpoch ~/ 1000;
    await login();
    expect(auth.expiraEm, vencimento);
    expect(valido(), 'token-teste');
  });

  test('token não é reutilizado se expira nos próximos 60 segundos', () async {
    await login();
    final vencimento = auth.expiraEm!;
    expect(
      valido(instante: vencimento.subtract(const Duration(seconds: 61))),
      'token-teste',
    );
    expect(
      valido(instante: vencimento.subtract(const Duration(seconds: 60))),
      isNull,
    );
    expect(
      valido(instante: vencimento.subtract(const Duration(seconds: 59))),
      isNull,
    );
    expect(valido(instante: vencimento), isNull);
    expect(
      valido(instante: vencimento.add(const Duration(seconds: 1))),
      isNull,
    );
  });

  test('sem expire_in permanece válido até ser limpo', () async {
    adapter.data.remove('expire_in');
    await login();
    expect(auth.expiraEm, isNull);
    expect(valido(instante: DateTime.utc(2030)), 'token-teste');
    expect(valido(userId: 2), isNull);
    expect(valido(ambiente: Environment.oficial.baseUrl), isNull);
  });

  test('clearToken remove token e expiração e permite novo login', () async {
    await login();
    auth.clearToken();
    expect(auth.bearerToken, isNull);
    expect(auth.expiraEm, isNull);
    expect(auth.isAuthenticated, isFalse);
    expect(valido(), isNull);
    adapter.data = {'access_token': 'novo-token'};
    await login();
    expect(valido(), 'novo-token');
    expect(auth.expiraEm, isNull);
  });

  for (final statusCode in [401, 403, 500]) {
    test('ApiService repassa erro $statusCode e limpa apenas no 401', () async {
      await login();
      final api = ApiService(auth);
      final apiAdapter = JsonHttpAdapter({}, statusCode: statusCode);
      api.dio.httpClientAdapter = apiAdapter;
      addTearDown(() => api.dio.close(force: true));
      await expectLater(
        api.dio.get('$baseUrl/teste'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );
      expect(
        apiAdapter.requests.single.headers['Authorization'],
        'Bearer token-teste',
      );
      expect(auth.bearerToken, statusCode == 401 ? isNull : 'token-teste');
    });
  }

  test('logout limpa a sessão AUDESP', () async {
    await login();
    final container = ProviderContainer.test(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    container.read(localSessionProvider.notifier).login(usuarioFixture());
    container.read(localSessionProvider.notifier).logout();
    expect(container.read(localSessionProvider), isNull);
    expect(auth.bearerToken, isNull);
  });

  test('trocar ambiente persiste o destino e limpa o token', () async {
    await login();
    final settings = _MemorySettings();
    final container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        appSettingsDaoProvider.overrideWithValue(settings),
      ],
    );
    await container
        .read(environmentProvider.notifier)
        .setEnvironment(Environment.oficial);
    expect(container.read(environmentProvider), Environment.oficial);
    expect(settings.values[SettingsKeys.environment], 'oficial');
    expect(auth.bearerToken, isNull);
  });
}
