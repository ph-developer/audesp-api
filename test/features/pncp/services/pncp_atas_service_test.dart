import 'dart:convert';
import 'dart:typed_data';

import 'package:audesp_api/features/pncp/services/pncp_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_ata_fixtures.dart';

class _Respostas implements HttpClientAdapter {
  final List<(int, Object?, String?)> respostas;
  final requests = <RequestOptions>[];
  _Respostas(this.respostas);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, corpo, retry) = respostas[requests.length];
    requests.add(options);
    // Status 0 simula o PNCP sem responder dentro do tempo limite.
    if (status == 0) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    }
    return ResponseBody.fromString(
      corpo == null ? '' : jsonEncode(corpo),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (retry != null) 'retry-after': [retry],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const cnpj = '49576416000141';
  final esperas = <Duration>[];
  setUp(esperas.clear);
  PncpService servico(_Respostas adapter) => PncpService(
    dio: Dio(BaseOptions(baseUrl: 'https://pncp.gov.br/api/consulta'))
      ..httpClientAdapter = adapter,
    esperar: (duracao) async => esperas.add(duracao),
  );

  test(
    'lista usa /api/pncp, sequência da compra e página solicitada',
    () async {
      final json = ataPncpJson(sequencialCompra: 2);
      final adapter = _Respostas([
        (
          200,
          {
            'data': [json],
            'totalPaginas': 3,
          },
          null,
        ),
      ]);
      final pagina = await servico(
        adapter,
      ).consultarAtasCompra(cnpj, 2026, 2, 2);
      expect(pagina.dados.single, json);
      expect(pagina.totalPaginas, 3);
      final req = adapter.requests.single;
      expect(req.uri.path, '/api/pncp/v1/orgaos/$cnpj/compras/2026/2/atas');
      expect(req.queryParameters['pagina'], 2);
    },
  );

  for (final status in [204, 404, 410]) {
    test('$status com corpo vazio significa compra sem atas', () async {
      final pagina = await servico(
        _Respostas([(status, null, null)]),
      ).consultarAtasCompra(cnpj, 2026, 1, 1);
      expect(pagina.dados, isEmpty);
      expect(pagina.totalPaginas, 1);
    });
  }

  test(
    'atualizações usam /api/consulta, datas AAAAMMDD e páginas menores',
    () async {
      final adapter = _Respostas([
        (
          200,
          {
            'data': [ataPncpJson(atualizacao: true)],
            'totalPaginas': 2,
          },
          null,
        ),
      ]);
      final pagina = await servico(adapter).consultarAtasAtualizadas(
        cnpj,
        DateTime(2026, 1, 2),
        DateTime(2026, 11, 9),
        2,
      );
      expect(pagina.totalPaginas, 2);
      final req = adapter.requests.single;
      expect(req.uri.path, '/api/consulta/v1/atas/atualizacao');
      expect(req.queryParameters, {
        'cnpj': cnpj,
        'dataInicial': '20260102',
        'dataFinal': '20261109',
        'pagina': 2,
        'tamanhoPagina': PncpService.tamanhoPaginaAtualizacoes,
      });
      expect(req.receiveTimeout, PncpService.tempoAtualizacoes);
    },
  );

  test('204 de atualizações é janela vazia, 404/410 são erros', () async {
    final pagina = await servico(
      _Respostas([(204, null, null)]),
    ).consultarAtasAtualizadas(cnpj, DateTime(2026), DateTime(2026, 11, 9), 1);
    expect(pagina.dados, isEmpty);
    for (final status in [404, 410]) {
      await expectLater(
        servico(_Respostas([(status, null, null)])).consultarAtasAtualizadas(
          cnpj,
          DateTime(2026),
          DateTime(2026, 11, 9),
          1,
        ),
        throwsA(isA<PncpException>()),
      );
    }
  });

  test('detalhe consulta a sequência da ata dentro da compra', () async {
    final json = ataPncpJson(sequencialCompra: 2, sequencialAta: 22);
    final adapter = _Respostas([(200, json, null)]);
    expect(await servico(adapter).consultarAta(cnpj, 2026, 2, 22), json);
    expect(
      adapter.requests.single.uri.path,
      '/api/pncp/v1/orgaos/$cnpj/compras/2026/2/atas/22',
    );
    await expectLater(
      servico(
        _Respostas([
          (404, {'message': 'Ata não cadastrada.'}, null),
        ]),
      ).consultarAta(cnpj, 2026, 2, 22),
      throwsA(isA<PncpException>()),
    );
  });

  test('429 repete exatamente a mesma página depois do Retry-After', () async {
    final adapter = _Respostas([
      (429, {}, '5'),
      (200, {'data': [], 'totalPaginas': 0}, null),
    ]);
    await servico(adapter).consultarAtasCompra(cnpj, 2026, 1, 2);
    expect(esperas, [const Duration(seconds: 5)]);
    expect(adapter.requests[0].uri, adapter.requests[1].uri);
  });

  test('429 repetido/longa espera e 500 não viram página vazia', () async {
    for (final respostas in [
      [(429, <String, dynamic>{}, null), (429, <String, dynamic>{}, null)],
      [(429, <String, dynamic>{}, '61')],
      [(500, <String, dynamic>{}, null)],
    ]) {
      await expectLater(
        servico(_Respostas(respostas)).consultarAtasCompra(cnpj, 2026, 1, 1),
        throwsA(isA<PncpException>()),
      );
    }
    expect(esperas, [PncpService.esperaPadrao]);
  });

  test(
    'corpo ou paginação inválidos não são tratados como leitura completa',
    () async {
      for (final corpo in [
        null,
        [],
        {},
        {'data': [], 'totalPaginas': '2'},
        {
          'data': ['ata inválida'],
          'totalPaginas': 1,
        },
      ]) {
        await expectLater(
          servico(
            _Respostas([(200, corpo, null)]),
          ).consultarAtasCompra(cnpj, 2026, 1, 1),
          throwsA(isA<PncpException>()),
        );
      }
    },
  );

  test('tempo esgotado tenta a mesma página mais uma vez', () async {
    final adapter = _Respostas([
      (0, null, null),
      (200, {'data': [], 'totalPaginas': 1}, null),
    ]);
    await servico(
      adapter,
    ).consultarAtasAtualizadas(cnpj, DateTime(2026), DateTime(2026, 11, 9), 1);
    expect(esperas, [PncpService.esperaPadrao]);
    expect(adapter.requests[0].uri, adapter.requests[1].uri);
  });

  test('tempo esgotado duas vezes vira mensagem clara', () async {
    await expectLater(
      servico(
        _Respostas([(0, null, null), (0, null, null)]),
      ).consultarAtasAtualizadas(
        cnpj,
        DateTime(2026),
        DateTime(2026, 11, 9),
        1,
      ),
      throwsA(
        isA<PncpException>().having(
          (e) => e.toString(),
          'mensagem',
          contains('demorou demais para responder'),
        ),
      ),
    );
  });
}
