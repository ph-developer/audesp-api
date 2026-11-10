import 'dart:convert';

import 'package:audesp_api/features/logs/domain/conclusao_envio.dart';
import 'package:audesp_api/features/logs/domain/retificacao.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:flutter_test/flutter_test.dart';

const _oficial = 'https://audesp.tce.sp.gov.br';
const _piloto = 'https://audesp-piloto.tce.sp.gov.br';

EnvioResumo _envio(
  int id, {
  String? statusProtocolo,
  bool retificacao = false,
  String baseUrl = _oficial,
}) => EnvioResumo(
  id: id,
  statusCode: 200,
  protocolo: 'P$id',
  statusProtocolo: statusProtocolo,
  timestamp: DateTime(2026, 11, id),
  descritor: {'retificacao': retificacao},
  endpoint: '$baseUrl/recepcao-fase-4/f4/enviar-edital',
);

/// [envios] do mais recente ao mais antigo, como em `EnviosIndex.todos`.
ConclusaoEnvio _de(
  String status,
  List<EnvioResumo> envios, {
  DateTime? descartadaEm,
}) => ConclusaoEnvio.de(
  status: status,
  envios: envios,
  baseUrl: _oficial,
  retificacaoDescartadaEm: descartadaEm,
);

void main() {
  group('retificação pendente', () {
    test('rejeitada depois do armazenado fica pendente e não desfaz', () {
      final conclusao = _de('sent', [
        _envio(2, statusProtocolo: 'Rejeitado', retificacao: true),
        _envio(1, statusProtocolo: 'Armazenado'),
      ]);
      expect(conclusao.concluida, isTrue);
      expect(conclusao.envio?.id, 1);
      expect(conclusao.retificacao?.id, 2);
      expect(conclusao.retificacaoRejeitada, isTrue);
      expect(conclusao.envioPendente?.id, 2);
      expect(conclusao.motivo('edital'), isNull);
      expect(conclusao.motivoPendencia('edital'), contains('rejeitada'));
    });

    test('em análise fica pendente com a situação do protocolo', () {
      final conclusao = _de('sent', [
        _envio(2, statusProtocolo: 'Recebido', retificacao: true),
        _envio(1, statusProtocolo: 'Armazenado'),
      ]);
      expect(conclusao.retificacao?.id, 2);
      expect(conclusao.retificacaoRejeitada, isFalse);
      expect(
        conclusao.motivoPendencia('ata', feminino: true),
        'A retificação da ata ainda não foi armazenada pelo AUDESP '
        '(situação: Recebido).',
      );
    });

    test('armazenada deixa de ser pendente e vira a versão vigente', () {
      final conclusao = _de('sent', [
        _envio(2, statusProtocolo: 'Armazenado', retificacao: true),
        _envio(1, statusProtocolo: 'Substituído'),
      ]);
      expect(conclusao.envio?.id, 2);
      expect(conclusao.retificacao, isNull);
    });

    test('reenvio do original parado em Recebido não é retificação', () {
      final conclusao = _de('sent', [
        _envio(2, statusProtocolo: 'Recebido'),
        _envio(1, statusProtocolo: 'Armazenado'),
      ]);
      expect(conclusao.retificacao, isNull);
    });

    test('excluída ou de outro ambiente não fica pendente', () {
      expect(
        _de('sent', [
          _envio(2, statusProtocolo: 'Excluído', retificacao: true),
          _envio(1, statusProtocolo: 'Armazenado'),
        ]).retificacao,
        isNull,
      );
      expect(
        _de('sent', [
          _envio(
            2,
            statusProtocolo: 'Rejeitado',
            retificacao: true,
            baseUrl: _piloto,
          ),
          _envio(1, statusProtocolo: 'Armazenado'),
        ]).retificacao,
        isNull,
      );
    });

    test('descartada some; uma nova depois do descarte volta a pender', () {
      final envios = [
        _envio(2, statusProtocolo: 'Rejeitado', retificacao: true),
        _envio(1, statusProtocolo: 'Armazenado'),
      ];
      expect(
        _de('sent', envios, descartadaEm: DateTime(2026, 11, 2)).retificacao,
        isNull,
      );
      expect(
        _de('sent', envios, descartadaEm: DateTime(2026, 11, 3)).retificacao,
        isNull,
      );
      expect(
        _de('sent', [
          _envio(4, statusProtocolo: 'Rejeitado', retificacao: true),
          ...envios,
        ], descartadaEm: DateTime(2026, 11, 3)).retificacao?.id,
        4,
      );
    });

    test('sem armazenado, o rejeitado continua sendo a situação', () {
      final conclusao = _de('sent', [
        _envio(1, statusProtocolo: 'Rejeitado', retificacao: true),
      ]);
      expect(conclusao.situacao, SituacaoConclusao.rejeitado);
      expect(conclusao.retificacao, isNull);
      expect(conclusao.motivoPendencia('edital'), conclusao.motivo('edital'));
    });
  });

  group('modo do campo retificacao', () {
    test('armazenado no ambiente obriga retificação', () {
      final modo = RetificacaoRules.modo(
        _de('draft', [_envio(1, statusProtocolo: 'Armazenado')]),
      );
      expect(modo, ModoRetificacao.retificacao);
      expect(modo.valor, isTrue);
    });

    test('aceito sem armazenamento segue como original', () {
      for (final status in ['Rejeitado', 'Recebido', 'Excluído']) {
        final modo = RetificacaoRules.modo(
          _de('draft', [_envio(1, statusProtocolo: status)]),
        );
        expect(modo, ModoRetificacao.original, reason: status);
        expect(modo.valor, isFalse);
      }
    });

    test('sem envio no ambiente, legado ou sem conclusão: usuário decide', () {
      expect(RetificacaoRules.modo(null), ModoRetificacao.livre);
      expect(RetificacaoRules.modo(_de('draft', [])), ModoRetificacao.livre);
      expect(RetificacaoRules.modo(_de('sent', [])), ModoRetificacao.livre);
      expect(
        RetificacaoRules.modo(
          _de('draft', [
            _envio(1, statusProtocolo: 'Armazenado', baseUrl: _piloto),
          ]),
        ),
        ModoRetificacao.livre,
      );
      expect(ModoRetificacao.livre.valor, isNull);
    });
  });

  group('ações', () {
    final armazenado = [_envio(1, statusProtocolo: 'Armazenado')];
    final rejeitada = [
      _envio(2, statusProtocolo: 'Rejeitado', retificacao: true),
      ...armazenado,
    ];
    final emAnalise = [
      _envio(2, statusProtocolo: 'Recebido', retificacao: true),
      ...armazenado,
    ];

    test('retificar só o enviado concluído sem retificação pendente', () {
      bool pode(ConclusaoEnvio c, {bool enviado = true}) =>
          RetificacaoRules.podeRetificar(c, enviado: enviado);
      expect(pode(_de('sent', armazenado)), isTrue);
      expect(pode(_de('sent', [])), isTrue, reason: 'legado');
      expect(pode(_de('draft', armazenado), enviado: false), isFalse);
      expect(pode(_de('sent', rejeitada)), isFalse);
      expect(pode(_de('sent', emAnalise)), isFalse);
      expect(
        pode(_de('sent', [_envio(1, statusProtocolo: 'Rejeitado')])),
        isFalse,
      );
      expect(RetificacaoRules.podeRetificar(null, enviado: true), isFalse);
    });

    test('descartar no rascunho ou com a retificação rejeitada', () {
      bool pode(ConclusaoEnvio c, {required bool enviado}) =>
          RetificacaoRules.podeDescartar(c, enviado: enviado);
      expect(pode(_de('draft', armazenado), enviado: false), isTrue);
      expect(pode(_de('draft', rejeitada), enviado: false), isTrue);
      expect(pode(_de('sent', rejeitada), enviado: true), isTrue);
      expect(pode(_de('sent', emAnalise), enviado: true), isFalse);
      expect(pode(_de('sent', armazenado), enviado: true), isFalse);
      expect(
        pode(_de('draft', []), enviado: false),
        isFalse,
        reason: 'sem versão armazenada para restaurar',
      );
      expect(
        pode(_de('sent', []), enviado: false),
        isFalse,
        reason: 'legado não tem log para restaurar',
      );
    });
  });

  group('documento', () {
    test('marcar troca só descritor.retificacao', () {
      final json = jsonEncode({
        'descritor': {'codigoEdital': 'X', 'retificacao': false},
        'objeto': 'Papel',
      });
      final marcado = RetificacaoRules.marcar(json, retificacao: true);
      expect(jsonDecode(marcado), {
        'descritor': {'codigoEdital': 'X', 'retificacao': true},
        'objeto': 'Papel',
      });
      expect(RetificacaoRules.retificacaoDe(marcado), isTrue);
      expect(RetificacaoRules.retificacaoDe(json), isFalse);
    });

    test('sem descritor cria um; JSON inválido é erro', () {
      expect(jsonDecode(RetificacaoRules.marcar('{}', retificacao: true)), {
        'descritor': {'retificacao': true},
      });
      expect(RetificacaoRules.retificacaoDe('{}'), isFalse);
      expect(
        () => RetificacaoRules.marcar('[]', retificacao: true),
        throwsFormatException,
      );
      expect(
        () => RetificacaoRules.retificacaoDe('inválido'),
        throwsFormatException,
      );
    });
  });
}
