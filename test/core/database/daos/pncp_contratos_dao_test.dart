import 'package:audesp_api/core/database/daos/pncp_contratos_dao.dart';
import 'package:audesp_api/core/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_mysql_server.dart';
import '../../../features/pncp/pncp_fixtures.dart';

void main() {
  late FakeMySqlServer server;
  late DatabaseService db;
  late PncpContratosDao dao;
  Map<String, Object?>? row;

  setUp(() async {
    server = await FakeMySqlServer.start();
    db = server.database();
    dao = PncpContratosDao(db);
    row = null;
    server.responder = (sql, params) {
      if (sql.startsWith('INSERT INTO pncp_contratos')) {
        final colunas = RegExp(r'\(([^)]+)\)').firstMatch(sql)![1]!.split(', ');
        final entrada = <String, Object?>{
          for (var i = 0; i < colunas.length; i++) colunas[i]: params[i],
        };
        const inteiros = {
          'ano',
          'sequencial',
          'fruto_adesao',
          'tipo_contrato_id',
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
      if (sql.startsWith('UPDATE pncp_contratos') && row != null) {
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
      final contrato = contratoPncpFixture();
      expect(await dao.findById(1), isNull);
      expect(await dao.upsert(contrato), isTrue);
      var salvo = (await dao.listAll()).single;
      expect(salvo.numeroControle, contrato.numeroControle);
      expect(salvo.numeroControleCompra, contrato.numeroControleCompra);
      expect(salvo.valorGlobal, contrato.valorGlobal);
      expect(salvo.dataAssinatura, contrato.dataAssinatura);
      expect(salvo.vigenciaFim, contrato.vigenciaFim);
      expect(salvo.dados, contrato.dados);

      await dao.dispensar(1, userId: 7, motivo: '  Já enviado  ');
      final criadoEm = salvo.createdAt;
      expect(
        await dao.upsert(
          contratoPncpFixture(
            alteracoes: {'objetoContrato': 'Objeto corrigido'},
          ),
        ),
        isFalse,
      );
      salvo = (await dao.findById(1))!;
      expect(salvo.objeto, 'Objeto corrigido');
      expect(salvo.createdAt, criadoEm);
      expect(salvo.dispensado, isTrue);
      expect(salvo.dispensadaPor, 7);
      expect(salvo.motivoDispensa, 'Já enviado');
      await dao.restaurar(1);
      salvo = (await dao.findById(1))!;
      expect(salvo.dispensado, isFalse);
      expect(salvo.dispensadaPor, isNull);
      expect(salvo.motivoDispensa, isNull);
      await dao.dispensar(1, userId: null, motivo: ' ');
      expect((await dao.findById(1))!.motivoDispensa, isNull);
    },
  );

  test('operações repetidas liberam todos os statements no servidor', () async {
    for (var i = 0; i < 50; i++) {
      await dao.upsert(contratoPncpFixture());
      await dao.findById(1);
      await dao.dispensar(1, userId: 7);
      await dao.restaurar(1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.comStmtPrepare, 200);
    expect(server.comStmtClose, 200);
    expect(server.preparedStmtCount, 0);
  });

  test(
    'migração v16 cria a tabela e avança para v17 sem recriar compras',
    () async {
      var versao = 16;
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
      expect(await db.schemaVersion, 17);
      expect(
        server.consultas.where(
          (c) => c.sql.contains('CREATE TABLE IF NOT EXISTS pncp_contratos'),
        ),
        hasLength(1),
      );
      expect(
        server.consultas.where(
          (c) => c.sql.contains('CREATE TABLE IF NOT EXISTS pncp_compras'),
        ),
        isEmpty,
      );
    },
  );
}
