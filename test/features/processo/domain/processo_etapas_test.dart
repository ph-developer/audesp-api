import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/processo_etapas.dart';
import 'package:audesp_api/features/processo/domain/processo_rules.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../processo_fixtures.dart';

EtapaProcesso _etapa(Processo processo, EtapaTipo tipo, {User? user}) =>
    ProcessoEtapas.de(
      processo,
      user ?? usuarioFixture(isAdmin: true),
    ).singleWhere((etapa) => etapa.tipo == tipo);

List<EtapaTipo> _tipos(Processo processo) => ProcessoEtapas.de(
  processo,
  usuarioFixture(isAdmin: true),
).map((etapa) => etapa.tipo).toList();

void main() {
  test(
    'estimativa de origem não acrescenta etapas nem altera dependências',
    () {
      final processo = processoFixture(
        estimativa: EstimativaModel(
          id: 7,
          numero: 3,
          ano: 2026,
          objeto: 'Material',
        ),
      );
      final etapas = ProcessoEtapas.de(processo, usuarioFixture(isAdmin: true));
      expect(etapas.map((e) => e.tipo), [
        EtapaTipo.edital,
        EtapaTipo.licitacao,
        EtapaTipo.ajuste,
      ]);
      expect(etapas[1].situacao, SituacaoEtapa.aCriar);
    },
  );

  test(
    'etapas seguem a ordem do fluxo e edital rascunho bloqueia licitação',
    () {
      final processo = processoFixture(status: 'draft');
      final etapas = ProcessoEtapas.de(processo, usuarioFixture(isAdmin: true));

      expect(etapas.map((etapa) => etapa.tipo), [
        EtapaTipo.edital,
        EtapaTipo.licitacao,
        EtapaTipo.ajuste,
      ]);
      expect(etapas.first.situacao, SituacaoEtapa.rascunho);
      expect(etapas.first.quantidade, 1);
      expect(etapas.first.acoes.single.label, 'Abrir edital');
      expect(etapas.first.acoes.single.route, '/edital/1');
      final licitacao = etapas[1];
      expect(licitacao.situacao, SituacaoEtapa.bloqueada);
      expect(
        licitacao.motivoBloqueio,
        'O edital ainda não foi enviado ao AUDESP.',
      );
      expect(licitacao.quantidade, 0);
      expect(licitacao.acoes, isEmpty);
    },
  );

  test(
    'edital enviado sem licitação permite criá-la com o edital preenchido',
    () {
      final processo = processoFixture(id: 42);
      expect(
        _etapa(processo, EtapaTipo.edital).situacao,
        SituacaoEtapa.enviada,
      );
      final etapa = _etapa(processo, EtapaTipo.licitacao);

      expect(etapa.situacao, SituacaoEtapa.aCriar);
      expect(etapa.motivoBloqueio, isNull);
      expect(etapa.acoes.single.label, 'Nova licitação');
      expect(etapa.acoes.single.route, '/licitacao/new?editalId=42');
    },
  );

  test('edital não SRP mostra Ajuste e omite Ata', () {
    expect(_tipos(processoFixture()), [
      EtapaTipo.edital,
      EtapaTipo.licitacao,
      EtapaTipo.ajuste,
    ]);
  });

  for (final licitacoes in [
    <Licitacao>[],
    [licitacaoFixture(1)],
  ]) {
    test(
      'SRP sem licitação enviada bloqueia ata e dispensa ajuste ($licitacoes)',
      () {
        final processo = processoFixture(srp: true, licitacoes: licitacoes);

        final ata = _etapa(processo, EtapaTipo.ata);
        expect(ata.situacao, SituacaoEtapa.bloqueada);
        expect(
          ata.motivoBloqueio,
          licitacoes.isEmpty
              ? 'O edital ainda não tem licitação.'
              : 'A licitação do edital ainda não foi enviada ao AUDESP.',
        );
        expect(ata.acoes, isEmpty);
        expect(_tipos(processo), isNot(contains(EtapaTipo.ajuste)));
      },
    );
  }

  test('etapa omitida volta a aparecer quando há documento antigo', () {
    final processo = processoFixture(
      licitacoes: [licitacaoFixture(1, status: 'sent')],
      atas: [ataFixture(11, status: 'sent')],
    );

    final ata = _etapa(processo, EtapaTipo.ata);
    expect(ata.situacao, SituacaoEtapa.enviada);
    expect(ata.acoes.map((a) => a.label), ['Abrir ata ata-11']);
  });

  test('SRP com licitação enviada libera só ata e omite Ajuste', () {
    final processo = processoFixture(
      srp: true,
      licitacoes: [licitacaoFixture(1, status: 'sent')],
    );
    final ata = _etapa(processo, EtapaTipo.ata);
    expect(ata.situacao, SituacaoEtapa.aCriar);
    expect(ata.acoes.single.label, 'Nova ata');
    expect(ata.acoes.single.route, '/ata/new?editalId=1');
    expect(_tipos(processo), [
      EtapaTipo.edital,
      EtapaTipo.licitacao,
      EtapaTipo.ata,
    ]);
  });

  test('SRP com ata em rascunho omite Ajuste', () {
    final processo = processoFixture(
      srp: true,
      licitacoes: [licitacaoFixture(1, status: 'sent')],
      atas: [ataFixture(11)],
    );

    expect(_etapa(processo, EtapaTipo.ata).situacao, SituacaoEtapa.rascunho);
    expect(_tipos(processo), isNot(contains(EtapaTipo.ajuste)));
  });

  for (final status in ['draft', 'sent']) {
    test('SRP mantém abertura do ajuste antigo sem criar outro ($status)', () {
      final processo = processoFixture(
        srp: true,
        licitacoes: [licitacaoFixture(1, status: 'sent')],
        atas: [
          ataFixture(11, status: 'sent'),
          ataFixture(12),
          ataFixture(13, status: 'sent'),
        ],
        ajustes: [ajusteFixture(21, ataId: 11, status: status)],
      );
      final ajuste = _etapa(processo, EtapaTipo.ajuste);

      expect(
        ajuste.situacao,
        status == 'sent' ? SituacaoEtapa.enviada : SituacaoEtapa.rascunho,
      );
      expect(ajuste.quantidade, 1);
      expect(ajuste.acoes.single.label, 'Abrir ajuste ajuste-21');
      expect(ajuste.acoes.single.route, '/ajuste/21');
    });
  }

  test('SRP com ata enviada e sem ajustes não oferece criação de ajuste', () {
    final processo = processoFixture(
      srp: true,
      licitacoes: [licitacaoFixture(1, status: 'sent')],
      atas: [ataFixture(11, status: 'sent')],
    );

    expect(_etapa(processo, EtapaTipo.ata).situacao, SituacaoEtapa.enviada);
    expect(_tipos(processo), isNot(contains(EtapaTipo.ajuste)));
  });

  test('SRP sem licitação e com ata enviada também dispensa ajuste', () {
    final processo = processoFixture(
      srp: true,
      atas: [ataFixture(11, status: 'sent')],
    );

    expect(_tipos(processo), isNot(contains(EtapaTipo.ajuste)));
  });

  test('não SRP com licitação enviada cria ajuste diretamente pelo edital', () {
    final processo = processoFixture(
      licitacoes: [licitacaoFixture(1, status: 'sent')],
    );
    final ajuste = _etapa(processo, EtapaTipo.ajuste);

    expect(ajuste.situacao, SituacaoEtapa.aCriar);
    expect(ajuste.acoes.single.label, 'Novo ajuste');
    expect(ajuste.acoes.single.route, '/ajuste/new?editalId=1');
  });

  test('não SRP sem licitação enviada bloqueia ajuste', () {
    final ajuste = _etapa(processoFixture(), EtapaTipo.ajuste);

    expect(ajuste.situacao, SituacaoEtapa.bloqueada);
    expect(ajuste.motivoBloqueio, 'O edital ainda não tem licitação.');
    expect(ajuste.acoes, isEmpty);
  });

  test(
    'licitação enviada prevalece sobre rascunhos e ações distinguem os ids',
    () {
      final processo = processoFixture(
        licitacoes: [
          licitacaoFixture(2),
          licitacaoFixture(3, status: 'sent'),
        ],
      );
      final licitacao = _etapa(processo, EtapaTipo.licitacao);

      expect(licitacao.situacao, SituacaoEtapa.enviada);
      expect(licitacao.quantidade, 2);
      expect(licitacao.acoes.map((acao) => acao.label), [
        'Abrir licitação rascunho #2',
        'Abrir licitação enviada #3',
      ]);
      expect(licitacao.acoes.map((acao) => acao.route), [
        '/licitacao/2',
        '/licitacao/3',
      ]);
    },
  );

  test('licitação única em rascunho tem ação simples de abertura', () {
    final etapa = _etapa(
      processoFixture(licitacoes: [licitacaoFixture(7)]),
      EtapaTipo.licitacao,
    );

    expect(etapa.situacao, SituacaoEtapa.rascunho);
    expect(etapa.acoes.single.label, 'Abrir licitação');
    expect(etapa.acoes.single.route, '/licitacao/7');
  });

  for (final status in ['draft', 'sent']) {
    test('ata e ajuste agregam todos os documentos ($status)', () {
      final processo = processoFixture(
        srp: true,
        licitacoes: [licitacaoFixture(1, status: 'sent')],
        atas: [
          ataFixture(11, status: 'sent'),
          ataFixture(12, status: status),
        ],
        ajustes: [
          ajusteFixture(21, status: 'sent'),
          ajusteFixture(22, status: status),
        ],
      );
      for (final tipo in [EtapaTipo.ata, EtapaTipo.ajuste]) {
        final etapa = _etapa(processo, tipo);
        expect(
          etapa.situacao,
          status == 'sent' ? SituacaoEtapa.enviada : SituacaoEtapa.rascunho,
        );
        expect(etapa.quantidade, 2);
      }
    });
  }

  test(
    'documentos existentes continuam abrindo quando a criação é bloqueada',
    () {
      final processo = processoFixture(
        status: 'draft',
        srp: true,
        atas: [ataFixture(11, codigo: '')],
        ajustes: [ajusteFixture(21, codigo: '')],
      );
      final ata = _etapa(processo, EtapaTipo.ata);
      final ajuste = _etapa(processo, EtapaTipo.ajuste);

      expect(ata.situacao, SituacaoEtapa.rascunho);
      expect(ata.acoes.single.label, 'Abrir ata 11');
      expect(ata.acoes.single.route, '/ata/11');
      expect(ajuste.situacao, SituacaoEtapa.rascunho);
      expect(ajuste.acoes.single.label, 'Abrir ajuste 21');
      expect(ajuste.acoes.single.route, '/ajuste/21');
    },
  );

  test('rótulos usam número/ano ou o código PNCP com máscara', () {
    final processo = processoFixture(
      srp: true,
      licitacoes: [licitacaoFixture(1, status: 'sent')],
      atas: [
        ataFixture(
          11,
          status: 'sent',
          documentoJson: '{"numeroAtaRegistroPreco":"7","anoAta":2026}',
        ),
        ataFixture(
          12,
          status: 'sent',
          codigo: '1234567800019011234562026000001',
        ),
      ],
      ajustes: [
        ajusteFixture(
          21,
          ataId: 11,
          documentoJson: '{"numeroContratoEmpenho":"15","anoContrato":2026}',
        ),
      ],
    );
    final user = usuarioFixture(isAdmin: true);
    final ata = _etapa(processo, EtapaTipo.ata, user: user);
    final ajuste = _etapa(processo, EtapaTipo.ajuste, user: user);

    expect(ata.acoes.map((a) => a.label), [
      'Abrir ata 7/2026',
      'Abrir ata 12345678000190-1-123456/2026-000001',
      'Nova ata',
    ]);
    expect(ajuste.acoes.single.label, 'Abrir ajuste 15/2026');
  });

  test('Contratação não recebe ações de Ata ou Ajuste', () {
    final processo = processoFixture(
      srp: true,
      licitacoes: [licitacaoFixture(1, status: 'sent')],
      atas: [ataFixture(11, status: 'sent')],
      ajustes: [ajusteFixture(21)],
    );
    final user = usuarioFixture(
      permissions: AppPermissions.edital | AppPermissions.licitacao,
    );
    final etapas = ProcessoEtapas.de(processo, user);

    expect(etapas[0].acoes, isNotEmpty);
    expect(etapas[1].acoes, isNotEmpty);
    expect(etapas[2].acoes, isEmpty);
    expect(etapas[3].acoes, isEmpty);
  });

  test(
    'Contratos não recebe Nova licitação nem abertura de edital/licitação',
    () {
      final user = usuarioFixture(
        permissions: AppPermissions.ata | AppPermissions.ajuste,
      );
      final semLicitacao = ProcessoEtapas.de(processoFixture(), user);
      expect(semLicitacao[0].acoes, isEmpty);
      expect(semLicitacao[1].acoes, isEmpty);
      final comLicitacao = ProcessoEtapas.de(
        processoFixture(
          srp: true,
          licitacoes: [licitacaoFixture(1, status: 'sent')],
        ),
        user,
      );
      expect(comLicitacao[1].acoes, isEmpty);
      expect(comLicitacao[2].acoes.single.label, 'Nova ata');
    },
  );

  test('sem permissão de envio não há ações em nenhuma etapa', () {
    final etapas = ProcessoEtapas.de(
      processoFixture(srp: true, licitacoes: [licitacaoFixture(1)]),
      usuarioFixture(permissions: AppPermissions.estimativa),
    );
    expect(etapas.expand((etapa) => etapa.acoes), isEmpty);
  });

  group('pendências', () {
    test('rótulos e rotas preservam os vínculos ao criar documentos', () {
      final processo = processoFixture(id: 42);
      final casos = [
        (
          TipoPendencia.criarLicitacao,
          'Criar licitação',
          '/licitacao/new?editalId=42',
        ),
        (TipoPendencia.criarAta, 'Criar ata', '/ata/new?editalId=42'),
        (TipoPendencia.criarAjuste, 'Criar ajuste', '/ajuste/new?editalId=42'),
      ];
      for (final (tipo, descricao, rota) in casos) {
        final pendencia = Pendencia(processo: processo, tipo: tipo);
        expect(descricaoPendencia(pendencia), descricao);
        expect(rotaPendencia(pendencia), rota);
      }
    });

    test(
      'enviar abre o rascunho atualizado mais recentemente, sem ordenar a origem',
      () {
        final antigo = licitacaoFixture(9, updatedAt: DateTime(2026, 10, 20));
        final recente = licitacaoFixture(2, updatedAt: DateTime(2026, 10, 28));
        final processo = processoFixture(
          licitacoes: [
            antigo,
            recente,
            licitacaoFixture(99, status: 'sent'),
          ],
        );
        final pendencia = Pendencia(
          processo: processo,
          tipo: TipoPendencia.enviarLicitacao,
        );

        expect(descricaoPendencia(pendencia), 'Enviar licitação');
        expect(rotaPendencia(pendencia), '/licitacao/2');
        expect(processo.licitacoes.first, antigo);
      },
    );

    test('datas iguais usam o maior id para o rascunho mais recente', () {
      final pendencia = Pendencia(
        processo: processoFixture(
          licitacoes: [licitacaoFixture(9), licitacaoFixture(2)],
        ),
        tipo: TipoPendencia.enviarLicitacao,
      );
      expect(rotaPendencia(pendencia), '/licitacao/9');
    });
  });
}
