import 'dart:convert';
import 'dart:typed_data';

import 'package:audesp_api/features/pncp/domain/pncp_varredura.dart';
import 'package:audesp_api/features/pncp/services/pncp_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/json_http_adapter.dart';
import '../pncp_fixtures.dart';

/// Devolve as respostas na ordem, para simular o 429 seguido de sucesso.
class _RespostasEmSequencia implements HttpClientAdapter {
  final List<(int, Map<String, dynamic>, String?)> respostas;
  var chamadas = 0;

  _RespostasEmSequencia(this.respostas);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, corpo, retryAfter) = respostas[chamadas++];
    return ResponseBody.fromString(
      jsonEncode(corpo),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'retry-after': ?retryAfter == null ? null : [retryAfter],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final esperas = <Duration>[];
  setUp(esperas.clear);

  PncpService servico(HttpClientAdapter adapter) => PncpService(
    dio: Dio()..httpClientAdapter = adapter,
    esperar: (d) async => esperas.add(d),
  );

  group('contratos', () {
    test(
      '200 usa /api/pncp mesmo quando o cliente tem a base das compras',
      () async {
        final adapter = JsonHttpAdapter(contratoPncpJson());
        final dio = Dio(
          BaseOptions(baseUrl: 'https://pncp.gov.br/api/consulta'),
        )..httpClientAdapter = adapter;
        final r = await PncpService(
          dio: dio,
        ).consultarContrato('46395000000139', 2026, 2);
        expect(r, isA<ContratoEncontrado>());
        expect((r as ContratoEncontrado).dados['sequencialContrato'], 2);
        expect(
          adapter.requests.single.uri.toString(),
          'https://pncp.gov.br/api/pncp/v1/orgaos/46395000000139/contratos/2026/2',
        );
      },
    );

    test('404 inexistente e 410 excluído', () async {
      final adapter = JsonHttpAdapter({}, statusCode: 404);
      expect(
        await servico(adapter).consultarContrato('1', 2026, 1),
        isA<SequenciaInexistente>(),
      );
      adapter.statusCode = 410;
      expect(
        await servico(adapter).consultarContrato('1', 2026, 1),
        isA<ContratoExcluido>(),
      );
    });

    test('429 aguarda Retry-After e repete a consulta do contrato', () async {
      final adapter = _RespostasEmSequencia([
        (429, {}, '5'),
        (200, contratoPncpJson(), null),
      ]);
      expect(
        await servico(adapter).consultarContrato('1', 2026, 2),
        isA<ContratoEncontrado>(),
      );
      expect(esperas, [const Duration(seconds: 5)]);
      expect(adapter.chamadas, 2);
    });

    test('429 sem cabeçalho espera o padrão e só tenta uma vez', () async {
      final adapter = _RespostasEmSequencia([(429, {}, null), (429, {}, null)]);
      await expectLater(
        servico(adapter).consultarContrato('1', 2026, 2),
        throwsA(isA<PncpException>()),
      );
      expect(esperas, [PncpService.esperaPadrao]);
      expect(adapter.chamadas, 2);
    });

    test(
      'Retry-After longo e demais erros interrompem com PncpException',
      () async {
        final longo = _RespostasEmSequencia([(429, {}, '61')]);
        await expectLater(
          servico(longo).consultarContrato('1', 2026, 2),
          throwsA(isA<PncpException>()),
        );
        expect(esperas, isEmpty);
        await expectLater(
          servico(
            JsonHttpAdapter({}, statusCode: 500),
          ).consultarContrato('1', 2026, 2),
          throwsA(
            isA<PncpException>().having(
              (e) => e.message,
              'message',
              contains('de contrato 2/2026'),
            ),
          ),
        );
      },
    );
  });

  test('200 devolve a compra e consulta a rota do órgão', () async {
    final adapter = JsonHttpAdapter(compraPncpJson());
    final r = await servico(adapter).consultarCompra('46395000000139', 2026, 2);
    expect(r, isA<CompraEncontrada>());
    expect((r as CompraEncontrada).dados['sequencialCompra'], 2);
    expect(
      adapter.requests.single.path,
      '/v1/orgaos/46395000000139/compras/2026/2',
    );
  });

  test('404 é sequência inexistente e 410 é compra excluída', () async {
    final adapter = JsonHttpAdapter({
      'message': 'A contratação informada não está cadastrada.',
    }, statusCode: 404);
    expect(
      await servico(adapter).consultarCompra('1', 2026, 1),
      isA<SequenciaInexistente>(),
    );
    adapter
      ..statusCode = 410
      ..data = {
        'message':
            'A contratação informada foi excluída e não pode ser consultada.',
      };
    expect(
      await servico(adapter).consultarCompra('1', 2026, 27),
      isA<CompraExcluida>(),
    );
  });

  test('429 aguarda o Retry-After e tenta de novo uma vez', () async {
    final adapter = _RespostasEmSequencia([
      (429, {}, '5'),
      (200, compraPncpJson(), null),
    ]);
    final r = await servico(adapter).consultarCompra('1', 2026, 2);
    expect(r, isA<CompraEncontrada>());
    expect(esperas, [const Duration(seconds: 5)]);
    expect(adapter.chamadas, 2);
  });

  test('429 usa a espera real quando nenhuma é injetada', () async {
    final adapter = _RespostasEmSequencia([
      (429, {}, '0'),
      (200, compraPncpJson(), null),
    ]);
    final r = await PncpService(
      dio: Dio()..httpClientAdapter = adapter,
    ).consultarCompra('1', 2026, 2);
    expect(r, isA<CompraEncontrada>());
    expect(adapter.chamadas, 2);
  });

  test('429 sem Retry-After usa a espera padrão', () async {
    final adapter = _RespostasEmSequencia([(429, {}, null), (404, {}, null)]);
    expect(
      await servico(adapter).consultarCompra('1', 2026, 3),
      isA<SequenciaInexistente>(),
    );
    expect(esperas, [PncpService.esperaPadrao]);
  });

  test('429 repetido ou com espera longa interrompe a varredura', () async {
    final repetido = _RespostasEmSequencia([(429, {}, '1'), (429, {}, '1')]);
    await expectLater(
      servico(repetido).consultarCompra('1', 2026, 4),
      throwsA(
        isA<PncpException>().having(
          (e) => e.message,
          'message',
          contains('limitou as consultas (erro 429) na sequência 4/2026'),
        ),
      ),
    );
    expect(repetido.chamadas, 2);

    esperas.clear();
    final longo = _RespostasEmSequencia([(429, {}, '600')]);
    await expectLater(
      servico(longo).consultarCompra('1', 2026, 5),
      throwsA(isA<PncpException>()),
    );
    expect(esperas, isEmpty);
  });

  test('outros erros lançam PncpException com a sequência', () async {
    final adapter = JsonHttpAdapter({}, statusCode: 500);
    expect(
      servico(adapter).consultarCompra('1', 2026, 9),
      throwsA(
        isA<PncpException>().having(
          (e) => e.message,
          'message',
          'O PNCP respondeu com erro 500 na sequência 9/2026.',
        ),
      ),
    );
  });
}
