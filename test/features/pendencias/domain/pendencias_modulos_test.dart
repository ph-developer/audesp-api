import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/logs/domain/conclusao_envio.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/pendencias/domain/pendencias_modulos.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../processo/processo_fixtures.dart';
import '../pendencias_fixtures.dart';

DocumentosProcesso documentosFixture({
  String status = 'draft',
  bool oculto = false,
}) => DocumentosProcesso(
  editais: [processoFixture(status: status, oculto: oculto).edital],
  licitacoes: [licitacaoFixture(1, status: status)],
  atas: [ataFixture(1, status: status)],
  ajustes: [ajusteFixture(1, status: status)],
);

PendenciasModulos pendencias(
  DocumentosProcesso documentos, {
  EnviosProcesso? envios,
  User? user,
  List<PncpCompra> compras = const [],
}) => PendenciasRules.paraUsuario(
  user: user ?? usuarioFixture(isAdmin: true),
  documentos: documentos,
  envios: envios ?? EnviosProcesso.vazio,
  compras: compras,
);

PncpCompra compraFixture(int id, {bool dispensada = false}) => PncpCompra(
  id: id,
  cnpj: '46395000000139',
  ano: 2026,
  sequencial: id,
  numeroControle: '463950000001391${id.toString().padLeft(6, '0')}2026',
  dadosJson: '{}',
  dispensadaEm: dispensada ? DateTime(2026, 11, 9) : null,
);

