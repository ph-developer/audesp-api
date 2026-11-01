import 'dart:async';

import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysql_client/exception.dart';

import '../../support/fake_mysql_server.dart';

void main() {
  late FakeMySqlServer server;
  late DatabaseService db;

  const sql = 'SELECT value FROM app_settings WHERE `key` = (?)';

  setUp(() async {
    server = await FakeMySqlServer.start();
    db = server.database();
  });

  tearDown(() async {
    await db.close();
    await server.stop();
  });

  // O COM_STMT_CLOSE não tem resposta: espera o servidor processar a fila.
  Future<void> settle() => Future.delayed(const Duration(milliseconds: 100));

  group('DatabaseService.executePrepared', () {
    test('libera cada statement depois de executar', () async {
      for (var i = 0; i < 500; i++) {
        await db.executePrepared(sql, ['chave']);
      }
      await settle();

      expect(server.comStmtPrepare, 500);
      expect(server.comStmtClose, 500);
      expect(server.preparedStmtCount, 0);
    });

    test('não acumula statements nas leituras periódicas do PNCP', () async {
      final settings = AppSettingsDao(db);

      for (var minuto = 0; minuto < 1000; minuto++) {
        await (
          settings.get(SettingsKeys.pncpCnpj),
          settings.get(SettingsKeys.pncpConsultaAutomatica),
          settings.get(SettingsKeys.pncpIntervaloMinutos),
          settings.get(SettingsKeys.pncpUltimaConsultaEm),
        ).wait;
      }
      await settle();

      expect(server.comStmtPrepare, 4000);
      expect(server.preparedStmtCount, 0);
      expect(server.peakConnections, lessThanOrEqualTo(5));
    });

    test('libera o statement quando a execução falha', () async {
      await expectLater(
        db.executePrepared('INSERT /*dup*/ INTO t VALUES (?)', [1]),
        throwsA(isA<MySQLServerException>()),
      );
      await settle();

      expect(server.comStmtClose, 1);
      expect(server.preparedStmtCount, 0);
    });

    test('mantém a conexão utilizável depois de erro de SQL', () async {
      for (var i = 0; i < 20; i++) {
        await expectLater(
          db.executePrepared('INSERT /*dup*/ INTO t VALUES (?)', [i]),
          throwsA(isA<MySQLServerException>()),
        );
      }
      await db.executePrepared(sql, ['chave']);
      await settle();

      expect(server.peakConnections, 1);
      expect(server.preparedStmtCount, 0);
    });

    test('libera o statement com número errado de parâmetros', () async {
      await expectLater(
        db.executePrepared(sql, ['a', 'b']),
        throwsA(isA<MySQLClientException>()),
      );
      await settle();

      expect(server.preparedStmtCount, 0);
    });

    test('sem parâmetros usa a consulta simples', () async {
      await db.executePrepared('DELETE FROM api_logs', []);

      expect(server.comStmtPrepare, 0);
      expect(server.comQuery, greaterThan(0));
    });
  });

  group('DatabaseService.execute', () {
    test('não cria prepared statements no servidor', () async {
      await db.execute('SELECT * FROM users WHERE email = :email', {
        'email': 'a@b.c',
      });

      expect(server.comStmtPrepare, 0);
      expect(server.preparedStmtCount, 0);
    });

    test('rajada do primeiro frame respeita o limite de conexões', () async {
      await db.execute('SELECT 1');

      await Future.wait([
        db.executePrepared(sql, ['environment']),
        for (var i = 0; i < 5; i++) db.execute('SELECT * FROM t$i'),
        for (var i = 0; i < 6; i++) db.executePrepared(sql, ['chave$i']),
      ]);
      await settle();

      expect(server.peakConnections, 5);
      expect(server.preparedStmtCount, 0);
    });
  });
}
