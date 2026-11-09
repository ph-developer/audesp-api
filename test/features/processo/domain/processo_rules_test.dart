import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/domain/processo_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Edital _edital(
  int id, {
  String status = 'sent',
  bool srp = false,
  int? estimativaId,
  bool oculto = false,
}) => Edital(
  id: id,
  estimativaId: estimativaId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$id',
  retificacao: false,
  status: status,
  documentoJson: jsonEncode({'srp': srp}),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, 27),
  ocultoEm: oculto ? DateTime(2026, 10, 29) : null,
);

Licitacao _licitacao(int id, {int editalId = 1, String status = 'draft'}) =>
    Licitacao(
      id: id,
      editalId: editalId,
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-$editalId',
      retificacao: false,
      status: status,
      documentoJson: '{}',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 10, 27),
    );

Ata _ata(int id, {int editalId = 1, String status = 'draft'}) => Ata(
  id: id,
  editalId: editalId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$editalId',
  codigoAta: 'ata-$id',
  retificacao: false,
  status: status,
  documentoJson: '{}',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, 27),
);

Ajuste _ajuste(
  int id, {
  int? editalId = 1,
  int? ataId,
  String status = 'draft',
}) => Ajuste(
  id: id,
  editalId: editalId,
  ataId: ataId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$editalId',
  codigoAta: ataId == null ? null : 'ata-$ataId',
  codigoContrato: 'ajuste-$id',
  retificacao: false,
  status: status,
  documentoJson: '{}',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, 27),
);

Processo _processo({
  Edital? edital,
  EstimativaModel? estimativa,
  List<Licitacao> licitacoes = const [],
  List<Ata> atas = const [],
  List<Ajuste> ajustes = const [],
  EnviosProcesso? envios,
}) => Processo(
  edital: edital ?? _edital(1),
  estimativa: estimativa,
  licitacoes: licitacoes,
  atas: atas,
  ajustes: ajustes,
  envios: envios,
);

const _oficial = 'https://audesp.tce.sp.gov.br';
const _piloto = 'https://audesp-piloto.tce.sp.gov.br';

EnvioResumo _envio(
  int id,
  Map<String, Object?> descritor, {
  String? statusProtocolo,
  int timestamp = 100,
  String baseUrl = _oficial,
}) => EnvioResumo(
  id: id,
  statusCode: 200,
  protocolo: 'P$id',
  statusProtocolo: statusProtocolo,
  timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
  descritor: descritor,
  endpoint: '$baseUrl/recepcao-fase-4/f4/enviar',
);

