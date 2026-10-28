import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respostas HTTP em memória; nenhum teste que o usa acessa a rede.
class JsonHttpAdapter implements HttpClientAdapter {
  Map<String, dynamic> data;
  int statusCode;
  final requests = <RequestOptions>[];

  JsonHttpAdapter(this.data, {this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
