import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../logs/domain/conclusao_envio.dart';
import '../../logs/domain/ultimo_envio.dart';
import '../../processo/domain/processo.dart';
import 'ajuste_documento.dart';

enum MotivoReenvio {
  /// Protocolo parado em "Recebido" por um problema do AUDESP.
  recebido,

  /// Rejeitado só pela RN012_AJUSTE com o documento salvo usando apenas
  /// `dataVigenciaInicio`. O reenvio inclui as duas grafias.
  vigenciaRejeitada,
}

/// Ajuste enviado que pode ser reenviado sem edição no ambiente ativo.
class AjusteRecebido {
  static const erroVigencia = 'RN012_AJUSTE';

  final Ajuste ajuste;
  final EnvioResumo envio;
  final MotivoReenvio motivo;

  const AjusteRecebido(
    this.ajuste,
    this.envio, [
    this.motivo = MotivoReenvio.recebido,
  ]);

  /// Já concluídos (algum envio armazenado) e ajustes de editais ocultos
  /// ficam de fora. Rejeitados com outros erros, ou cujo documento não usa
  /// o nome documentado, precisam de correção e também ficam de fora.
  static List<AjusteRecebido> listar(
    DocumentosProcesso documentos,
    EnviosProcesso envios,
  ) {
    final ocultos = {
      for (final e in documentos.editais)
        if (e.oculto) e.id,
    };
    final lista = <AjusteRecebido>[];
    for (final ajuste in documentos.ajustes) {
      if (ajuste.status != 'sent' || ocultos.contains(ajuste.editalId)) {
        continue;
      }
      final conclusao = envios.ajuste(ajuste);
      final envio = conclusao.envio;
      if (envio == null) continue;
      final motivo = switch (conclusao.situacao) {
        SituacaoConclusao.emAnalise
            when protocoloPodeSerReenviado(envio.statusProtocolo) =>
          MotivoReenvio.recebido,
        SituacaoConclusao.rejeitado
            when _soErroVigencia(envio) &&
                _usaNomeDocumentado(ajuste.documentoJson) =>
          MotivoReenvio.vigenciaRejeitada,
        _ => null,
      };
      if (motivo != null) lista.add(AjusteRecebido(ajuste, envio, motivo));
    }
    return lista;
  }

  static bool _soErroVigencia(EnvioResumo envio) =>
      envio.codigosErro.isNotEmpty &&
      envio.codigosErro.every((c) => c.trim().toUpperCase() == erroVigencia);

  static bool _usaNomeDocumentado(String documentoJson) {
    try {
      final doc = jsonDecode(documentoJson);
      return doc is Map<String, dynamic> &&
          doc[AjusteDocumento.campoVigenciaInicioDocumentado] != null &&
          doc[AjusteDocumento.campoVigenciaInicio] == null;
    } on FormatException {
      return false;
    }
  }
}
