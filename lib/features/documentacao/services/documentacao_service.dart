import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/documentacao_monitor.dart';

final documentacaoServiceProvider = Provider<DocumentacaoService>(
  (ref) => DocumentacaoService(),
);

/// Baixa as páginas públicas da documentação do AUDESP (sem autenticação).
class DocumentacaoService {
  final Dio _dio;

  DocumentacaoService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'User-Agent': 'audesp_api'},
            ),
          );

  /// Lê a página do TCE, cada anexo dela e a especificação da API. Qualquer
  /// falha lança exceção; o monitor tenta de novo mais tarde.
  Future<DocumentacaoSnapshot> lerDocumentacao() async {
    final html = await _dio.getUri<String>(
      DocumentacaoFontes.paginaTce,
      options: Options(responseType: ResponseType.plain),
    );
    final pagina = extrairPaginaTce(
      html.data ?? '',
      pagina: DocumentacaoFontes.paginaTce,
    );

    final anexos = <String, String>{};
    for (final uri in pagina.anexos) {
      anexos[nomeAnexo(uri)] = await _hashArquivo(uri);
    }

    return DocumentacaoSnapshot(
      textoPagina: sha256.convert(utf8.encode(pagina.texto)).toString(),
      anexos: anexos,
      especificacaoApi: await _hashArquivo(DocumentacaoFontes.especificacaoApi),
    );
  }

  Future<String> _hashArquivo(Uri uri) async {
    final response = await _dio.getUri<List<int>>(
      uri,
      options: Options(responseType: ResponseType.bytes),
    );
    return sha256.convert(response.data ?? const []).toString();
  }
}
