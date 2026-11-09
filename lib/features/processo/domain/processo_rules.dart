import '../../logs/domain/conclusao_envio.dart';
import 'processo.dart';

/// [pendente]: há licitação, mas nenhuma com protocolo armazenado.
enum SituacaoLicitacao { inexistente, pendente, concluida }

class OpcaoEdital {
  final Processo processo;
  final String? motivoBloqueio;

  const OpcaoEdital({required this.processo, this.motivoBloqueio});

  bool get liberado => motivoBloqueio == null;
}

/// Dependências dos documentos vinculados a um edital.
abstract final class ProcessoRules {
  static List<OpcaoEdital> opcoesAta(Iterable<Processo> processos) => [
    for (final processo in processos)
      if (_editalEnviado(processo) && processo.edital.isSrp)
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
      if (_editalEnviado(processo) &&
          (adesaoParticipacao || !processo.edital.isSrp))
        OpcaoEdital(
          processo: processo,
          motivoBloqueio: motivoBloqueioAjuste(
            processo,
            adesaoParticipacao: adesaoParticipacao,
          ),
        ),
  ];

  // Editais oferecidos nos formulários de Ata e Ajuste: os enviados, mesmo
  // ainda sem armazenamento (o motivo do bloqueio explica), e os já
  // armazenados que voltaram a rascunho para retificação.
  static bool _editalEnviado(Processo processo) =>
      processo.edital.status == 'sent' || processo.conclusaoEdital.concluida;

  static SituacaoLicitacao situacaoLicitacao(Processo processo) {
    if (processo.licitacoes.isEmpty) return SituacaoLicitacao.inexistente;
    return conclusaoLicitacao(processo)!.concluida
        ? SituacaoLicitacao.concluida
        : SituacaoLicitacao.pendente;
  }

  /// A licitação concluída ou, sem nenhuma, a mais adiantada (em análise,
  /// depois rejeitada, excluída e não enviada). null sem licitação.
  static ConclusaoEnvio? conclusaoLicitacao(Processo processo) {
    ConclusaoEnvio? melhor;
    for (final licitacao in processo.licitacoes) {
      final conclusao = processo.envios.licitacao(licitacao);
      if (conclusao.concluida) return conclusao;
      if (melhor == null ||
          _prioridade(conclusao.situacao) > _prioridade(melhor.situacao)) {
        melhor = conclusao;
      }
    }
    return melhor;
  }

  static int _prioridade(SituacaoConclusao situacao) => switch (situacao) {
    SituacaoConclusao.concluida => 4,
    SituacaoConclusao.emAnalise => 3,
    SituacaoConclusao.rejeitado => 2,
    SituacaoConclusao.excluido => 1,
    SituacaoConclusao.naoEnviado => 0,
  };

  static const motivoEditalOculto = 'O edital está oculto no sistema.';

  static String? _motivoEdital(Processo processo) =>
      processo.conclusaoEdital.motivo('edital');

  /// null indica que a licitação do edital pode ser enviada.
  static String? motivoBloqueioLicitacao(Processo processo) {
    if (processo.edital.oculto) return motivoEditalOculto;
    return _motivoEdital(processo);
  }

  /// null indica que a criação está liberada.
  static String? motivoBloqueioAta(Processo processo) {
    if (processo.edital.oculto) return motivoEditalOculto;
    final motivoEdital = _motivoEdital(processo);
    if (motivoEdital != null) return motivoEdital;
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
    if (processo.edital.oculto) return motivoEditalOculto;
    if (adesaoParticipacao) return null;
    final motivoEdital = _motivoEdital(processo);
    if (motivoEdital != null) return motivoEdital;
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

  static String? _motivoBloqueioLicitacao(Processo processo) {
    final conclusao = conclusaoLicitacao(processo);
    if (conclusao == null) return 'O edital ainda não tem licitação.';
    return conclusao.motivo('licitação do edital', feminino: true);
  }

  static ({int atas, int ajustes}) dependentesDe(Processo processo) =>
      (atas: processo.atas.length, ajustes: processo.ajustes.length);
}
