import 'dart:convert';

import 'package:audesp_api/features/logs/domain/atualizacao_protocolos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pendentes = [
    ProtocoloEmAndamento(logId: 1, protocolo: 'A', statusAtual: 'Pendente'),
    ProtocoloEmAndamento(logId: 2, protocolo: 'B', statusAtual: 'Recebido'),
    ProtocoloEmAndamento(logId: 3, protocolo: 'C', statusAtual: 'Pendente'),
  ];

  test('grava só os protocolos que mudaram de situação', () async {
    final salvos = <int, String>{};
    final retornos = {'A': 'Armazenado', 'B': 'Recebido', 'C': 'Rejeitado'};

    final mudaram = await AtualizacaoProtocolos.executar(
      pendentes: pendentes,
      consultar: (p) async => jsonEncode({'status': retornos[p]}),
      salvar: (id, status, _) async => salvos[id] = status,
      podeContinuar: () => true,
    );

    expect(mudaram, 2);
    expect(salvos, {1: 'Armazenado', 3: 'Rejeitado'});
  });

  test('erro ou resposta sem status não impede os demais', () async {
    final salvos = <int>[];

    final mudaram = await AtualizacaoProtocolos.executar(
      pendentes: pendentes,
      consultar: (p) async => switch (p) {
        'A' => throw Exception('Erro 500'),
        'B' => '{}',
        _ => jsonEncode({'status': 'Armazenado'}),
      },
      salvar: (id, _, _) async => salvos.add(id),
      podeContinuar: () => true,
    );

    expect(mudaram, 1);
    expect(salvos, [3]);
  });

  test('para quando o token deixa de valer', () async {
    final consultados = <String>[];
    var tokenValido = true;

    await AtualizacaoProtocolos.executar(
      pendentes: pendentes,
      consultar: (p) async {
        consultados.add(p);
        tokenValido = false; // ex.: 401 limpou o token
        throw Exception('Erro 401');
      },
      salvar: (_, _, _) async {},
      podeContinuar: () => tokenValido,
    );

    expect(consultados, ['A']);
  });
}
