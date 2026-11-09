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

  const ConclusaoEnvio(this.situacao, [this.envio]);

  /// Documento enviado sem nenhum log de envio (legado): conta como
  /// concluído para não travar processos antigos.
  static const legado = ConclusaoEnvio(SituacaoConclusao.concluida);

  bool get concluida => situacao == SituacaoConclusao.concluida;

  /// [envios] são todos os envios do documento (original e retificações, de
  /// qualquer ambiente), do mais recente ao mais antigo. Só os do ambiente
  /// de [baseUrl] concluem: um protocolo armazenado no Piloto não vale no
  /// Oficial. Basta um envio armazenado; uma retificação posterior em
  /// análise ou rejeitada não desfaz a conclusão.
  static ConclusaoEnvio de({
    required String status,
    required Iterable<EnvioResumo> envios,
    required String baseUrl,
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
        return ConclusaoEnvio(SituacaoConclusao.concluida, envio);
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
