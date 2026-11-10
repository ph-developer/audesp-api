import '../../../core/database/app_database.dart';
import '../../estimativa/models/estimativa_model.dart';
import '../../logs/domain/conclusao_envio.dart';
import '../../logs/domain/ultimo_envio.dart';

/// Documentos locais, inclusive ajustes de adesão sem edital vinculado.
class DocumentosProcesso {
  final List<Edital> editais;
  final List<Licitacao> licitacoes;
  final List<Ata> atas;
  final List<Ajuste> ajustes;

  DocumentosProcesso({
    Iterable<Edital> editais = const [],
    Iterable<Licitacao> licitacoes = const [],
    Iterable<Ata> atas = const [],
    Iterable<Ajuste> ajustes = const [],
  }) : editais = List.unmodifiable(editais),
       licitacoes = List.unmodifiable(licitacoes),
       atas = List.unmodifiable(atas),
       ajustes = List.unmodifiable(ajustes);
}

/// Envios registrados de cada tipo de documento e o ambiente ativo, para
/// saber quais fases estão concluídas (protocolo armazenado).
class EnviosProcesso {
  final EnviosIndex editais;
  final EnviosIndex licitacoes;
  final EnviosIndex atas;
  final EnviosIndex ajustes;
  final String baseUrl;

  EnviosProcesso({
    EnviosIndex? editais,
    EnviosIndex? licitacoes,
    EnviosIndex? atas,
    EnviosIndex? ajustes,
    this.baseUrl = '',
  }) : editais = editais ?? EnviosIndex.vazio,
       licitacoes = licitacoes ?? EnviosIndex.vazio,
       atas = atas ?? EnviosIndex.vazio,
       ajustes = ajustes ?? EnviosIndex.vazio;

  /// Sem envios: todo documento enviado conta como legado (concluído).
  static final vazio = EnviosProcesso();

  ConclusaoEnvio edital(Edital edital) => _conclusao(
    edital.status,
    editais,
    DescritorEnvio.edital(
      municipio: edital.municipio,
      entidade: edital.entidade,
      codigoEdital: edital.codigoEdital,
      retificacao: edital.retificacao,
    ),
    edital.retificacaoDescartadaEm,
  );

  ConclusaoEnvio licitacao(Licitacao licitacao) => _conclusao(
    licitacao.status,
    licitacoes,
    DescritorEnvio.licitacao(
      municipio: licitacao.municipio,
      entidade: licitacao.entidade,
      codigoEdital: licitacao.codigoEdital,
      retificacao: licitacao.retificacao,
    ),
    licitacao.retificacaoDescartadaEm,
  );

  ConclusaoEnvio ata(Ata ata) => _conclusao(
    ata.status,
    atas,
    DescritorEnvio.ata(
      municipio: ata.municipio,
      entidade: ata.entidade,
      codigoEdital: ata.codigoEdital,
      codigoAta: ata.codigoAta,
      retificacao: ata.retificacao,
    ),
    ata.retificacaoDescartadaEm,
  );

  ConclusaoEnvio ajuste(Ajuste ajuste) => _conclusao(
    ajuste.status,
    ajustes,
    DescritorEnvio.ajuste(
      municipio: ajuste.municipio,
      entidade: ajuste.entidade,
      codigoEdital: ajuste.codigoEdital,
      codigoAta: ajuste.codigoAta,
      codigoContrato: ajuste.codigoContrato,
      retificacao: ajuste.retificacao,
    ),
    ajuste.retificacaoDescartadaEm,
  );

  // Original e retificações são o mesmo documento: qualquer um deles
  // armazenado conclui a fase.
  ConclusaoEnvio _conclusao(
    String status,
    EnviosIndex index,
    Map<String, Object?> descritor, [
    DateTime? retificacaoDescartadaEm,
  ]) => ConclusaoEnvio.de(
    status: status,
    envios: index.todos(Map.of(descritor)..remove('retificacao')),
    baseUrl: baseUrl,
    retificacaoDescartadaEm: retificacaoDescartadaEm,
  );

  /// Conclusão pelo descritor ([DescritorEnvio]) de um formulário, que pode
  /// ter códigos ainda não salvos. [endpoint] é um dos [EnviosEndpoint].
  ConclusaoEnvio porDescritor(
    String endpoint, {
    required String status,
    required Map<String, Object?> descritor,
    DateTime? retificacaoDescartadaEm,
  }) => _conclusao(
    status,
    switch (endpoint) {
      EnviosEndpoint.edital => editais,
      EnviosEndpoint.licitacao => licitacoes,
      EnviosEndpoint.ata => atas,
      _ => ajustes,
    },
    descritor,
    retificacaoDescartadaEm,
  );
}

/// Documentos vinculados a um edital.
class Processo {
  final Edital edital;
  // Resumo da estimativa de origem (sem itens), para identificação.
  final EstimativaModel? estimativa;
  final List<Licitacao> licitacoes;
  final List<Ata> atas;
  final List<Ajuste> ajustes;
  final EnviosProcesso envios;

  Processo({
    required this.edital,
    this.estimativa,
    required List<Licitacao> licitacoes,
    required List<Ata> atas,
    required List<Ajuste> ajustes,
    EnviosProcesso? envios,
  }) : licitacoes = List.unmodifiable(licitacoes),
       atas = List.unmodifiable(atas),
       ajustes = List.unmodifiable(ajustes),
       envios = envios ?? EnviosProcesso.vazio;

  late final ConclusaoEnvio conclusaoEdital = envios.edital(edital);

  /// Preserva a ordem dos editais e dos documentos em cada vínculo.
  static List<Processo> agrupar({
    required Iterable<Edital> editais,
    required Iterable<Licitacao> licitacoes,
    required Iterable<Ata> atas,
    required Iterable<Ajuste> ajustes,
    Iterable<EstimativaModel> estimativas = const [],
    EnviosProcesso? envios,
  }) {
    final estimativasPorId = {for (final e in estimativas) e.id: e};
    final licitacoesPorEdital = <int, List<Licitacao>>{};
    final atasPorEdital = <int, List<Ata>>{};
    final ajustesPorEdital = <int, List<Ajuste>>{};

    for (final licitacao in licitacoes) {
      (licitacoesPorEdital[licitacao.editalId] ??= []).add(licitacao);
    }
    for (final ata in atas) {
      (atasPorEdital[ata.editalId] ??= []).add(ata);
    }
    for (final ajuste in ajustes) {
      final editalId = ajuste.editalId;
      if (editalId != null) {
        (ajustesPorEdital[editalId] ??= []).add(ajuste);
      }
    }

    return [
      for (final edital in editais)
        Processo(
          edital: edital,
          estimativa: estimativasPorId[edital.estimativaId],
          licitacoes: licitacoesPorEdital[edital.id] ?? [],
          atas: atasPorEdital[edital.id] ?? [],
          ajustes: ajustesPorEdital[edital.id] ?? [],
          envios: envios,
        ),
    ];
  }
}
