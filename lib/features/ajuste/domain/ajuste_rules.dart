/// Regras condicionais do Ajuste conforme o Modelo da Fase IV 2026 v02.
abstract final class AjusteRules {
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
}
