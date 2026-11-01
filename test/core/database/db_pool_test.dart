import 'dart:async';

import 'package:audesp_api/core/database/db_pool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_mysql_server.dart';

void main() {
  late FakeMySqlServer server;

  setUp(() async {
    server = await FakeMySqlServer.start();
  });

  tearDown(() => server.stop());

  group('DbPool', () {
    test('rajada não passa de maxConnections', () async {
      final pool = server.pool();

      await Future.wait([
        for (var i = 0; i < 50; i++)
          pool.use((conn) => conn.execute('SELECT /*sleep:5*/ 1')),
      ]);

      expect(server.peakConnections, 5);
      expect(pool.openConnections, 5);
      expect(pool.idleConnections, 5);
      await pool.close();
    });

    test('quem excede o limite espera na fila sem travar o isolate', () async {
      final pool = server.pool(maxConnections: 2);
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => ticks++,
      );

      await Future.wait([
        for (var i = 0; i < 6; i++)
          pool.use((conn) => conn.execute('SELECT /*sleep:50*/ 1')),
      ]);
      timer.cancel();

      expect(ticks, greaterThan(0));
      expect(server.peakConnections, 2);
      await pool.close();
    });

    test('devolve a conexão quando a ação lança exceção', () async {
      final pool = server.pool(maxConnections: 1);

      await expectLater(
        pool.use<void>((conn) async => throw StateError('falha')),
        throwsStateError,
      );
      await pool.use((conn) => conn.execute('SELECT 1'));

      expect(pool.openConnections, 1);
      await pool.close();
    });

    test('falha ao conectar não consome vaga do pool', () async {
      var attempts = 0;
      final pool = DbPool(
        maxConnections: 1,
        connect: () async {
          attempts++;
          throw StateError('sem rede');
        },
      );

      await expectLater(
        pool.use((conn) => conn.execute('SELECT 1')),
        throwsStateError,
      );
      await expectLater(
        pool.use((conn) => conn.execute('SELECT 1')),
        throwsStateError,
      );

      expect(attempts, 2);
      expect(pool.openConnections, 0);
    });

    test('conexão caída no meio do comando sai do pool', () async {
      final pool = server.pool(
        maxConnections: 1,
        commandTimeout: const Duration(milliseconds: 200),
      );
      await pool.use((conn) => conn.execute('SELECT 1'));

      await expectLater(
        pool.use((conn) => conn.execute('SELECT /*drop*/ 1')),
        throwsA(isA<TimeoutException>()),
      );
      expect(pool.openConnections, 0);

      await pool.use((conn) => conn.execute('SELECT 1'));
      expect(pool.openConnections, 1);
      await pool.close();
    });

    test('descarta conexão fechada pelo servidor enquanto ociosa', () async {
      final pool = server.pool(maxConnections: 1);
      await pool.use((conn) => conn.execute('SELECT 1'));

      server.dropConnections();
      await Future.delayed(const Duration(milliseconds: 50));
      await pool.use((conn) => conn.execute('SELECT 1'));

      expect(pool.openConnections, 1);
      expect(server.threadsConnected, 1);
      await pool.close();
    });

    test('close encerra as conexões ociosas', () async {
      final pool = server.pool();
      await Future.wait([
        for (var i = 0; i < 3; i++)
          pool.use((conn) => conn.execute('SELECT /*sleep:5*/ 1')),
      ]);

      await pool.close();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(pool.openConnections, 0);
      expect(server.threadsConnected, 0);
    });
  });
}
