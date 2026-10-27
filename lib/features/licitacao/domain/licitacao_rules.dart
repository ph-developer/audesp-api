/// Regras condicionais da Licitação conforme o Modelo da Fase IV 2026 v04.
abstract final class LicitacaoRules {
  static String? validarPercentualGarantia({
    required int? exigenciaGarantiaLicitantes,
    required num? percentualValor,
  }) {
    if (exigenciaGarantiaLicitantes != 1) return null;
    if (percentualValor == null) {
      return 'Informe o percentual da garantia quando a exigência for "Sim".';
    }
    if (!percentualValor.isFinite ||
        percentualValor < 0 ||
        percentualValor > 100) {
      return 'O percentual da garantia deve estar entre 0 e 100.';
    }
    return null;
  }

  static String? validarNomeIndice({
    required int? tipoIndice,
    required String? nomeIndice,
  }) {
    if (tipoIndice != 8) return null;
    final nome = nomeIndice?.trim() ?? '';
    if (nome.length < 3 || nome.length > 50) {
      return 'Informe o nome do índice "Outro" com 3 a 50 caracteres.';
    }
    return null;
  }

  static String? validarEnvio(Map<String, dynamic> documento) {
    final erroGarantia = validarPercentualGarantia(
      exigenciaGarantiaLicitantes:
          documento['exigenciaGarantiaLicitantes'] as int?,
      percentualValor: documento['percentualValor'] as num?,
    );
    if (erroGarantia != null) return erroGarantia;

    for (final indice
        in documento['indicesEconomicos'] as List<dynamic>? ?? []) {
      final erroNome = validarNomeIndice(
        tipoIndice: indice['tipoIndice'] as int?,
        nomeIndice: indice['nomeIndice'] as String?,
      );
      if (erroNome != null) return erroNome;
    }
    return null;
  }
}
