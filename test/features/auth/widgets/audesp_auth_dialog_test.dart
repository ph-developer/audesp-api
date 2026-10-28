import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/services/api_service.dart';
import 'package:audesp_api/core/services/auth_service.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/auth/widgets/audesp_auth_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/json_http_adapter.dart';
import '../../processo/processo_fixtures.dart';

class _TestSession extends LocalSessionNotifier {
  @override
  build() => usuarioFixture();
}

class _TestEnvironment extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;
}

Future<void> _pumpDialog(
  WidgetTester tester,
  AuthService auth, {
  required Future<void> Function(String token) onConfirm,
  String actionLabel = 'Autenticar e enviar',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        localSessionProvider.overrideWith(_TestSession.new),
        environmentProvider.overrideWith(_TestEnvironment.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () => showAudespAuthDialog(
                  context,
                  ref,
                  onConfirm: onConfirm,
                  actionLabel: actionLabel,
                ),
                child: const Text('Abrir confirmação'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir confirmação'));
  await tester.pumpAndSettle();
}

void main() {
  late AuthService auth;
  late JsonHttpAdapter adapter;

  Future<void> login() async {
    await auth.loginAudesp(
      userId: 1,
      email: 'teste@example.com',
      password: 'senha-teste',
      baseUrl: Environment.piloto.baseUrl,
    );
  }

  setUp(() {
    adapter = JsonHttpAdapter({
      'access_token': 'token-teste',
      'expire_in': 3600,
    });
    final dio = Dio()..httpClientAdapter = adapter;
    auth = AuthService(dio: dio, agora: () => DateTime(2026, 10, 28, 12));
    addTearDown(() => dio.close(force: true));
  });

  testWidgets('sem sessão exige senha, autentica e confirma o envio', (
    tester,
  ) async {
    String? tokenEnviado;
    await _pumpDialog(
      tester,
      auth,
      onConfirm: (token) async => tokenEnviado = token,
    );
    expect(find.text('Senha AUDESP'), findsOneWidget);
    expect(find.text('Sessão AUDESP ativa'), findsNothing);
    expect(find.text('Usuário de teste'), findsOneWidget);
    expect(find.text('Piloto'), findsOneWidget);
    expect(adapter.requests, isEmpty);
    await tester.tap(find.text('Autenticar e enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe a senha do AUDESP.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'senha-teste');
    await tester.tap(find.text('Autenticar e enviar'));
    await tester.pumpAndSettle();
    expect(tokenEnviado, 'token-teste');
    expect(adapter.requests, hasLength(1));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('sessão válida mantém confirmação sem senha nem novo login', (
    tester,
  ) async {
    await tester.runAsync(login);
    String? tokenEnviado;
    await _pumpDialog(
      tester,
      auth,
      onConfirm: (token) async => tokenEnviado = token,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Sessão AUDESP ativa'), findsOneWidget);
    expect(find.text('Expira às 13:00'), findsOneWidget);
    expect(tokenEnviado, isNull);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(tokenEnviado, 'token-teste');
    expect(adapter.requests, hasLength(1));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('ação personalizada remove Autenticar e e permite cancelar', (
    tester,
  ) async {
    await tester.runAsync(login);
    var envios = 0;
    await _pumpDialog(
      tester,
      auth,
      actionLabel: 'Autenticar e Atualizar',
      onConfirm: (_) async {
        envios++;
      },
    );
    expect(find.text('Atualizar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(envios, 0);
    expect(adapter.requests, hasLength(1));
  });

  testWidgets('401 no envio volta para senha e permite autenticar novamente', (
    tester,
  ) async {
    await tester.runAsync(login);
    final api = ApiService(auth);
    api.dio.httpClientAdapter = JsonHttpAdapter({}, statusCode: 401);
    addTearDown(() => api.dio.close(force: true));
    var tentativas = 0;
    await _pumpDialog(
      tester,
      auth,
      onConfirm: (_) async {
        tentativas++;
        if (tentativas == 1) {
          await api.dio.get('${Environment.piloto.baseUrl}/teste');
        }
      },
    );
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(
      find.text('A sessão AUDESP expirou. Informe a senha novamente.'),
      findsOneWidget,
    );
    expect(find.text('Senha AUDESP'), findsOneWidget);
    expect(find.text('Sessão AUDESP ativa'), findsNothing);
    await tester.enterText(find.byType(TextField), 'nova-senha');
    await tester.tap(find.text('Autenticar e enviar'));
    await tester.pumpAndSettle();
    expect(tentativas, 2);
    expect(adapter.requests, hasLength(2));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('outro erro permanece no diálogo com a sessão ativa', (
    tester,
  ) async {
    await tester.runAsync(login);
    await _pumpDialog(
      tester,
      auth,
      onConfirm: (_) async => throw Exception('Falha no envio'),
    );
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Falha no envio'), findsOneWidget);
    expect(find.text('Sessão AUDESP ativa'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
