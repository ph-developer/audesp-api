import '../../../core/database/app_database.dart';
import 'processo.dart';

enum SituacaoLicitacao { inexistente, rascunho, enviada }

enum TipoPendencia { criarLicitacao, enviarLicitacao, criarAta, criarAjuste }

class Pendencia {
  final Processo processo;
  final TipoPendencia tipo;

  const Pendencia({required this.processo, required this.tipo});
}

class OpcaoEdital {
  final Processo processo;
  final String? motivoBloqueio;

  const OpcaoEdital({required this.processo, this.motivoBloqueio});

  bool get liberado => motivoBloqueio == null;
}

/// Dependências e pendências dos documentos de um processo.
abstract final class ProcessoRules {
  static List<OpcaoEdital> opcoesAta(Iterable<Processo> processos) => [
    for (final processo in processos)
      if (processo.edital.status == 'sent' && processo.edital.isSrp)
        OpcaoEdital(
          processo: processo,
          motivoBloqueio: motivoBloqueioAta(processo),
        ),
  ];

  static List<OpcaoEdital> opcoesAjuste(
    Iterable<Processo> processos, {
    bool adesaoParticipacao = false,
  }) => [
    for (final processo in processos)
      if (processo.edital.status == 'sent' &&
          (adesaoParticipacao || !processo.edital.isSrp))
        OpcaoEdital(
          processo: processo,
          motivoBloqueio: motivoBloqueioAjuste(
            processo,
            adesaoParticipacao: adesaoParticipacao,
          ),
        ),
  ];

  static SituacaoLicitacao situacaoLicitacao(Iterable<Licitacao> licitacoes) {
    var temLicitacao = false;
    for (final licitacao in licitacoes) {
      if (licitacao.status == 'sent') return SituacaoLicitacao.enviada;
      temLicitacao = true;
    }
    return temLicitacao
        ? SituacaoLicitacao.rascunho
        : SituacaoLicitacao.inexistente;
  }

  /// null indica que a criação está liberada.
  static String? motivoBloqueioAta(Processo processo) {
    if (processo.edital.status != 'sent') {
      return 'O edital ainda não foi enviado ao AUDESP.';
    }
    if (!processo.edital.isSrp) {
      return 'Ata de registro de preços exige edital SRP.';
    }
    return _motivoBloqueioLicitacao(processo);
  }

  static bool podeCriarAta(Processo processo) =>
      motivoBloqueioAta(processo) == null;

  static String? motivoBloqueioAjuste(
    Processo processo, {
    bool adesaoParticipacao = false,
  }) {
    if (adesaoParticipacao) return null;
    if (processo.edital.status != 'sent') {
      return 'O edital ainda não foi enviado ao AUDESP.';
    }
    if (processo.edital.isSrp) {
      return 'Edital com registro de preços gera ata, não ajuste.';
    }
    return _motivoBloqueioLicitacao(processo);
  }

  static bool podeCriarAjuste(
    Processo processo, {
    bool adesaoParticipacao = false,
  }) =>
      motivoBloqueioAjuste(processo, adesaoParticipacao: adesaoParticipacao) ==
      null;

  static String? _motivoBloqueioLicitacao(Processo processo) =>
      switch (situacaoLicitacao(processo.licitacoes)) {
        SituacaoLicitacao.inexistente => 'O edital ainda não tem licitação.',
        SituacaoLicitacao.rascunho =>
          'A licitação do edital ainda não foi enviada ao AUDESP.',
        SituacaoLicitacao.enviada => null,
      };

  static ({int atas, int ajustes}) dependentesDe(Processo processo) =>
      (atas: processo.atas.length, ajustes: processo.ajustes.length);

  static List<Pendencia> pendenciasPara(
    User user,
    Iterable<Processo> processos,
  ) {
    final pendencias = <Pendencia>[];
    final podeLicitacao = user.hasPermission(AppPermissions.licitacao);
    final podeAta = user.hasPermission(AppPermissions.ata);
    final podeAjuste = user.hasPermission(AppPermissions.ajuste);

    for (final processo in processos) {
      final situacao = situacaoLicitacao(processo.licitacoes);
      final isSrp = processo.edital.isSrp;

      if (podeLicitacao && processo.edital.status == 'sent') {
        if (situacao == SituacaoLicitacao.inexistente) {
          pendencias.add(
            Pendencia(processo: processo, tipo: TipoPendencia.criarLicitacao),
          );
        } else if (situacao == SituacaoLicitacao.rascunho) {
          pendencias.add(
            Pendencia(processo: processo, tipo: TipoPendencia.enviarLicitacao),
          );
        }
      }

      if (podeAta &&
          situacao == SituacaoLicitacao.enviada &&
          isSrp &&
          processo.atas.isEmpty) {
        pendencias.add(
          Pendencia(processo: processo, tipo: TipoPendencia.criarAta),
        );
      }

      if (podeAjuste &&
          !isSrp &&
          situacao == SituacaoLicitacao.enviada &&
          processo.ajustes.isEmpty) {
        pendencias.add(
          Pendencia(processo: processo, tipo: TipoPendencia.criarAjuste),
        );
      }
    }
    return pendencias;
  }
}
