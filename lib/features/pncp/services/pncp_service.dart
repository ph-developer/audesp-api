import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pncp_varredura.dart';
import '../domain/pncp_atas_varredura.dart';

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
  }) => _consultar(
    cnpj,
    ano,
    sequencial,
    contrato: false,
    novaTentativa: novaTentativa,
  );

  /// Contratos usam /api/pncp; /api/consulta não atende esta rota.
  /// Aplica o mesmo tratamento de 404, 410 e 429 das compras.
  Future<SequenciaPncp> consultarContrato(
    String cnpj,
    int ano,
    int sequencial, {
    bool novaTentativa = true,
  }) => _consultar(
    cnpj,
    ano,
    sequencial,
    contrato: true,
    novaTentativa: novaTentativa,
  );

  Future<SequenciaPncp> _consultar(
    String cnpj,
    int ano,
    int sequencial, {
    required bool contrato,
    required bool novaTentativa,
  }) async {
    final sequencia =
        'sequência ${contrato ? 'de contrato ' : ''}$sequencial/$ano';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        contrato
            ? 'https://pncp.gov.br/api/pncp/v1/orgaos/$cnpj/contratos/$ano/$sequencial'
            : '/v1/orgaos/$cnpj/compras/$ano/$sequencial',
      );
      final dados = response.data;
      if (dados == null) {
        throw PncpException(
          'O PNCP retornou uma resposta vazia na $sequencia.',
        );
      }
      return contrato ? ContratoEncontrado(dados) : CompraEncontrada(dados);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      switch (status) {
        case 404:
          return const SequenciaInexistente();
        case 410:
          return contrato ? const ContratoExcluido() : const CompraExcluida();
        case 429:
          final espera = _retryAfter(e.response!) ?? esperaPadrao;
          if (novaTentativa && espera <= esperaMaxima) {
            await _esperar(espera);
            return _consultar(
              cnpj,
              ano,
              sequencial,
              contrato: contrato,
              novaTentativa: false,
            );
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

  /// A primeira sequência é a da compra. As listas podem vir paginadas.
  Future<PaginaAtasPncp> consultarAtasCompra(
    String cnpj,
    int ano,
    int sequencial,
    int pagina,
  ) async => _paginaAtas(
    await _consultarAta(
      'https://pncp.gov.br/api/pncp/v1/orgaos/$cnpj/compras/$ano/$sequencial/atas',
      contexto: 'atas da compra $sequencial/$ano',
      parametros: {'pagina': pagina},
      ausenciaPermitida: true,
    ),
  );

  Future<PaginaAtasPncp> consultarAtasAtualizadas(
    String cnpj,
    DateTime inicio,
    DateTime fim,
    int pagina,
  ) async => _paginaAtas(
    await _consultarAta(
      'https://pncp.gov.br/api/consulta/v1/atas/atualizacao',
      contexto: 'atas atualizadas (página $pagina)',
      parametros: {
        'cnpj': cnpj,
        'dataInicial': _dataConsulta(inicio),
        'dataFinal': _dataConsulta(fim),
        'pagina': pagina,
        'tamanhoPagina': 500,
      },
    ),
  );

  /// O detalhe é usado antes de abrir o formulário; em caso de falha o
  /// formulário conserva os dados salvos e ainda revalida a pendência.
  Future<Map<String, dynamic>> consultarAta(
    String cnpj,
    int ano,
    int sequencialCompra,
    int sequencialAta,
  ) async {
    final dados = await _consultarAta(
      'https://pncp.gov.br/api/pncp/v1/orgaos/$cnpj/compras/$ano/$sequencialCompra/atas/$sequencialAta',
      contexto: 'ata $sequencialAta da compra $sequencialCompra/$ano',
    );
    if (dados == null) {
      throw const PncpException('O PNCP retornou uma ata vazia.');
    }
    return dados;
  }

  Future<Map<String, dynamic>?> _consultarAta(
    String url, {
    required String contexto,
    Map<String, dynamic>? parametros,
    bool ausenciaPermitida = false,
    bool novaTentativa = true,
  }) async {
    try {
      // dynamic permite reconhecer o 204 de corpo vazio antes de ler o JSON.
      final resposta = await _dio.get<dynamic>(
        url,
        queryParameters: parametros,
      );
      if (resposta.statusCode == 204) return null;
      if (resposta.data is! Map<String, dynamic>) {
        throw PncpException(
          'O PNCP retornou uma resposta inválida em $contexto.',
        );
      }
      return resposta.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (ausenciaPermitida && (status == 404 || status == 410)) return null;
      if (status == 429) {
        final espera = _retryAfter(e.response!) ?? esperaPadrao;
        if (novaTentativa && espera <= esperaMaxima) {
          await _esperar(espera);
          return _consultarAta(
            url,
            contexto: contexto,
            parametros: parametros,
            ausenciaPermitida: ausenciaPermitida,
            novaTentativa: false,
          );
        }
        throw PncpException(
          'O PNCP limitou as consultas (erro 429) em $contexto. '
          'A próxima consulta continua de onde esta parou.',
        );
      }
      throw PncpException(
        e.response == null
            ? 'Não foi possível conectar ao PNCP ($contexto): ${e.message}'
            : 'O PNCP respondeu com erro $status em $contexto.',
      );
    }
  }

  static PaginaAtasPncp _paginaAtas(Map<String, dynamic>? resposta) {
    if (resposta == null) return const PaginaAtasPncp();
    final dados = resposta['data'];
    final total = resposta['totalPaginas'];
    if (dados is! List ||
        dados.any((d) => d is! Map<String, dynamic>) ||
        total is! num ||
        !total.isFinite ||
        total < 0 ||
        total != total.toInt()) {
      throw const PncpException('O PNCP retornou uma página de atas inválida.');
    }
    return PaginaAtasPncp(
      dados: dados.cast<Map<String, dynamic>>(),
      totalPaginas: total.toInt(),
    );
  }

  static String _dataConsulta(DateTime data) =>
      '${data.year}${data.month.toString().padLeft(2, '0')}${data.day.toString().padLeft(2, '0')}';

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
