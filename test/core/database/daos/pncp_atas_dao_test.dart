import 'package:audesp_api/core/database/daos/pncp_atas_dao.dart';
import 'package:audesp_api/core/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_mysql_server.dart';
import '../../../features/pncp/pncp_ata_fixtures.dart';

void main() {
  late FakeMySqlServer server;
  late DatabaseService db;
  late PncpAtasDao dao;
  Map<String, Object?>? row;

  setUp(() async {
    server = await FakeMySqlServer.start();
    db = server.database();
    dao = PncpAtasDao(db);
    row = null;
    server.responder = (sql, params) {
      if (sql.startsWith('INSERT INTO pncp_atas')) {
        final colunas = RegExp(r'\(([^)]+)\)').firstMatch(sql)![1]!.split(', ');
        final entrada = <String, Object?>{
          for (var i = 0; i < colunas.length; i++) colunas[i]: params[i],
        };
        const inteiros = {
          'ano_compra',
          'sequencial_compra',
          'sequencial_ata',
          'ano_ata',
          'cancelada',
          'data_cancelamento',
          'data_assinatura',
          'vigencia_inicio',
          'vigencia_fim',
          'data_publicacao',
          'created_at',
          'updated_at',
        };
        for (final chave in inteiros) {
          entrada[chave] = int.tryParse(entrada[chave]?.toString() ?? '');
        }
        if (row == null) {
          row = {'id': 1, ...entrada};
          return const FakeMySqlResult(affectedRows: 1);
        }
        for (final m in RegExp(r'(\w+) = VALUES\((\w+)\)').allMatches(sql)) {
          row![m[1]!] = entrada[m[2]!];
        }
        return const FakeMySqlResult(affectedRows: 2);
      }
      if (sql.startsWith('UPDATE pncp_atas') && row != null) {
        if (sql.contains('dispensada_em = NULL')) {
          row!.addAll({
            'dispensada_em': null,
            'dispensada_por': null,
            'motivo_dispensa': null,
          });
        } else {
          row!.addAll({
            'dispensada_em': int.parse(params[0]!),
            'dispensada_por': params[1] == null ? null : int.parse(params[1]!),
            'motivo_dispensa': params[2],
          });
        }
        return const FakeMySqlResult(affectedRows: 1);
      }
      return FakeMySqlResult(rows: [if (row != null) row!]);
    };
  });

  tearDown(() async {
    await db.close();
    await server.stop();
  });

  test(
    'upsert detecta inclusão, lê datas e preserva a dispensa na atualização',
    () async {
      final ata = ataPncpFixture();
      expect(await dao.findById(1), isNull);
      expect(await dao.upsert(ata), isTrue);
      var salvo = (await dao.listAll()).single;
      expect(salvo.numeroControle, ata.numeroControle);
      expect(salvo.numeroControleCompra, ata.numeroControleCompra);
      expect(salvo.sequencialAta, ata.sequencialAta);
      expect(salvo.dataAssinatura, ata.dataAssinatura);
      expect(salvo.vigenciaFim, ata.vigenciaFim);
      expect(salvo.dados, ata.dados);

      await dao.dispensar(1, userId: 7, motivo: '  Já enviado  ');
      final criadoEm = salvo.createdAt;
      expect(
        await dao.upsert(
          ataPncpFixture(
            alteracoes: {
              'objetoCompra': 'Objeto corrigido',
              'cancelado': true,
              'dataCancelamento': '2026-11-09',
              'dataVigenciaFim': '2027-03-01',
            },
          ),
        ),
        isFalse,
      );
      salvo = (await dao.findById(1))!;
      expect(salvo.objeto, 'Objeto corrigido');
      expect(salvo.cancelada, isTrue);
      expect(salvo.dataCancelamento, DateTime(2026, 11, 9));
      expect(salvo.vigenciaFim, DateTime(2027, 3, 1));
      expect(salvo.createdAt, criadoEm);
      expect(salvo.dispensada, isTrue);
      expect(salvo.dispensadaPor, 7);
      expect(salvo.motivoDispensa, 'Já enviado');
      await dao.restaurar(1);
      salvo = (await dao.findById(1))!;
      expect(salvo.dispensada, isFalse);
      expect(salvo.dispensadaPor, isNull);
      expect(salvo.motivoDispensa, isNull);
      await dao.dispensar(1, userId: null, motivo: ' ');
      expect((await dao.findById(1))!.motivoDispensa, isNull);
    },
  );

  test('operações repetidas liberam todos os statements no servidor', () async {
    for (var i = 0; i < 50; i++) {
      await dao.upsert(ataPncpFixture());
      await dao.findById(1);
      await dao.dispensar(1, userId: 7);
      await dao.restaurar(1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.comStmtPrepare, 200);
    expect(server.comStmtClose, 200);
    expect(server.preparedStmtCount, 0);
  });

  for (final inicial in [17, 18]) {
    test(
      'migração v$inicial chega à v18 sem recriar tabelas anteriores',
      () async {
        var versao = inicial;
        server.responder = (sql, params) {
          if (sql == 'SELECT COUNT(*) FROM __schema') {
            return const FakeMySqlResult(
              rows: [
                {'COUNT(*)': 1},
              ],
            );
          }
          if (sql == 'SELECT version FROM __schema') {
            return FakeMySqlResult(
              rows: [
                {'version': versao},
              ],
            );
          }
          if (sql.startsWith('UPDATE __schema')) {
            versao = int.parse(params.single!);
          }
          if (sql.contains('information_schema.statistics')) {
            return const FakeMySqlResult(
              rows: [
                {'c': 1},
              ],
            );
          }
          return const FakeMySqlResult();
        };
        await db.initialize();
        expect(await db.schemaVersion, 18);
        expect(
          server.consultas.where(
            (c) => c.sql.contains('CREATE TABLE IF NOT EXISTS pncp_atas'),
          ),
          hasLength(inicial == 17 ? 1 : 0),
        );
        expect(
          server.consultas.where(
            (c) =>
                c.sql.contains('CREATE TABLE IF NOT EXISTS pncp_contratos') ||
                c.sql.contains('CREATE TABLE IF NOT EXISTS pncp_compras'),
          ),
          isEmpty,
        );
      },
    );
  }
}