void main() {
  group('edital oculto', () {
    test('bloqueia ata e ajuste, inclusive na adesão', () {
      final srp = _processo(
        edital: _edital(1, srp: true, oculto: true),
        licitacoes: [_licitacao(1, status: 'sent')],
      );
      final comum = _processo(
        edital: _edital(2, oculto: true),
        licitacoes: [_licitacao(2, editalId: 2, status: 'sent')],
      );
      expect(
        ProcessoRules.motivoBloqueioAta(srp),
        ProcessoRules.motivoEditalOculto,
      );
      expect(
        ProcessoRules.motivoBloqueioAjuste(comum),
        ProcessoRules.motivoEditalOculto,
      );
      expect(
        ProcessoRules.opcoesAjuste([
          comum,
        ], adesaoParticipacao: true).single.liberado,
        isFalse,
      );
      expect(ProcessoRules.opcoesAta([srp]).single.liberado, isFalse);
    });
  });

  group('Processo.agrupar', () {
    test('liga a estimativa por id e ignora vínculos ausentes ou órfãos', () {
      final estimativa = EstimativaModel(
        id: 7,
        numero: 3,
        ano: 2026,
        objeto: 'Material',
      );
      final processos = Processo.agrupar(
        editais: [
          _edital(1, estimativaId: 7),
          _edital(2, estimativaId: 99),
          _edital(3),
          _edital(4, estimativaId: 7),
        ],
        licitacoes: [],
        atas: [],
        ajustes: [],
        estimativas: [estimativa],
      );
      expect(processos[0].estimativa, same(estimativa));
      expect(processos[1].estimativa, isNull);
      expect(processos[2].estimativa, isNull);
      expect(processos[3].estimativa, same(estimativa));
      final semEstimativas = Processo.agrupar(
        editais: [_edital(1, estimativaId: 7)],
        licitacoes: [],
        atas: [],
        ajustes: [],
      );
      expect(semEstimativas.single.estimativa, isNull);
    });

    test('vincula por edital e preserva a ordem de todas as listas', () {
      final editais = [_edital(2), _edital(1), _edital(3, status: 'draft')];
      final licitacoes = [
        _licitacao(1),
        _licitacao(2, editalId: 2),
        _licitacao(3),
        _licitacao(4, editalId: 99),
      ];
      final atas = [
        _ata(1, editalId: 2),
        _ata(2),
        _ata(3, editalId: 2),
        _ata(4, editalId: 99),
      ];
      final ajustes = [
        _ajuste(1, ataId: 2),
        _ajuste(2, editalId: 2, ataId: 1),
        _ajuste(3),
        _ajuste(4, editalId: null, ataId: 2),
        _ajuste(5, editalId: 99),
      ];

      final processos = Processo.agrupar(
        editais: editais,
        licitacoes: licitacoes,
        atas: atas,
        ajustes: ajustes,
      );

      expect(processos.map((p) => p.edital), editais);
      expect(processos[0].licitacoes, [licitacoes[1]]);
      expect(processos[0].atas, [atas[0], atas[2]]);
      expect(processos[0].ajustes, [ajustes[1]]);
      expect(processos[1].licitacoes, [licitacoes[0], licitacoes[2]]);
      expect(processos[1].atas, [atas[1]]);
      expect(processos[1].ajustes, [ajustes[0], ajustes[2]]);
      expect(processos[2].licitacoes, isEmpty);
      expect(processos[2].atas, isEmpty);
      expect(processos[2].ajustes, isEmpty);
    });

    test('sem editais descarta todos os documentos', () {
      expect(
        Processo.agrupar(
          editais: [],
          licitacoes: [_licitacao(1)],
          atas: [_ata(1)],
          ajustes: [_ajuste(1), _ajuste(2, editalId: null)],
        ),
        isEmpty,
      );
    });

    test('Processo mantém cópias imutáveis das listas recebidas', () {
      final licitacao = _licitacao(1);
      final ata = _ata(1);
      final ajuste = _ajuste(1);
      final licitacoes = [licitacao];
      final atas = [ata];
      final ajustes = [ajuste];
      final processo = _processo(
        licitacoes: licitacoes,
        atas: atas,
        ajustes: ajustes,
      );

      licitacoes.clear();
      atas.clear();
      ajustes.clear();

      expect(processo.licitacoes, [licitacao]);
      expect(processo.atas, [ata]);
      expect(processo.ajustes, [ajuste]);
      expect(() => processo.licitacoes.clear(), throwsUnsupportedError);
      expect(() => processo.atas.clear(), throwsUnsupportedError);
      expect(() => processo.ajustes.clear(), throwsUnsupportedError);
    });
  });

  group('situacaoLicitacao', () {
    test('sem licitação é inexistente', () {
      expect(
        ProcessoRules.situacaoLicitacao(_processo()),
        SituacaoLicitacao.inexistente,
      );
    });

    test('com licitações não enviadas é pendente', () {
      expect(
        ProcessoRules.situacaoLicitacao(
          _processo(licitacoes: [_licitacao(1), _licitacao(2)]),
        ),
        SituacaoLicitacao.pendente,
      );
    });

    test('enviada sem log de envio (legado) é concluída', () {
      expect(
        ProcessoRules.situacaoLicitacao(
          _processo(licitacoes: [_licitacao(1, status: 'sent')]),
        ),
        SituacaoLicitacao.concluida,
      );
    });

    test('concluída prevalece sobre rascunhos em qualquer ordem', () {
      final licitacoes = [_licitacao(1), _licitacao(2, status: 'sent')];
      expect(
        ProcessoRules.situacaoLicitacao(_processo(licitacoes: licitacoes)),
        SituacaoLicitacao.concluida,
      );
      expect(
        ProcessoRules.situacaoLicitacao(
          _processo(licitacoes: licitacoes.reversed.toList()),
        ),
        SituacaoLicitacao.concluida,
      );
    });
  });

  group('protocolo armazenado conclui a fase', () {
    final edital = DescritorEnvio.edital(
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-1',
      retificacao: false,
    );
    final licitacao = DescritorEnvio.licitacao(
      municipio: '1',
      entidade: '2',
      codigoEdital: 'edital-1',
      retificacao: false,
    );

    EnviosProcesso envios({
      List<EnvioResumo> editais = const [],
      List<EnvioResumo> licitacoes = const [],
    }) => EnviosProcesso(
      editais: EnviosIndex(editais),
      licitacoes: EnviosIndex(licitacoes),
      baseUrl: _oficial,
    );

    test('edital em análise bloqueia licitação', () {
      final processo = _processo(
        envios: envios(
          editais: [_envio(1, edital, statusProtocolo: 'Recebido')],
        ),
      );

      expect(
        ProcessoRules.motivoBloqueioLicitacao(processo),
        'O protocolo do edital ainda não foi armazenado pelo AUDESP '
        '(situação: Recebido).',
      );
      expect(
        ProcessoRules.motivoBloqueioAjuste(processo),
        ProcessoRules.motivoBloqueioLicitacao(processo),
      );
    });

    test('edital armazenado libera a licitação', () {
      final processo = _processo(
        envios: envios(
          editais: [_envio(1, edital, statusProtocolo: 'Armazenado')],
        ),
      );

      expect(ProcessoRules.motivoBloqueioLicitacao(processo), isNull);
    });

    test('armazenado no Piloto não conclui no Oficial', () {
      final processo = _processo(
        envios: envios(
          editais: [
            _envio(1, edital, statusProtocolo: 'Armazenado', baseUrl: _piloto),
          ],
        ),
      );

      expect(
        ProcessoRules.motivoBloqueioLicitacao(processo),
        'O edital ainda não foi enviado ao AUDESP.',
      );
    });

    test('edital em retificação continua concluído', () {
      final processo = _processo(
        edital: _edital(1, status: 'draft'),
        envios: envios(
          editais: [
            _envio(2, {...edital, 'retificacao': true}, timestamp: 200),
            _envio(1, edital, statusProtocolo: 'Armazenado'),
          ],
        ),
      );

      expect(processo.conclusaoEdital.concluida, isTrue);
      expect(ProcessoRules.motivoBloqueioLicitacao(processo), isNull);
    });

    test('licitação rejeitada bloqueia o ajuste e pede reenvio', () {
      final processo = _processo(
        licitacoes: [_licitacao(1, status: 'sent')],
        envios: envios(
          licitacoes: [_envio(1, licitacao, statusProtocolo: 'Rejeitado')],
        ),
      );

      expect(
        ProcessoRules.motivoBloqueioAjuste(processo),
        'O protocolo da licitação do edital foi rejeitado pelo AUDESP. '
        'Corrija e reenvie.',
      );
    });

    test('licitação em análise bloqueia o ajuste', () {
      final processo = _processo(
        licitacoes: [_licitacao(1, status: 'sent')],
        envios: envios(
          licitacoes: [_envio(1, licitacao, statusProtocolo: 'Pendente')],
        ),
      );

      expect(ProcessoRules.podeCriarAjuste(processo), isFalse);
    });

    test('licitação armazenada libera o ajuste', () {
      final processo = _processo(
        licitacoes: [_licitacao(1, status: 'sent')],
        envios: envios(
          licitacoes: [_envio(1, licitacao, statusProtocolo: 'Armazenado')],
        ),
      );

      expect(ProcessoRules.podeCriarAjuste(processo), isTrue);
    });

    test('uma licitação armazenada basta entre várias', () {
      final processo = _processo(
        licitacoes: [
          _licitacao(1, status: 'sent'),
          _licitacao(2),
        ],
        envios: envios(
          licitacoes: [
            _envio(2, licitacao, statusProtocolo: 'Rejeitado', timestamp: 200),
            _envio(1, licitacao, statusProtocolo: 'Armazenado'),
          ],
        ),
      );

      expect(
        ProcessoRules.situacaoLicitacao(processo),
        SituacaoLicitacao.concluida,
      );
    });
  });

  group('motivoBloqueioAta e podeCriarAta', () {
    test('edital não enviado tem prioridade sobre SRP e licitação', () {
      final processo = _processo(edital: _edital(1, status: 'draft'));
      expect(
        ProcessoRules.motivoBloqueioAta(processo),
        'O edital ainda não foi enviado ao AUDESP.',
      );
      expect(ProcessoRules.podeCriarAta(processo), isFalse);
    });

    test('edital não SRP tem prioridade sobre a ausência de licitação', () {
      final processo = _processo();
      expect(
        ProcessoRules.motivoBloqueioAta(processo),
        'Ata de registro de preços exige edital SRP.',
      );
      expect(ProcessoRules.podeCriarAta(processo), isFalse);
    });

    test('exige licitação para edital SRP enviado', () {
      final processo = _processo(edital: _edital(1, srp: true));
      expect(
        ProcessoRules.motivoBloqueioAta(processo),
        'O edital ainda não tem licitação.',
      );
      expect(ProcessoRules.podeCriarAta(processo), isFalse);
    });

    test('exige envio da licitação em rascunho', () {
      final processo = _processo(
        edital: _edital(1, srp: true),
        licitacoes: [_licitacao(1)],
      );
      expect(
        ProcessoRules.motivoBloqueioAta(processo),
        'A licitação do edital ainda não foi enviada ao AUDESP.',
      );
      expect(ProcessoRules.podeCriarAta(processo), isFalse);
    });

    test('libera edital SRP e licitação enviados mesmo com outro rascunho', () {
      final processo = _processo(
        edital: _edital(1, srp: true),
        licitacoes: [
          _licitacao(1),
          _licitacao(2, status: 'sent'),
        ],
      );
      expect(ProcessoRules.motivoBloqueioAta(processo), isNull);
      expect(ProcessoRules.podeCriarAta(processo), isTrue);
    });
  });

  group('motivoBloqueioAjuste e podeCriarAjuste', () {
    test('edital não enviado tem prioridade sobre SRP e licitação', () {
      for (final srp in [false, true]) {
        final processo = _processo(
          edital: _edital(1, status: 'draft', srp: srp),
        );
        expect(
          ProcessoRules.motivoBloqueioAjuste(processo),
          'O edital ainda não foi enviado ao AUDESP.',
        );
        expect(ProcessoRules.podeCriarAjuste(processo), isFalse);
      }
    });

    test('SRP bloqueia ajuste independentemente da licitação ou ata', () {
      for (final licitacoes in <List<Licitacao>>[
        [],
        [_licitacao(1)],
        [_licitacao(1, status: 'sent')],
      ]) {
        final processo = _processo(
          edital: _edital(1, srp: true),
          licitacoes: licitacoes,
          atas: [_ata(1, status: 'sent')],
        );
        expect(
          ProcessoRules.motivoBloqueioAjuste(processo),
          'Edital com registro de preços gera ata, não ajuste.',
        );
        expect(ProcessoRules.podeCriarAjuste(processo), isFalse);
      }
    });

    test('exige licitação para edital não SRP', () {
      final processo = _processo();
      expect(
        ProcessoRules.motivoBloqueioAjuste(processo),
        'O edital ainda não tem licitação.',
      );
      expect(ProcessoRules.podeCriarAjuste(processo), isFalse);
    });

    test('exige envio da licitação em rascunho', () {
      final processo = _processo(licitacoes: [_licitacao(1)]);
      expect(
        ProcessoRules.motivoBloqueioAjuste(processo),
        'A licitação do edital ainda não foi enviada ao AUDESP.',
      );
      expect(ProcessoRules.podeCriarAjuste(processo), isFalse);
    });

    test('libera edital não SRP e licitação enviados', () {
      final processo = _processo(
        licitacoes: [
          _licitacao(1),
          _licitacao(2, status: 'sent'),
        ],
      );
      expect(ProcessoRules.motivoBloqueioAjuste(processo), isNull);
      expect(ProcessoRules.podeCriarAjuste(processo), isTrue);
      expect(ProcessoRules.podeCriarAta(processo), isFalse);
    });

    test('adesão ou participação fica isenta de todos os bloqueios', () {
      final processos = [
        _processo(edital: _edital(1, status: 'draft')),
        _processo(edital: _edital(1, srp: true)),
        _processo(
          edital: _edital(1, srp: true),
          licitacoes: [_licitacao(1, status: 'sent')],
        ),
        _processo(licitacoes: [_licitacao(1)]),
      ];
      for (final processo in processos) {
        expect(
          ProcessoRules.motivoBloqueioAjuste(
            processo,
            adesaoParticipacao: true,
          ),
          isNull,
        );
        expect(
          ProcessoRules.podeCriarAjuste(processo, adesaoParticipacao: true),
          isTrue,
        );
      }
    });
  });

  group('opções de edital', () {
    test('sem processos não há opções', () {
      expect(ProcessoRules.opcoesAta([]), isEmpty);
      expect(ProcessoRules.opcoesAjuste([]), isEmpty);
      expect(ProcessoRules.opcoesAjuste([], adesaoParticipacao: true), isEmpty);
    });

    test(
      'ata inclui só editais enviados SRP, com bloqueios e na mesma ordem',
      () {
        final semLicitacao = _processo(edital: _edital(3, srp: true));
        final liberado = _processo(
          edital: _edital(2, srp: true),
          licitacoes: [
            _licitacao(1, editalId: 2, status: 'sent'),
            _licitacao(2, editalId: 2),
            _licitacao(3, editalId: 2, status: 'sent'),
          ],
        );
        final licitacaoRascunho = _processo(
          edital: _edital(1, srp: true),
          licitacoes: [_licitacao(4)],
        );
        final opcoes = ProcessoRules.opcoesAta([
          _processo(edital: _edital(4, srp: true, status: 'draft')),
          semLicitacao,
          _processo(
            edital: _edital(5),
            licitacoes: [_licitacao(5, editalId: 5, status: 'sent')],
          ),
          liberado,
          licitacaoRascunho,
        ]);

        expect(opcoes.map((o) => o.processo), [
          semLicitacao,
          liberado,
          licitacaoRascunho,
        ]);
        expect(opcoes.map((o) => o.liberado), [false, true, false]);
        expect(opcoes.map((o) => o.motivoBloqueio), [
          ProcessoRules.motivoBloqueioAta(semLicitacao),
          null,
          ProcessoRules.motivoBloqueioAta(licitacaoRascunho),
        ]);
      },
    );

    test('ajuste inclui só enviados não SRP com o motivo de cada bloqueio', () {
      final processos = [
        for (final srp in [false, true]) ...[
          _processo(edital: _edital(srp ? 4 : 1, srp: srp)),
          _processo(
            edital: _edital(srp ? 5 : 2, srp: srp),
            licitacoes: [_licitacao(1, editalId: srp ? 5 : 2)],
          ),
          _processo(
            edital: _edital(srp ? 6 : 3, srp: srp),
            licitacoes: [
              _licitacao(2, editalId: srp ? 6 : 3, status: 'sent'),
              _licitacao(3, editalId: srp ? 6 : 3),
            ],
          ),
        ],
      ];
      final opcoes = ProcessoRules.opcoesAjuste([
        _processo(edital: _edital(7, status: 'draft')),
        ...processos,
        _processo(edital: _edital(8, status: 'draft', srp: true)),
      ]);

      final naoSrp = processos.where((p) => !p.edital.isSrp);
      expect(opcoes.map((o) => o.processo), naoSrp);
      expect(opcoes.map((o) => o.liberado), [false, false, true]);
      expect(
        opcoes.map((o) => o.motivoBloqueio),
        naoSrp.map(ProcessoRules.motivoBloqueioAjuste),
      );
    });

    test('adesão libera todos os enviados mas mantém fora os não enviados', () {
      final processos = [
        _processo(),
        _processo(
          edital: _edital(2, srp: true),
          licitacoes: [_licitacao(1, editalId: 2)],
        ),
        _processo(
          edital: _edital(3),
          licitacoes: [_licitacao(2, editalId: 3, status: 'sent')],
        ),
      ];
      final opcoes = ProcessoRules.opcoesAjuste([
        ...processos,
        _processo(edital: _edital(4, status: 'draft')),
      ], adesaoParticipacao: true);

      expect(opcoes.map((o) => o.processo), processos);
      expect(opcoes.every((o) => o.liberado), isTrue);
      expect(opcoes.every((o) => o.motivoBloqueio == null), isTrue);
    });
  });

  group('dependentesDe', () {
    test('conta atas e ajustes em qualquer status', () {
      final processo = _processo(
        atas: [
          _ata(1),
          _ata(2, status: 'sent'),
        ],
        ajustes: [
          _ajuste(1),
          _ajuste(2, status: 'sent'),
          _ajuste(3),
        ],
      );
      expect(ProcessoRules.dependentesDe(processo), (atas: 2, ajustes: 3));
    });

    test('processo sem dependentes tem contagens zeradas', () {
      expect(ProcessoRules.dependentesDe(_processo()), (atas: 0, ajustes: 0));
    });
  });
}
