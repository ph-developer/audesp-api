import '../models/xsd_licitacao_models.dart';

class XsdSourceNormalizer {
  const XsdSourceNormalizer();

  XsdLicitacaoSource normalize({
    required Map<String, dynamic> edital,
    required Map<String, dynamic> licitacao,
  }) {
    final descritor = licitacao['descritor'] is Map
        ? Map<String, dynamic>.from(licitacao['descritor'] as Map)
        : <String, dynamic>{};
    final descritorEdital = edital['descritor'] is Map
        ? Map<String, dynamic>.from(edital['descritor'] as Map)
        : <String, dynamic>{};
    final itens = (licitacao['itens'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final modalidade = _int(edital['modalidadeId']);

    final publicidade = edital['publicidade'] is Map
        ? Map<String, dynamic>.from(edital['publicidade'] as Map)
        : const <String, dynamic>{};
    final publicacoes =
        (publicidade['publicacoes'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => _date(e['dataPublicacao']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    final dataEdital = _firstDate([
      edital['dataPublicacaoPncp'],
      edital['dataPublicacao'],
      descritorEdital['dataDocumento'],
      publicacoes.firstOrNull,
      edital['dataAberturaProposta'],
    ]);

    final datasSituacao =
        itens
            .map((item) => _date(item['dataSituacaoItem']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    final fontesRecursos =
        (licitacao['fonteRecursosContratacao'] as List? ?? const [])
            .map(_int)
            .where((value) => value > 0)
            .toList();

    return XsdLicitacaoSource(
      modalidadeId: modalidade,
      srp: edital['srp'] == true,
      carona:
          edital['carona'] == true ||
          edital['adesao'] == true ||
          licitacao['carona'] == true,
      municipio: (descritor['municipio'] ?? licitacao['municipio'] ?? '')
          .toString(),
      entidade: (descritor['entidade'] ?? licitacao['entidade'] ?? '')
          .toString(),
      codigoEdital: (descritor['codigoEdital'] ?? edital['codigoEdital'] ?? '')
          .toString(),
      numeroCompra: (edital['numeroCompra'] ?? '').toString(),
      anoCompra: _int(edital['anoCompra'], 2026),
      numeroProcesso: (edital['numeroProcesso'] ?? '').toString(),
      objeto: (edital['objetoCompra'] ?? '').toString(),
      criterioJulgamentoId: _int(edital['criterioJulgamentoId']),
      amparoLegalId: edital['amparoLegalId'] == null
          ? null
          : _int(edital['amparoLegalId']),
      editalData: dataEdital,
      situacaoData: datasSituacao.lastOrNull,
      quitacaoTributosFederais: licitacao['quitacaoTributosFederais'] == true,
      quitacaoTributosEstaduais: licitacao['quitacaoTributosEstaduais'] == true,
      quitacaoTributosMunicipais:
          licitacao['quitacaoTributosMunicipais'] == true,
      declaracaoRecursos: licitacao['declaracaoRecursosContratacao'] == true,
      fontesRecursos: List.unmodifiable(fontesRecursos),
      parecerTecnicoJuridico: licitacao['viabilidadeContratacao'] == 1,
      entregaPropostaData: _date(edital['dataEncerramentoProposta']),
      aberturaData: _date(edital['dataAberturaProposta']),
      itens: itens,
      editalJson: Map.unmodifiable(edital),
      licitacaoJson: Map.unmodifiable(licitacao),
    );
  }

  /// Source-owned values always win. The persisted profile only supplies
  /// information that does not exist in Edital/Licitação.
  XsdLicitacaoProfile mergeProfile({
    required XsdLicitacaoSource source,
    XsdLicitacaoProfile? persisted,
  }) {
    final current =
        persisted ?? XsdLicitacaoProfile(anoAtoDesignacao: DateTime.now().year);
    final importedSources =
        source.fontesRecursos
            .where((value) => value != 99)
            .map((value) => value >= 91 && value <= 98 ? value - 90 : value)
            .toSet()
            .toList()
          ..sort();
    return current.copyWith(
      // Os schemas tornam o bloco opcional; por decisão do módulo ele nunca
      // é enviado, inclusive quando um perfil antigo possuía enquadramento.
      lrf: XsdLrfEnquadramento.omitido,
      situacaoData: source.situacaoData ?? current.situacaoData,
      tributosFederais: source.quitacaoTributosFederais,
      tributosEstaduais: source.quitacaoTributosEstaduais,
      tributosMunicipais: source.quitacaoTributosMunicipais,
      parecerTecnicoJuridico: source.parecerTecnicoJuridico,
      recursos: XsdRecursosProfile(
        declarados: source.declaracaoRecursos,
        valor: source.declaracaoRecursos ? current.recursos.valor : null,
        data: source.declaracaoRecursos ? current.recursos.data : null,
        fontes: source.declaracaoRecursos ? importedSources : const [],
        outrasFontesDescricao: source.declaracaoRecursos
            ? current.recursos.outrasFontesDescricao
            : null,
      ),
      opcionais: {
        ...current.opcionais,
        if (source.licitacaoJson['tipoNatureza'] != null)
          'naturezaLicitacao': source.licitacaoJson['tipoNatureza'],
      },
    );
  }
}

int _int(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

DateTime? _firstDate(List<Object?> values) {
  for (final value in values) {
    final parsed = value is DateTime ? value : _date(value);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : DateTime.tryParse(text);
}
