import 'dart:convert';

import 'conclusao_envio.dart';

/// Como o campo `retificacao` do descritor é definido no próximo envio.
enum ModoRetificacao {
  /// Nenhum envio aceito no ambiente (ou documento legado, sem log): o
  /// usuário decide, pois o documento pode ter sido prestado por outro
  /// sistema.
  livre,

  /// Há envio aceito no ambiente, mas nenhum armazenado: o AUDESP ainda não
  /// tem o documento, que segue como original.
  original,

  /// Já armazenado no ambiente: só entra como retificação.
  retificacao;

  /// Valor imposto ao campo, ou null quando o usuário decide.
  bool? get valor => switch (this) {
    livre => null,
    original => false,
    retificacao => true,
  };
}

/// Regras da retificação de um documento já armazenado no AUDESP.
abstract final class RetificacaoRules {
  static ModoRetificacao modo(ConclusaoEnvio? conclusao) {
    if (conclusao == null) return ModoRetificacao.livre;
    return switch (conclusao.situacao) {
      SituacaoConclusao.concluida =>
        conclusao.envio == null
            ? ModoRetificacao.livre
            : ModoRetificacao.retificacao,
      SituacaoConclusao.emAnalise ||
      SituacaoConclusao.rejeitado ||
      SituacaoConclusao.excluido => ModoRetificacao.original,
      SituacaoConclusao.naoEnviado => ModoRetificacao.livre,
    };
  }

  /// Documento enviado e armazenado, sem outra retificação em andamento.
  static bool podeRetificar(
    ConclusaoEnvio? conclusao, {
    required bool enviado,
  }) =>
      enviado &&
      conclusao != null &&
      conclusao.concluida &&
      conclusao.retificacao == null;

  /// Há versão armazenada para restaurar e a retificação está em rascunho
  /// ou foi rejeitada. Em análise, é preciso aguardar o AUDESP.
  static bool podeDescartar(
    ConclusaoEnvio? conclusao, {
    required bool enviado,
  }) =>
      conclusao != null &&
      conclusao.concluida &&
      conclusao.envio != null &&
      (!enviado || conclusao.retificacaoRejeitada);

  /// [documentoJson] com `descritor.retificacao` trocado.
  static String marcar(String documentoJson, {required bool retificacao}) {
    final doc = _documento(documentoJson);
    final descritor = doc['descritor'];
    doc['descritor'] = {
      if (descritor is Map<String, dynamic>) ...descritor,
      'retificacao': retificacao,
    };
    return jsonEncode(doc);
  }

  /// `descritor.retificacao` do JSON de um envio.
  static bool retificacaoDe(String documentoJson) {
    final descritor = _documento(documentoJson)['descritor'];
    return descritor is Map<String, dynamic> &&
        descritor['retificacao'] == true;
  }

  static Map<String, dynamic> _documento(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('O documento não é um objeto JSON.');
    }
    return decoded;
  }
}
