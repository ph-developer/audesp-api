import 'dart:convert';

/// Envio cujo protocolo ainda pode mudar de situação no AUDESP.
class ProtocoloEmAndamento {
  final int logId;
  final String protocolo;
  final String? statusAtual;

  const ProtocoloEmAndamento({
    required this.logId,
    required this.protocolo,
    this.statusAtual,
  });
}

/// Retorna o JSON da consulta de status do protocolo.
typedef ConsultarProtocolo = Future<String> Function(String protocolo);

typedef SalvarProtocolo =
    Future<void> Function(int logId, String status, String retorno);

/// Consulta os protocolos em andamento e grava as novas situações, para que
/// a fase seguinte seja liberada sem alguém abrir os logs.
abstract final class AtualizacaoProtocolos {
  static const maxPorExecucao = 20;

  /// Erro em um protocolo não impede os demais. [podeContinuar] é conferido
  /// antes de cada consulta: falso quando o token deixou de valer (expirou ou
  /// o AUDESP respondeu 401). Retorna quantos protocolos mudaram de situação.
  static Future<int> executar({
    required Iterable<ProtocoloEmAndamento> pendentes,
    required ConsultarProtocolo consultar,
    required SalvarProtocolo salvar,
    required bool Function() podeContinuar,
  }) async {
    var mudaram = 0;
    for (final pendente in pendentes) {
      if (!podeContinuar()) break;
      try {
        final retorno = await consultar(pendente.protocolo);
        final json = jsonDecode(retorno);
        final status = json is Map ? json['status']?.toString().trim() : null;
        if (status == null || status.isEmpty) continue;
        if (status == pendente.statusAtual?.trim()) continue;
        await salvar(pendente.logId, status, retorno);
        mudaram++;
      } catch (_) {
        continue;
      }
    }
    return mudaram;
  }
}
