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

  test('sem enviada usa mais recente e desempata pelo id', () {
    expect(
      LicitacaoReferencia.selecionar([
        _licitacao(1, dia: 10),
        _licitacao(2, dia: 20),
        _licitacao(3, dia: 20),
      ])?.id,
      3,
    );
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
        LicitacaoReferencia.numerosItens([_licitacao(1, json: json)]),
        isNull,
      );
    }
  });

  test(
    'lista vazia é referência conhecida e extrai todos os números da lista',
    () {
      expect(
        LicitacaoReferencia.numerosItens([
          _licitacao(1, json: '{"itens": []}'),
        ]),
        isEmpty,
      );
      expect(
        LicitacaoReferencia.numerosItens([
          _licitacao(
            1,
            json:
                '{"itens": [{"numeroItem": 2}, {"numeroItem": 5}, {"numeroItem": 2}]}',
          ),
        ]),
        {2, 5},
      );
    },
  );
}
