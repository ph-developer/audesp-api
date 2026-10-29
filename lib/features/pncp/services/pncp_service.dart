import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pncp_varredura.dart';

final pncpServiceProvider = Provider<PncpService>((ref) => PncpService());

/// Cliente da API pública de consulta do PNCP (sem autenticação).
class PncpService {
  /// Espera máxima pedida pelo PNCP (Retry-After) que ainda vale aguardar;
  /// acima disso a varredura para e continua na próxima consulta.
  static const esperaMaxima = Duration(seconds: 60);

  /// Espera quando o 429 vem sem Retry-After.
  static const esperaPadrao = Duration(seconds: 10);

  final Dio _dio;
  final Future<void> Function(Duration) _esperar;

  PncpService({Dio? dio, Future<void> Function(Duration)? esperar})
    : _esperar = esperar ?? Future<void>.delayed,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://pncp.gov.br/api/consulta',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  /// 404 vira [SequenciaInexistente] e 410 vira [CompraExcluida]. No 429
  /// (limite de requisições) aguarda o Retry-After e tenta uma vez mais.
  /// Os demais erros lançam [PncpException].
  Future<SequenciaPncp> consultarCompra(
    String cnpj,
    int ano,
    int sequencial, {
    bool novaTentativa = true,
  }) async {
    final sequencia = 'sequência $sequencial/$ano';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/orgaos/$cnpj/compras/$ano/$sequencial',
      );
      final dados = response.data;
      if (dados == null) {
        throw PncpException(
          'O PNCP retornou uma resposta vazia na $sequencia.',
        );
      }
      return CompraEncontrada(dados);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      switch (status) {
        case 404:
          return const SequenciaInexistente();
        case 410:
          return const CompraExcluida();
        case 429:
          final espera = _retryAfter(e.response!) ?? esperaPadrao;
          if (novaTentativa && espera <= esperaMaxima) {
            await _esperar(espera);
            return consultarCompra(cnpj, ano, sequencial, novaTentativa: false);
          }
          throw PncpException(
            'O PNCP limitou as consultas (erro 429) na $sequencia. '
            'A próxima consulta continua de onde esta parou.',
          );
      }
      throw PncpException(
        e.response == null
            ? 'Não foi possível conectar ao PNCP ($sequencia): ${e.message}'
            : 'O PNCP respondeu com erro $status na $sequencia.',
      );
    }
  }

  // Retry-After pode vir em segundos ou como data HTTP.
  static Duration? _retryAfter(Response<dynamic> response) {
    final valor = response.headers.value('retry-after')?.trim();
    if (valor == null || valor.isEmpty) return null;
    final segundos = int.tryParse(valor);
    if (segundos != null) return Duration(seconds: segundos);
    try {
      final diferenca = HttpDate.parse(valor).difference(DateTime.now());
      return diferenca.isNegative ? Duration.zero : diferenca;
    } on FormatException {
      return null;
    }
  }
}

class PncpException implements Exception {
  final String message;
  const PncpException(this.message);

  @override
  String toString() => message;
}
