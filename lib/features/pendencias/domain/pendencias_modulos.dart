import '../../../core/database/app_database.dart';
import '../../logs/domain/conclusao_envio.dart';
import '../../pncp/domain/pncp_pendencias.dart';
import '../../processo/domain/processo.dart';

class PendenciaProtocolo<T> {
  final T documento;
  final ConclusaoEnvio conclusao;
  final Edital? edital;

  const PendenciaProtocolo(this.documento, this.conclusao, {this.edital});
}

/// O mesmo resultado alimenta as abas, os badges e a escolha da tela inicial.
class PendenciasModulos {
  final List<PncpCompra> comprasEdital;
  final List<PncpCompra> comprasDispensadas;
  final List<PendenciaProtocolo<Edital>> editais;
  final List<Edital> criarLicitacao;
  final List<PendenciaProtocolo<Licitacao>> licitacoes;
  final List<PendenciaProtocolo<Ata>> atas;
  final List<PendenciaProtocolo<Ajuste>> ajustes;

  const PendenciasModulos({
    this.comprasEdital = const [],
    this.comprasDispensadas = const [],
    this.editais = const [],
    this.criarLicitacao = const [],
    this.licitacoes = const [],
    this.atas = const [],
    this.ajustes = const [],
  });

  Map<String, int> get contagens => {
    '/edital': comprasEdital.length + editais.length,
    '/licitacao': criarLicitacao.length + licitacoes.length,
    '/ata': atas.length,
    '/ajuste': ajustes.length,
  };
}

abstract final class PendenciasRules {
  static bool protocoloPendente(ConclusaoEnvio conclusao) =>
      switch (conclusao.situacao) {
        SituacaoConclusao.emAnalise ||
        SituacaoConclusao.rejeitado ||
        SituacaoConclusao.excluido => true,
        SituacaoConclusao.naoEnviado || SituacaoConclusao.concluida => false,
      };

  static List<Edital> editaisSemLicitacao(
    DocumentosProcesso documentos,
    EnviosProcesso envios,
  ) {
    final vinculados = documentos.licitacoes.map((l) => l.editalId).toSet();
    return [
      for (final edital in documentos.editais)
        if (!edital.oculto &&
            !vinculados.contains(edital.id) &&
            envios.edital(edital).concluida)
          edital,
    ];
  }

  /// Ocultos continuam casando com compras do PNCP, mas nem eles nem seus
  /// documentos vinculados geram pendências. Adesões sem edital são avaliadas.
  static PendenciasModulos paraUsuario({
    required User user,
    required DocumentosProcesso documentos,
    required EnviosProcesso envios,
    Iterable<PncpCompra> compras = const [],
  }) {
    final editaisPorId = {for (final e in documentos.editais) e.id: e};
    bool visivel(int? editalId) => editaisPorId[editalId]?.oculto != true;
    final podeEdital = user.hasPermission(AppPermissions.edital);
    return PendenciasModulos(
      comprasEdital: podeEdital
          ? PncpPendencias.semEdital(compras, documentos.editais)
          : const [],
      comprasDispensadas: podeEdital
          ? PncpPendencias.dispensadas(compras, documentos.editais)
          : const [],
      editais: podeEdital
          ? _protocolos(
              documentos.editais.where((e) => !e.oculto),
              envios.edital,
              (e) => e,
            )
          : const [],
      criarLicitacao: user.hasPermission(AppPermissions.licitacao)
          ? editaisSemLicitacao(documentos, envios)
          : const [],
      licitacoes: user.hasPermission(AppPermissions.licitacao)
          ? _protocolos(
              documentos.licitacoes.where((l) => visivel(l.editalId)),
              envios.licitacao,
              (l) => editaisPorId[l.editalId],
            )
          : const [],
      atas: user.hasPermission(AppPermissions.ata)
          ? _protocolos(
              documentos.atas.where((a) => visivel(a.editalId)),
              envios.ata,
              (a) => editaisPorId[a.editalId],
            )
          : const [],
      ajustes: user.hasPermission(AppPermissions.ajuste)
          ? _protocolos(
              documentos.ajustes.where((a) => visivel(a.editalId)),
              envios.ajuste,
              (a) => editaisPorId[a.editalId],
            )
          : const [],
    );
  }

  static List<PendenciaProtocolo<T>> _protocolos<T>(
    Iterable<T> documentos,
    ConclusaoEnvio Function(T) conclusaoDe,
    Edital? Function(T) editalDe,
  ) => [
    for (final documento in documentos)
      if (conclusaoDe(documento) case final conclusao
          when protocoloPendente(conclusao))
        PendenciaProtocolo(documento, conclusao, edital: editalDe(documento)),
  ];
}
