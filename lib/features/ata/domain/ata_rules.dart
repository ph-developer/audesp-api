import '../../licitacao/domain/licitacao_referencia.dart';

/// Regras condicionais da Ata conforme o Modelo da Fase IV 2026 v04.
abstract final class AtaRules {
  static String? validarItens(
    Iterable<int> numeros, {
    Set<int>? numerosLicitacao,
  }) => LicitacaoReferencia.validarItens(
    numeros,
    numerosLicitacao: numerosLicitacao,
  );
}
