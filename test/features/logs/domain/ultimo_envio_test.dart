import 'dart:convert';

import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:flutter_test/flutter_test.dart';

EnvioResumo _envio({
  required int id,
  int? statusCode = 200,
  String? statusProtocolo,
  int timestamp = 1000,
  Map<String, Object?>? descritor,
}) => EnvioResumo.fromMap({
  'id': id,
  'status_code': statusCode,
  'protocolo': statusCode == 200 ? 'P$id' : null,
  'status_protocolo': statusProtocolo,
  'timestamp': timestamp,
  'descritor': descritor == null ? null : jsonEncode(descritor),
});

void main() {
  final edital = DescritorEnvio.edital(
    municipio: '1234',
    entidade: '56',
    codigoEdital: 'E1',
    retificacao: false,
  );

  group('EnviosIndex.ultimo', () {
    test('retorna o envio mais recente do documento', () {
      final index = EnviosIndex([
        _envio(id: 1, timestamp: 100, descritor: {...edital}),
        _envio(id: 3, timestamp: 300, descritor: {...edital}),
        _envio(id: 2, timestamp: 200, descritor: {...edital}),
      ]);

      expect(index.ultimo(edital)?.id, 3);
    });

    test('desempata pelo id no mesmo segundo', () {
      final index = EnviosIndex([
        _envio(id: 4, descritor: {...edital}),
        _envio(id: 5, descritor: {...edital}),
      ]);

      expect(index.ultimo(edital)?.id, 5);
    });

    test('compara números do JSON com os textos do modelo', () {
      final index = EnviosIndex([
        _envio(
          id: 1,
          descritor: {...edital, 'municipio': 1234, 'entidade': 56},
        ),
      ]);

      expect(index.ultimo(edital)?.id, 1);
    });

    test('separa envio original de retificação', () {
      final index = EnviosIndex([
        _envio(id: 1, timestamp: 100, descritor: {...edital}),
        _envio(
          id: 2,
          timestamp: 200,
          descritor: {...edital, 'retificacao': true},
        ),
      ]);

      expect(index.ultimo(edital)?.id, 1);
      expect(index.ultimo({...edital, 'retificacao': true})?.id, 2);
    });

    test('ignora outros documentos e descritores ausentes', () {
      final index = EnviosIndex([
        _envio(id: 1, descritor: {...edital, 'codigoEdital': 'E2'}),
        _envio(id: 2, descritor: {...edital, 'entidade': '99'}),
        _envio(id: 3),
      ]);

      expect(index.ultimo(edital), isNull);
    });

    test('ajuste sem ata não exige codigoAta', () {
      final ajuste = DescritorEnvio.ajuste(
        municipio: '1234',
        entidade: '56',
        codigoEdital: 'E1',
        codigoAta: '',
        codigoContrato: 'C1',
        retificacao: false,
      );
      final index = EnviosIndex([
        _envio(id: 1, descritor: {...ajuste}),
      ]);

      expect(ajuste.containsKey('codigoAta'), isFalse);
      expect(index.ultimo(ajuste)?.id, 1);
    });
  });

  group('EnviosIndex.todos', () {
    test('traz original e retificações sem filtrar a retificação', () {
      final index = EnviosIndex([
        _envio(id: 1, timestamp: 100, descritor: {...edital}),
        _envio(
          id: 2,
          timestamp: 200,
          descritor: {...edital, 'retificacao': true},
        ),
        _envio(id: 3, descritor: {...edital, 'codigoEdital': 'E2'}),
      ]);

      final semRetificacao = Map.of(edital)..remove('retificacao');
      expect(index.todos(semRetificacao).map((e) => e.id), [2, 1]);
    });
  });

  group('EnvioResumo', () {
    test('falha HTTP prevalece sobre o status do protocolo', () {
      final envio = _envio(id: 1, statusCode: 400);

      expect(envio.situacao, SituacaoEnvio.falha);
      expect(envio.rotulo, 'Falha no envio');
    });

    test('usa o status do protocolo ou "Enviado"', () {
      expect(_envio(id: 1, statusProtocolo: 'Armazenado').rotulo, 'Armazenado');
      expect(_envio(id: 2, statusProtocolo: ' ').rotulo, 'Enviado');
      expect(_envio(id: 3).rotulo, 'Enviado');
    });

    test('classifica o status do protocolo', () {
      SituacaoEnvio situacao(String status) =>
          _envio(id: 1, statusProtocolo: status).situacao;

      expect(situacao('Rejeitado'), SituacaoEnvio.rejeitado);
      expect(situacao('Armazenado'), SituacaoEnvio.armazenado);
      expect(situacao('Substituído'), SituacaoEnvio.encerrado);
      expect(situacao('Excluido'), SituacaoEnvio.encerrado);
      expect(situacao('Recebido'), SituacaoEnvio.emAndamento);
      expect(situacao('Pendente'), SituacaoEnvio.emAndamento);
    });

    test('descritor inválido não corresponde a nenhum documento', () {
      final envio = EnvioResumo.fromMap({
        'id': 1,
        'status_code': 200,
        'protocolo': null,
        'status_protocolo': null,
        'timestamp': 0,
        'descritor': 'não é json',
      });

      expect(envio.descritor, isEmpty);
    });
  });

  group('FiltroEnvio', () {
    test('"Sem envio" aceita só documentos sem log', () {
      expect(FiltroEnvio.semEnvio.aceita(null), isTrue);
      expect(FiltroEnvio.semEnvio.aceita(_envio(id: 1)), isFalse);
    });

    test('filtra pela situação do último envio', () {
      final falha = _envio(id: 1, statusCode: 500);
      final armazenado = _envio(id: 2, statusProtocolo: 'Armazenado');

      expect(FiltroEnvio.falha.aceita(falha), isTrue);
      expect(FiltroEnvio.falha.aceita(armazenado), isFalse);
      expect(FiltroEnvio.armazenado.aceita(armazenado), isTrue);
      expect(FiltroEnvio.armazenado.aceita(null), isFalse);
      expect(FiltroEnvio.todos.aceita(null), isTrue);
    });
  });
}
