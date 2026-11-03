import 'dart:convert';
import 'dart:typed_data';

import 'package:audesp_api/features/documentacao/domain/documentacao_monitor.dart';
import 'package:audesp_api/features/documentacao/services/documentacao_service.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responde por endereço; nenhum teste acessa a rede.
class _PaginasAdapter implements HttpClientAdapter {
  final Map<String, String> paginas;
  final requests = <Uri>[];

  _PaginasAdapter(this.paginas);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    final corpo = paginas[options.uri.toString()];
    if (corpo == null) return ResponseBody.fromString('', 404);
    return ResponseBody.fromBytes(utf8.encode(corpo), 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const anexo =
      'https://www.tce.sp.gov.br/sites/default/files/audesp-documentacao/edital-20261015.zip';

  Map<String, String> paginas() => {
    DocumentacaoFontes.paginaTce.toString():
        '<article><p>Documentação</p><a href="$anexo">edital</a></article>',
    anexo: 'conteudo-zip',
    DocumentacaoFontes.especificacaoApi.toString(): 'openapi: 3.0.0',
  };

  String hash(String s) => sha256.convert(utf8.encode(s)).toString();

  test('gera hashes do texto, de cada anexo e da especificação', () async {
    final adapter = _PaginasAdapter(paginas());
    final service = DocumentacaoService(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final snapshot = await service.lerDocumentacao();

    expect(snapshot.textoPagina, hash('Documentação edital'));
    expect(snapshot.anexos, {'edital-20261015.zip': hash('conteudo-zip')});
    expect(snapshot.especificacaoApi, hash('openapi: 3.0.0'));
    expect(adapter.requests, hasLength(3));
  });

  test('erro em qualquer arquivo interrompe a leitura', () async {
    final adapter = _PaginasAdapter(paginas()..remove(anexo));
    final service = DocumentacaoService(
      dio: Dio()..httpClientAdapter = adapter,
    );

    await expectLater(service.lerDocumentacao(), throwsA(isA<DioException>()));
  });
}
