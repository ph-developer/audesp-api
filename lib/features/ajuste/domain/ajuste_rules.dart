/// Regras condicionais do Ajuste conforme o Modelo da Fase IV 2026 v04.
abstract final class AjusteRules {
  static const _tiposContratoComVigencia = <int>{1, 2, 3, 4, 5, 8, 12};

  static const _orgaosFonteRecursos = <int>{1, 10, 13, 20, 25};

  static const _orgaosClassificacaoDespesa = <int>{
    1,
    2,
    3,
    4,
    5,
    6,
    9,
    10,
    13,
    19,
    20,
    25,
    42,
    43,
  };

  static bool exigeFonteRecursos({
    required int? codigoTipoOrgao,
    required bool receita,
  }) {
    return !receita && _orgaosFonteRecursos.contains(codigoTipoOrgao);
  }

  static bool exigeDespesas({
    required int? codigoTipoOrgao,
    required int? tipoContratoId,
    required bool receita,
  }) {
    final empenhoMunicipal =
        tipoContratoId == 7 && _orgaosFonteRecursos.contains(codigoTipoOrgao);
    final processoDeDespesa =
        !receita && _orgaosClassificacaoDespesa.contains(codigoTipoOrgao);
    return empenhoMunicipal || processoDeDespesa;
  }

  static bool exigeDataVigenciaInicio({
    required int? tipoContratoId,
    required bool vigenciaMesesInformada,
  }) {
    return _tiposContratoComVigencia.contains(tipoContratoId) &&
        !vigenciaMesesInformada;
  }

  static bool exigeVigenciaMeses({
    required int? tipoContratoId,
    required bool dataVigenciaInicioInformada,
  }) {
    return _tiposContratoComVigencia.contains(tipoContratoId) &&
        !dataVigenciaInicioInformada;
  }

  static bool exigeDataVigenciaFim({
    required bool dataVigenciaInicioInformada,
  }) {
    return dataVigenciaInicioInformada;
  }

  /// Valida o código local do contrato de um edital sem PNCP.
  static String? validarCodigoContratoSemPncp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o Código do Contrato';
    }
    if (value.trim().length > 25) {
      return 'Máximo 25 caracteres';
    }
    return null;
  }

  /// Valida o formato do `codigoContrato` do PNCP (25 dígitos numéricos).
  ///
  /// Estrutura conforme PNCP / Fase IV AUDESP:
  /// - 14 dígitos: CNPJ do Órgão/Entidade do contrato (posições 1-14)
  /// - 1 dígito: Dígito "2" marcador de contrato (15ª posição)
  /// - 6 dígitos: Número sequencial da contratação/contrato no PNCP (posições 16-21)
  /// - 4 dígitos: Ano do contrato (posições 22-25)
  ///
  /// Retorna `null` se válido ou a mensagem de erro correspondente.
  static String? validarCodigoContrato(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o ID do Contrato PNCP';
    }
    final raw = value.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 25) {
      return 'ID do Contrato PNCP incompleto (25 dígitos)';
    }
    if (raw.length > 25) {
      return 'ID do Contrato PNCP deve ter no máximo 25 dígitos';
    }
    if (raw[14] != '2') {
      return 'O 15º dígito do ID do Contrato PNCP deve ser 2 (marcador de contrato)';
    }
    return null;
  }

  /// Indica se o `codigoContrato` é válido conforme a regra PNCP (25 dígitos e 15º dígito '2').
  static bool isCodigoContratoValido(String? value) =>
      validarCodigoContrato(value) == null;
}
