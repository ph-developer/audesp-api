import 'dart:convert';

import 'package:audesp_api/core/database/models/licitacao.dart';
import 'package:audesp_api/features/licitacao/domain/licitacao_referencia.dart';
import 'package:flutter_test/flutter_test.dart';

Licitacao _licitacao(
  int id, {
  String status = 'draft',
  int dia = 1,
  String? json,
}) => Licitacao(
  id: id,
  editalId: 1,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital',
  retificacao: false,
  status: status,
  documentoJson:
      json ??
      jsonEncode({
        'itens': [
          {'numeroItem': id},
        ],
      }),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, dia),
);

void main() {
  test('prefere enviada mais recente, mesmo com rascunho posterior', () {
    final licitacoes = [
      _licitacao(1, dia: 27),
      _licitacao(2, status: 'sent', dia: 10),
      _licitacao(3, status: 'sent', dia: 20),
    ];
    expect(LicitacaoReferencia.selecionar(licitacoes)?.id, 3);
    expect(LicitacaoReferencia.numerosItens(licitacoes), {3});
    expect(licitacoes.map((l) => l.id), [1, 2, 3]);
  });

  test('sem enviada ignora todos os rascunhos', () {
    final licitacoes = [
      _licitacao(1, dia: 10),
      _licitacao(2, dia: 20),
      _licitacao(3, dia: 20),
    ];
    expect(LicitacaoReferencia.selecionar(licitacoes), isNull);
    expect(LicitacaoReferencia.numerosItens(licitacoes), isNull);
  });

  test('entre enviadas desempata pelo maior id independentemente da ordem', () {
    final licitacoes = [
      _licitacao(3, status: 'sent', dia: 20),
      _licitacao(4, dia: 27),
      _licitacao(1, status: 'sent', dia: 10),
      _licitacao(2, status: 'sent', dia: 20),
    ];
    expect(LicitacaoReferencia.selecionar(licitacoes)?.id, 3);
    expect(LicitacaoReferencia.selecionar(licitacoes.reversed)?.id, 3);
  });

  test('ausência ou JSON ilegível não cria referência vazia bloqueante', () {
    expect(LicitacaoReferencia.selecionar([]), isNull);
    expect(LicitacaoReferencia.numerosItens([]), isNull);
    for (final json in [
      'inválido',
      '{}',
      '{"itens": null}',
      '{"itens": [{}]}',
      '{"itens": [{"numeroItem": 1}, {"numeroItem": "inválido"}]}',
    ]) {
      expect(
        LicitacaoReferencia.numerosItens([
          _licitacao(1, status: 'sent', json: json),
        ]),
        isNull,
      );
    }
  });

  test(
    'lista vazia é referência conhecida e extrai todos os números da lista',
    () {
      expect(
        LicitacaoReferencia.numerosItens([
          _licitacao(1, status: 'sent', json: '{"itens": []}'),
        ]),
        isEmpty,
      );
      expect(
        LicitacaoReferencia.numerosItens([
          _licitacao(
            1,
            status: 'sent',
            json:
                '{"itens": [{"numeroItem": 2}, {"numeroItem": 5}, {"numeroItem": 2}]}',
          ),
        ]),
        {2, 5},
      );
    },
  );

  test(
    'enviada ilegível não usa enviada anterior nem rascunho como referência',
    () {
      final licitacoes = [
        _licitacao(1, status: 'sent', dia: 10),
        _licitacao(2, status: 'sent', dia: 20, json: '{}'),
        _licitacao(3, dia: 27),
      ];
      expect(LicitacaoReferencia.selecionar(licitacoes)?.id, 2);
      expect(LicitacaoReferencia.numerosItens(licitacoes), isNull);
    },
  );
}