void main() {
  test('só em análise, rejeitado e excluído são pendências de protocolo', () {
    for (final situacao in SituacaoConclusao.values) {
      expect(
        PendenciasRules.protocoloPendente(ConclusaoEnvio(situacao)),
        [
          SituacaoConclusao.emAnalise,
          SituacaoConclusao.rejeitado,
          SituacaoConclusao.excluido,
        ].contains(situacao),
        reason: situacao.name,
      );
    }
  });

  for (final status in ['draft', 'sent']) {
    for (final situacao in ['Recebido', 'Rejeitado', 'Excluído']) {
      test(
        '$status com protocolo $situacao gera pendência nos quatro módulos',
        () {
          final docs = documentosFixture(status: status);
          final resultado = pendencias(
            docs,
            envios: enviosFixture(docs, situacao: situacao),
          );
          expect(resultado.contagens, {
            '/edital': 1,
            '/licitacao': 1,
            '/ata': 1,
            '/ajuste': 1,
          });
          expect(resultado.editais.single.documento, same(docs.editais.single));
          expect(resultado.editais.single.conclusao.envio?.rotulo, situacao);
          expect(resultado.criarLicitacao, isEmpty);
        },
      );
    }
  }

  test('rascunhos nunca enviados não geram pendência em nenhum módulo', () {
    expect(pendencias(documentosFixture()).contagens.values, everyElement(0));
  });

  for (final situacao in ['Armazenado', 'Substituído']) {
    test('$situacao conclui os quatro documentos e dispensa pendências', () {
      final docs = documentosFixture();
      expect(
        pendencias(
          docs,
          envios: enviosFixture(docs, situacao: situacao),
        ).contagens.values,
        everyElement(0),
      );
    });
  }

  test('retificação rejeitada não desfaz conclusão armazenada', () {
    final docs = documentosFixture();
    EnviosIndex index(Object doc) => EnviosIndex([
      envioFixture(doc, id: 2, situacao: 'Rejeitado', retificacao: true),
      envioFixture(doc, id: 1, situacao: 'Armazenado'),
    ]);
    final envios = EnviosProcesso(
      baseUrl: ambientePendencias,
      editais: index(docs.editais.single),
      licitacoes: index(docs.licitacoes.single),
      atas: index(docs.atas.single),
      ajustes: index(docs.ajustes.single),
    );
    expect(pendencias(docs, envios: envios).contagens.values, everyElement(0));
  });

  test(
    'protocolos de outro ambiente não geram pendência nem liberam criação',
    () {
      final docs = documentosFixture(status: 'sent');
      expect(
        pendencias(
          docs,
          envios: enviosFixture(docs, ambiente: 'https://audesp.tce.sp.gov.br'),
        ).contagens.values,
        everyElement(0),
      );
    },
  );

  test('edital só pede nova licitação após concluir e sem nenhum vínculo', () {
    final editais = [
      for (var id = 1; id <= 5; id++) processoFixture(id: id).edital,
    ];
    final docs = DocumentosProcesso(
      editais: editais,
      licitacoes: [licitacaoFixture(3, editalId: 3)],
    );
    final envios = EnviosProcesso(
      baseUrl: ambientePendencias,
      editais: EnviosIndex([
        envioFixture(editais[0], situacao: 'Armazenado'),
        envioFixture(editais[1], situacao: 'Recebido'),
        envioFixture(editais[2], situacao: 'Armazenado'),
        envioFixture(editais[3], situacao: 'Rejeitado'),
        envioFixture(
          editais[4],
          situacao: 'Armazenado',
          ambiente: 'https://audesp.tce.sp.gov.br',
        ),
      ]),
    );
    expect(pendencias(docs, envios: envios).criarLicitacao, [editais[0]]);
  });

  test('legado enviado continua elegível para criar licitação', () {
    final edital = processoFixture().edital;
    expect(pendencias(DocumentosProcesso(editais: [edital])).criarLicitacao, [
      edital,
    ]);
  });

  test('edital oculto e seus documentos não geram pendência', () {
    final docs = documentosFixture(oculto: true);
    expect(
      pendencias(docs, envios: enviosFixture(docs)).contagens.values,
      everyElement(0),
    );
    expect(
      pendencias(DocumentosProcesso(editais: docs.editais)).criarLicitacao,
      isEmpty,
    );
  });

  test('ajuste sem edital tem conclusão própria e aparece nas pendências', () {
    final ajuste = ajusteFixture(
      9,
      editalId: null,
      documentoJson: '{"adesaoParticipacao":true}',
    );
    final docs = DocumentosProcesso(ajustes: [ajuste]);
    final resultado = pendencias(
      docs,
      envios: enviosFixture(docs, situacao: 'Rejeitado'),
    );
    expect(resultado.ajustes.single.documento, same(ajuste));
    expect(resultado.ajustes.single.edital, isNull);
    expect(resultado.contagens['/ajuste'], 1);
  });

  test('não cobra criação de ata ou ajuste depois da licitação', () {
    for (final srp in [false, true]) {
      final docs = DocumentosProcesso(
        editais: [processoFixture(srp: srp).edital],
        licitacoes: [licitacaoFixture(1, status: 'sent')],
      );
      expect(pendencias(docs).contagens.values, everyElement(0));
    }
  });

  test('PNCP dispensa restaurável não conta e edital oculto ainda casa', () {
    final compras = [
      compraFixture(1),
      compraFixture(2, dispensada: true),
      compraFixture(3),
    ];
    final docs = DocumentosProcesso(
      editais: [
        processoFixture(codigo: compras[2].numeroControle, oculto: true).edital,
      ],
    );
    final resultado = pendencias(docs, compras: compras);
    expect(resultado.comprasEdital, [compras[0]]);
    expect(resultado.comprasDispensadas, [compras[1]]);
    expect(resultado.contagens['/edital'], 1);
  });

  test('permissões filtram protocolos, PNCP e criação de licitação', () {
    final docs = documentosFixture();
    final envios = enviosFixture(docs);
    for (final permissao in [
      AppPermissions.none,
      AppPermissions.estimativa,
      AppPermissions.edital,
      AppPermissions.licitacao,
      AppPermissions.ata,
      AppPermissions.ajuste,
    ]) {
      final user = usuarioFixture(permissions: permissao);
      final resultado = pendencias(
        docs,
        envios: envios,
        user: user,
        compras: [compraFixture(1)],
      );
      expect(resultado.contagens, {
        '/edital': permissao == AppPermissions.edital ? 2 : 0,
        '/licitacao': permissao == AppPermissions.licitacao ? 1 : 0,
        '/ata': permissao == AppPermissions.ata ? 1 : 0,
        '/ajuste': permissao == AppPermissions.ajuste ? 1 : 0,
      });
      final semLicitacao = pendencias(
        DocumentosProcesso(editais: [processoFixture().edital]),
        user: user,
      );
      expect(
        semLicitacao.criarLicitacao.length,
        permissao == AppPermissions.licitacao ? 1 : 0,
      );
    }
  });
}
