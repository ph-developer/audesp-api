import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openCnpjServiceProvider = Provider<OpenCnpjService>((ref) {
  return OpenCnpjService();
});

class OpenCnpjService {
  final Dio _dio;
  final Map<String, OpenCnpjEmpresa> _cache = {};

  OpenCnpjService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.opencnpj.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  Future<OpenCnpjEmpresa> consultarEmpresa(String cnpj) async {
    final cnpjNormalizado = cnpj
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{12}\d{2}$').hasMatch(cnpjNormalizado)) {
      throw const OpenCnpjException('CNPJ inválido.');
    }

    final valorEmCache = _cache[cnpjNormalizado];
    if (valorEmCache != null) return valorEmCache;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/$cnpjNormalizado',
        queryParameters: const {'datasets': 'receita'},
      );
      final data = response.data;
      if (data == null) {
        throw const OpenCnpjException('Resposta vazia da OpenCNPJ.');
      }

      final empresa = OpenCnpjEmpresa(
        razaoSocial: data['razao_social']?.toString().trim() ?? '',
        declaracaoMeEpp: classificarDeclaracaoMeEpp(
          porteEmpresa: data['porte_empresa']?.toString(),
          opcaoMei: data['opcao_mei']?.toString(),
        ),
      );
      _cache[cnpjNormalizado] = empresa;
      return empresa;
    } on OpenCnpjException {
      rethrow;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        throw const OpenCnpjException('CNPJ inválido para a OpenCNPJ.');
      }
      if (statusCode == 404) {
        throw const OpenCnpjException('CNPJ não encontrado na OpenCNPJ.');
      }
      throw OpenCnpjException(
        'Falha ao consultar a OpenCNPJ${statusCode == null ? '' : ' (HTTP $statusCode)'}.',
      );
    }
  }

  static int classificarDeclaracaoMeEpp({
    String? porteEmpresa,
    String? opcaoMei,
  }) {
    final porte = _normalizar(porteEmpresa ?? '');
    if (porte.contains('EMPRESA DE PEQUENO PORTE') ||
        RegExp(r'\bEPP\b').hasMatch(porte)) {
      return 2;
    }
    if (porte.contains('MICRO EMPRESA') ||
        porte.contains('MICROEMPRESA') ||
        RegExp(r'\bME\b').hasMatch(porte) ||
        (opcaoMei ?? '').trim().toUpperCase() == 'S') {
      return 1;
    }
    return 3;
  }

  static String _normalizar(String valor) {
    return valor
        .trim()
        .toUpperCase()
        .replaceAll(RegExp('[ÀÁÂÃÄ]'), 'A')
        .replaceAll(RegExp('[ÈÉÊË]'), 'E')
        .replaceAll(RegExp('[ÌÍÎÏ]'), 'I')
        .replaceAll(RegExp('[ÒÓÔÕÖ]'), 'O')
        .replaceAll(RegExp('[ÙÚÛÜ]'), 'U')
        .replaceAll('Ç', 'C');
  }
}

class OpenCnpjEmpresa {
  final String razaoSocial;
  final int declaracaoMeEpp;

  const OpenCnpjEmpresa({
    required this.razaoSocial,
    required this.declaracaoMeEpp,
  });
}

class OpenCnpjException implements Exception {
  final String message;

  const OpenCnpjException(this.message);

  @override
  String toString() => message;
}
