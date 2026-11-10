import 'ultimo_envio.dart';

enum SituacaoConclusao {
  /// Nenhum envio aceito no ambiente ativo.
  naoEnviado,

  /// Protocolo recebido, aguardando o armazenamento pelo AUDESP.
  emAnalise,
  rejeitado,
  excluido,

  /// Protocolo armazenado: a fase está concluída e libera a próxima.
  concluida,
}

/// Situação de um documento para liberar a fase seguinte do processo.
class ConclusaoEnvio {
  final SituacaoConclusao situacao;

  /// Envio que define a situação, quando há um.
  final EnvioResumo? envio;

  /// Retificação enviada depois do armazenamento e ainda em análise ou
  /// rejeitada. A fase continua concluída, mas a retificação é uma pendência.
  final EnvioResumo? retificacao;

  const ConclusaoEnvio(this.situacao, [this.envio, this.retificacao]);

  /// Documento enviado sem nenhum log de envio (legado): conta como
  /// concluído para não travar processos antigos.
  static const legado = ConclusaoEnvio(SituacaoConclusao.concluida);

  bool get concluida => situacao == SituacaoConclusao.concluida;

  bool get retificacaoRejeitada =>
      retificacao?.situacao == SituacaoEnvio.rejeitado;

  /// Envio que uma pendência mostra: a retificação pendente ou o que define
  /// a situação.
  EnvioResumo? get envioPendente => retificacao ?? envio;

  /// [envios] são todos os envios do documento (original e retificações, de
  /// qualquer ambiente), do mais recente ao mais antigo. Só os do ambiente
  /// de [baseUrl] concluem: um protocolo armazenado no Piloto não vale no
  /// Oficial. Basta um envio armazenado; uma retificação posterior em
  /// análise ou rejeitada não desfaz a conclusão e fica em [retificacao],
  /// salvo se foi descartada ([retificacaoDescartadaEm] igual ou posterior
  /// ao envio dela).
  static ConclusaoEnvio de({
    required String status,
    required Iterable<EnvioResumo> envios,
    required String baseUrl,
    DateTime? retificacaoDescartadaEm,
  }) {
    final aceitos = envios.where((e) => e.sucesso).toList();
    if (aceitos.isEmpty) {
      return status == 'sent'
          ? legado
          : const ConclusaoEnvio(SituacaoConclusao.naoEnviado);
    }
    final doAmbiente = aceitos.where((e) => e.doAmbiente(baseUrl)).toList();
    for (final envio in doAmbiente) {
      if (envio.armazenou) {
        return ConclusaoEnvio(
          SituacaoConclusao.concluida,
          envio,
          _retificacaoPendente(
            doAmbiente.first,
            envio,
            retificacaoDescartadaEm,
          ),
        );
      }
    }
    if (doAmbiente.isEmpty) {
      return const ConclusaoEnvio(SituacaoConclusao.naoEnviado);
    }
    final ultimo = doAmbiente.first;
    return ConclusaoEnvio(switch (ultimo.situacao) {
      SituacaoEnvio.rejeitado => SituacaoConclusao.rejeitado,
      SituacaoEnvio.encerrado => SituacaoConclusao.excluido,
      _ => SituacaoConclusao.emAnalise,
    }, ultimo);
  }

  static EnvioResumo? _retificacaoPendente(
    EnvioResumo ultimo,
    EnvioResumo armazenado,
    DateTime? descartadaEm,
  ) {
    if (identical(ultimo, armazenado)) return null;
    // Um reenvio do original parado em "Recebido" não é retificação.
    if (ultimo.descritor['retificacao'] != true) return null;
    final pendente =
        ultimo.situacao == SituacaoEnvio.rejeitado ||
        ultimo.situacao == SituacaoEnvio.emAndamento;
    if (!pendente) return null;
    if (descartadaEm != null && !ultimo.timestamp.isAfter(descartadaEm)) {
      return null;
    }
    return ultimo;
  }

  /// Texto da pendência: o da retificação pendente ou o de [motivo].
  String? motivoPendencia(String nome, {bool feminino = false}) {
    final pendente = retificacao;
    if (pendente == null) return motivo(nome, feminino: feminino);
    final d = feminino ? 'da' : 'do';
    return retificacaoRejeitada
        ? 'A retificação $d $nome foi rejeitada pelo AUDESP. Corrija e '
              'reenvie, ou descarte a retificação.'
        : 'A retificação $d $nome ainda não foi armazenada pelo AUDESP '
              '(situação: ${pendente.rotulo}).';
  }

  /// Por que a fase seguinte está bloqueada, ou null quando concluída.
  /// [nome] vem sem artigo ("edital", "licitação do edital").
  String? motivo(String nome, {bool feminino = false}) {
    final o = feminino ? 'A' : 'O';
    final d = feminino ? 'da' : 'do';
    return switch (situacao) {
      SituacaoConclusao.concluida => null,
      SituacaoConclusao.naoEnviado =>
        '$o $nome ainda não foi ${feminino ? 'enviada' : 'enviado'} ao AUDESP.',
      SituacaoConclusao.emAnalise =>
        'O protocolo $d $nome ainda não foi armazenado pelo AUDESP '
            '(situação: ${envio?.rotulo ?? 'Enviado'}).',
      SituacaoConclusao.rejeitado =>
        'O protocolo $d $nome foi rejeitado pelo AUDESP. Corrija e reenvie.',
      SituacaoConclusao.excluido =>
        'O envio $d $nome foi excluído do AUDESP. Envie novamente.',
    };
  }
}
