import '../../licitacao/domain/licitacao_referencia.dart';

/// Regras condicionais do Ajuste conforme o Modelo da Fase IV 2026 v04.
abstract final class AjusteRules {
  static const objetosPorCategoria = <int, Set<int>>{
    1: {1, 2},
    2: {3, 4, 5, 6, 7, 8, 9, 10, 11},
    3: {12, 13, 14},
    4: {15},
    5: {16},
    6: {17},
    7: {18, 19},
    8: {20, 21, 22, 23, 24, 25, 26, 27},
    9: {18, 19},
    10: {28},
    11: {29},
  };

  static String? validarTipoObjetoContrato({
    required int? categoriaProcessoId,
    required int? tipoObjetoContrato,
  }) {
    if (categoriaProcessoId == null) {
      return 'Selecione a categoria do processo.';
    }
    if (tipoObjetoContrato == null) {
      return 'Selecione o tipo de objeto do contrato.';
    }
    if (!(objetosPorCategoria[categoriaProcessoId]?.contains(
          tipoObjetoContrato,
        ) ??
        false)) {
      return 'O objeto do contrato $tipoObjetoContrato não é permitido para a categoria do processo $categoriaProcessoId.';
    }
    return null;
  }

  static String? validarCodigoEditalAdesao(String? value) {
    final raw = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (raw.length != 25) {
      return 'Informe o ID de Contratação PNCP da adesão com 25 dígitos.';
    }
    return null;
  }

  static String? validarCodigoAtaAdesao(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.replaceAll(RegExp(r'\D'), '');
    if (raw.length != 31) {
      return 'Informe o ID da Ata PNCP da adesão com 31 dígitos ou deixe o campo vazio.';
    }
    return null;
  }

  static String? validarItens(
    Iterable<int> numeros, {
    required bool adesaoParticipacao,
    Set<int>? numerosLicitacao,
  }) => LicitacaoReferencia.validarItens(
    numeros,
    numerosLicitacao: adesaoParticipacao ? null : numerosLicitacao,
  );

  static String? validarEnvio(
    Map<String, dynamic> documento, {
    Set<int>? numerosLicitacao,
  }) {
    final descritor = documento['descritor'] as Map<String, dynamic>? ?? {};
    final adesao = descritor['adesaoParticipacao'] == true;
    if (adesao) {
      final erroCodigos =
          validarCodigoEditalAdesao(descritor['codigoEdital'] as String?) ??
          validarCodigoAtaAdesao(descritor['codigoAta'] as String?);
      if (erroCodigos != null) return erroCodigos;
    }
    return validarTipoObjetoContrato(
          categoriaProcessoId: documento['categoriaProcessoId'] as int?,
          tipoObjetoContrato: documento['tipoObjetoContrato'] as int?,
        ) ??
        validarItens(
          (documento['itens'] as List<dynamic>? ?? []).map(
            (e) => (e as num).toInt(),
          ),
          adesaoParticipacao: adesao,
          numerosLicitacao: numerosLicitacao,
        );
  }

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
