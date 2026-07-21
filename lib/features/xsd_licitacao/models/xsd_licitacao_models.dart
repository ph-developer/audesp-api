import 'dart:convert';

enum XsdLicitacaoVariant { nao1, nao3 }

enum XsdObjetoClassificacao {
  comprasServicos,
  tecnologiaInformacao,
  obrasEngenharia,
}

enum XsdLrfEnquadramento { omitido, artigo16, artigo17, naoSeEnquadra }

class XsdValidationResult {
  final bool isValid;
  final String? message;
  final int? line;
  final int? column;

  const XsdValidationResult.valid()
    : isValid = true,
      message = null,
      line = null,
      column = null;

  const XsdValidationResult.invalid(this.message, {this.line, this.column})
    : isValid = false;

  String get displayMessage {
    final position = line == null
        ? ''
        : ' (linha $line${column == null ? '' : ', coluna $column'})';
    return '${message ?? 'XML inválido'}$position';
  }
}

class XsdBuildResult {
  final String xml;
  final String markdown;
  final XsdLicitacaoVariant variant;
  final String baseName;
  final String xmlFileName;
  final String markdownFileName;
  final XsdValidationResult validation;

  const XsdBuildResult({
    required this.xml,
    required this.markdown,
    required this.variant,
    required this.baseName,
    required this.validation,
  }) : xmlFileName = '$baseName.xml',
       markdownFileName = '$baseName.md';
}

class XsdComissaoMembro {
  final int? id;
  final String cpf;
  final String nome;
  final int atribuicao;
  final String cargo;
  final int naturezaCargo;

  const XsdComissaoMembro({
    this.id,
    required this.cpf,
    required this.nome,
    required this.atribuicao,
    required this.cargo,
    required this.naturezaCargo,
  });

  XsdComissaoMembro copyWith({int? atribuicao}) => XsdComissaoMembro(
    id: id,
    cpf: cpf,
    nome: nome,
    atribuicao: atribuicao ?? this.atribuicao,
    cargo: cargo,
    naturezaCargo: naturezaCargo,
  );

  Map<String, dynamic> toJson() => {
    'cpf': cpf,
    'nome': nome,
    'atribuicao': atribuicao,
    'cargo': cargo,
    'naturezaCargo': naturezaCargo,
  };

  factory XsdComissaoMembro.fromJson(Map<String, dynamic> json) =>
      XsdComissaoMembro(
        cpf: json['cpf']?.toString() ?? '',
        nome: json['nome']?.toString() ?? '',
        atribuicao: _asInt(json['atribuicao'], 1),
        cargo: json['cargo']?.toString() ?? '',
        naturezaCargo: _asInt(json['naturezaCargo'], 1),
      );
}

class XsdPublicacao {
  final int veiculo;
  final DateTime data;
  final String? descricao;
  final bool oficial;

  const XsdPublicacao({
    required this.veiculo,
    required this.data,
    this.descricao,
    this.oficial = true,
  });

  Map<String, dynamic> toJson() => {
    'veiculo': veiculo,
    'data': _date(data),
    'descricao': descricao,
    'oficial': oficial,
  };

  factory XsdPublicacao.fromJson(Map<String, dynamic> json) => XsdPublicacao(
    veiculo: _asInt(json['veiculo'], 1),
    data: DateTime.parse(json['data'].toString()),
    descricao: json['descricao']?.toString(),
    oficial: json['oficial'] != false,
  );
}

class XsdOrcamento {
  final String documento;
  final double valorUnitario;
  final double quantidade;
  final String unidade;
  final DateTime data;

  const XsdOrcamento({
    required this.documento,
    required this.valorUnitario,
    required this.quantidade,
    required this.unidade,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'documento': documento,
    'valorUnitario': valorUnitario,
    'quantidade': quantidade,
    'unidade': unidade,
    'data': _date(data),
  };

  factory XsdOrcamento.fromJson(Map<String, dynamic> json) => XsdOrcamento(
    documento: json['documento']?.toString() ?? '',
    valorUnitario: _asDouble(json['valorUnitario']),
    quantidade: _asDouble(json['quantidade']),
    unidade: json['unidade']?.toString() ?? '',
    data: DateTime.parse(json['data'].toString()),
  );
}

class XsdLoteProfile {
  final int numero;
  final int tipoExecucao;
  final int classificacaoEconomica;
  final List<XsdOrcamento> orcamentos;

  const XsdLoteProfile({
    required this.numero,
    this.tipoExecucao = 1,
    this.classificacaoEconomica = 1,
    this.orcamentos = const [],
  });

  Map<String, dynamic> toJson() => {
    'numero': numero,
    'tipoExecucao': tipoExecucao,
    'classificacaoEconomica': classificacaoEconomica,
    'orcamentos': orcamentos.map((e) => e.toJson()).toList(),
  };

  factory XsdLoteProfile.fromJson(Map<String, dynamic> json) => XsdLoteProfile(
    numero: _asInt(json['numero'], 1),
    tipoExecucao: _asInt(json['tipoExecucao'], 1),
    classificacaoEconomica: _asInt(json['classificacaoEconomica'], 1),
    orcamentos: _mapList(json['orcamentos'], XsdOrcamento.fromJson),
  );
}

class XsdRecursosProfile {
  final bool declarados;
  final double? valor;
  final DateTime? data;
  final List<int> fontes;
  final String? outrasFontesDescricao;

  const XsdRecursosProfile({
    this.declarados = false,
    this.valor,
    this.data,
    this.fontes = const [],
    this.outrasFontesDescricao,
  });

  Map<String, dynamic> toJson() => {
    'declarados': declarados,
    'valor': valor,
    'data': data == null ? null : _date(data!),
    'fontes': fontes,
    'outrasFontesDescricao': outrasFontesDescricao,
  };

  factory XsdRecursosProfile.fromJson(Map<String, dynamic> json) =>
      XsdRecursosProfile(
        declarados: json['declarados'] == true,
        valor: json['valor'] == null ? null : _asDouble(json['valor']),
        data: _nullableDate(json['data']),
        fontes: (json['fontes'] as List? ?? const [])
            .map((e) => _asInt(e, 0))
            .where((e) => e > 0)
            .toList(),
        outrasFontesDescricao: json['outrasFontesDescricao']?.toString(),
      );
}

class XsdLicitacaoProfile {
  static const revision = '2026_A';

  final XsdObjetoClassificacao objetoClassificacao;
  final bool subcontratacao;
  final bool lei13121;
  final XsdLrfEnquadramento lrf;
  final bool? estimativaTrienal;
  final bool? adequacaoPlano;
  final bool? metasResultado;
  final bool? medidasCompensacao;
  final bool? previsaoPpaLdo;
  final bool parecerTecnicoJuridico;
  final bool tributosFederais;
  final bool tributosEstaduais;
  final bool tributosMunicipais;
  final bool resolucao072014;
  final DateTime? julgamentoData;
  final DateTime? situacaoData;
  final DateTime? homologacaoData;
  final DateTime? adjudicacaoData;
  final DateTime? ratificacaoData;
  final DateTime? finalizacaoProcessoData;
  final int? fundamentoLegalCodigo;
  final List<XsdComissaoMembro> comissao;
  final String numAtoDesignacao;
  final int anoAtoDesignacao;
  final DateTime? atoDesignacaoData;
  final DateTime? atoDesignacaoInicio;
  final DateTime? atoDesignacaoFim;
  final int tipoComissao;
  final List<XsdLoteProfile> lotes;
  final List<XsdPublicacao> publicacoes;
  final XsdRecursosProfile recursos;
  final Map<String, dynamic> opcionais;

  const XsdLicitacaoProfile({
    this.objetoClassificacao = XsdObjetoClassificacao.comprasServicos,
    this.subcontratacao = false,
    this.lei13121 = false,
    this.lrf = XsdLrfEnquadramento.omitido,
    this.estimativaTrienal,
    this.adequacaoPlano,
    this.metasResultado,
    this.medidasCompensacao,
    this.previsaoPpaLdo,
    this.parecerTecnicoJuridico = false,
    this.tributosFederais = false,
    this.tributosEstaduais = false,
    this.tributosMunicipais = false,
    this.resolucao072014 = false,
    this.julgamentoData,
    this.situacaoData,
    this.homologacaoData,
    this.adjudicacaoData,
    this.ratificacaoData,
    this.finalizacaoProcessoData,
    this.fundamentoLegalCodigo,
    this.comissao = const [],
    this.numAtoDesignacao = '',
    this.anoAtoDesignacao = 2026,
    this.atoDesignacaoData,
    this.atoDesignacaoInicio,
    this.atoDesignacaoFim,
    this.tipoComissao = 1,
    this.lotes = const [],
    this.publicacoes = const [],
    this.recursos = const XsdRecursosProfile(),
    this.opcionais = const {},
  });

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'objetoClassificacao': objetoClassificacao.name,
    'subcontratacao': subcontratacao,
    'lei13121': lei13121,
    'lrf': lrf.name,
    'estimativaTrienal': estimativaTrienal,
    'adequacaoPlano': adequacaoPlano,
    'metasResultado': metasResultado,
    'medidasCompensacao': medidasCompensacao,
    'previsaoPpaLdo': previsaoPpaLdo,
    'parecerTecnicoJuridico': parecerTecnicoJuridico,
    'tributosFederais': tributosFederais,
    'tributosEstaduais': tributosEstaduais,
    'tributosMunicipais': tributosMunicipais,
    'resolucao072014': resolucao072014,
    'julgamentoData': _dateOrNull(julgamentoData),
    'situacaoData': _dateOrNull(situacaoData),
    'homologacaoData': _dateOrNull(homologacaoData),
    'adjudicacaoData': _dateOrNull(adjudicacaoData),
    'ratificacaoData': _dateOrNull(ratificacaoData),
    'finalizacaoProcessoData': _dateOrNull(finalizacaoProcessoData),
    'fundamentoLegalCodigo': fundamentoLegalCodigo,
    'comissao': comissao.map((e) => e.toJson()).toList(),
    'numAtoDesignacao': numAtoDesignacao,
    'anoAtoDesignacao': anoAtoDesignacao,
    'atoDesignacaoData': _dateOrNull(atoDesignacaoData),
    'atoDesignacaoInicio': _dateOrNull(atoDesignacaoInicio),
    'atoDesignacaoFim': _dateOrNull(atoDesignacaoFim),
    'tipoComissao': tipoComissao,
    'lotes': lotes.map((e) => e.toJson()).toList(),
    'publicacoes': publicacoes.map((e) => e.toJson()).toList(),
    'recursos': recursos.toJson(),
    'opcionais': opcionais,
  };

  String encode() => jsonEncode(toJson());

  XsdLicitacaoProfile copyWith({
    XsdObjetoClassificacao? objetoClassificacao,
    bool? subcontratacao,
    bool? lei13121,
    XsdLrfEnquadramento? lrf,
    bool? parecerTecnicoJuridico,
    bool? tributosFederais,
    bool? tributosEstaduais,
    bool? tributosMunicipais,
    bool? resolucao072014,
    List<XsdComissaoMembro>? comissao,
    String? numAtoDesignacao,
    int? anoAtoDesignacao,
    DateTime? atoDesignacaoData,
    int? tipoComissao,
    DateTime? homologacaoData,
    DateTime? situacaoData,
    DateTime? finalizacaoProcessoData,
    int? fundamentoLegalCodigo,
    XsdRecursosProfile? recursos,
    Map<String, dynamic>? opcionais,
  }) => XsdLicitacaoProfile(
    objetoClassificacao: objetoClassificacao ?? this.objetoClassificacao,
    subcontratacao: subcontratacao ?? this.subcontratacao,
    lei13121: lei13121 ?? this.lei13121,
    lrf: lrf ?? this.lrf,
    estimativaTrienal: estimativaTrienal,
    adequacaoPlano: adequacaoPlano,
    metasResultado: metasResultado,
    medidasCompensacao: medidasCompensacao,
    previsaoPpaLdo: previsaoPpaLdo,
    parecerTecnicoJuridico:
        parecerTecnicoJuridico ?? this.parecerTecnicoJuridico,
    tributosFederais: tributosFederais ?? this.tributosFederais,
    tributosEstaduais: tributosEstaduais ?? this.tributosEstaduais,
    tributosMunicipais: tributosMunicipais ?? this.tributosMunicipais,
    resolucao072014: resolucao072014 ?? this.resolucao072014,
    julgamentoData: julgamentoData,
    situacaoData: situacaoData ?? this.situacaoData,
    homologacaoData: homologacaoData ?? this.homologacaoData,
    adjudicacaoData: adjudicacaoData,
    ratificacaoData: ratificacaoData,
    finalizacaoProcessoData:
        finalizacaoProcessoData ?? this.finalizacaoProcessoData,
    fundamentoLegalCodigo: fundamentoLegalCodigo ?? this.fundamentoLegalCodigo,
    comissao: comissao ?? this.comissao,
    numAtoDesignacao: numAtoDesignacao ?? this.numAtoDesignacao,
    anoAtoDesignacao: anoAtoDesignacao ?? this.anoAtoDesignacao,
    atoDesignacaoData: atoDesignacaoData ?? this.atoDesignacaoData,
    atoDesignacaoInicio: atoDesignacaoInicio,
    atoDesignacaoFim: atoDesignacaoFim,
    tipoComissao: tipoComissao ?? this.tipoComissao,
    lotes: lotes,
    publicacoes: publicacoes,
    recursos: recursos ?? this.recursos,
    opcionais: opcionais ?? this.opcionais,
  );

  factory XsdLicitacaoProfile.decode(String value) =>
      XsdLicitacaoProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);

  factory XsdLicitacaoProfile.fromJson(Map<String, dynamic> json) =>
      XsdLicitacaoProfile(
        objetoClassificacao: _enumByName(
          XsdObjetoClassificacao.values,
          json['objetoClassificacao'],
          XsdObjetoClassificacao.comprasServicos,
        ),
        subcontratacao: json['subcontratacao'] == true,
        lei13121: json['lei13121'] == true,
        lrf: _enumByName(
          XsdLrfEnquadramento.values,
          json['lrf'],
          XsdLrfEnquadramento.omitido,
        ),
        estimativaTrienal: json['estimativaTrienal'] as bool?,
        adequacaoPlano: json['adequacaoPlano'] as bool?,
        metasResultado: json['metasResultado'] as bool?,
        medidasCompensacao: json['medidasCompensacao'] as bool?,
        previsaoPpaLdo: json['previsaoPpaLdo'] as bool?,
        parecerTecnicoJuridico: json['parecerTecnicoJuridico'] == true,
        tributosFederais: json['tributosFederais'] == true,
        tributosEstaduais: json['tributosEstaduais'] == true,
        tributosMunicipais: json['tributosMunicipais'] == true,
        resolucao072014: json['resolucao072014'] == true,
        julgamentoData: _nullableDate(json['julgamentoData']),
        situacaoData: _nullableDate(json['situacaoData']),
        homologacaoData: _nullableDate(json['homologacaoData']),
        adjudicacaoData: _nullableDate(json['adjudicacaoData']),
        ratificacaoData: _nullableDate(json['ratificacaoData']),
        finalizacaoProcessoData: _nullableDate(json['finalizacaoProcessoData']),
        fundamentoLegalCodigo: json['fundamentoLegalCodigo'] == null
            ? null
            : _asInt(json['fundamentoLegalCodigo'], 0),
        comissao: _mapList(json['comissao'], XsdComissaoMembro.fromJson),
        numAtoDesignacao: json['numAtoDesignacao']?.toString() ?? '',
        anoAtoDesignacao: _asInt(json['anoAtoDesignacao'], 2026),
        atoDesignacaoData: _nullableDate(json['atoDesignacaoData']),
        atoDesignacaoInicio: _nullableDate(json['atoDesignacaoInicio']),
        atoDesignacaoFim: _nullableDate(json['atoDesignacaoFim']),
        tipoComissao: _asInt(json['tipoComissao'], 1),
        lotes: _mapList(json['lotes'], XsdLoteProfile.fromJson),
        publicacoes: _mapList(json['publicacoes'], XsdPublicacao.fromJson),
        recursos: json['recursos'] is Map
            ? XsdRecursosProfile.fromJson(
                Map<String, dynamic>.from(json['recursos'] as Map),
              )
            : const XsdRecursosProfile(),
        opcionais: json['opcionais'] is Map
            ? Map<String, dynamic>.from(json['opcionais'] as Map)
            : const {},
      );
}

/// Read-only normalized data imported from Edital and Licitação JSON documents.
class XsdLicitacaoSource {
  final int modalidadeId;
  final bool srp;
  final bool carona;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final String numeroCompra;
  final int anoCompra;
  final String numeroProcesso;
  final String objeto;
  final int criterioJulgamentoId;
  final int? amparoLegalId;
  final DateTime? editalData;
  final DateTime? situacaoData;
  final bool quitacaoTributosFederais;
  final bool quitacaoTributosEstaduais;
  final bool quitacaoTributosMunicipais;
  final bool declaracaoRecursos;
  final List<int> fontesRecursos;
  final bool parecerTecnicoJuridico;
  final DateTime? entregaPropostaData;
  final DateTime? aberturaData;
  final List<Map<String, dynamic>> itens;
  final Map<String, dynamic> editalJson;
  final Map<String, dynamic> licitacaoJson;

  const XsdLicitacaoSource({
    required this.modalidadeId,
    required this.srp,
    required this.carona,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.numeroCompra,
    required this.anoCompra,
    required this.numeroProcesso,
    required this.objeto,
    required this.criterioJulgamentoId,
    required this.amparoLegalId,
    required this.editalData,
    required this.situacaoData,
    required this.quitacaoTributosFederais,
    required this.quitacaoTributosEstaduais,
    required this.quitacaoTributosMunicipais,
    required this.declaracaoRecursos,
    required this.fontesRecursos,
    required this.parecerTecnicoJuridico,
    required this.entregaPropostaData,
    required this.aberturaData,
    required this.itens,
    required this.editalJson,
    required this.licitacaoJson,
  });
}

/// Compatibility adapter for the original dialog while profiles are edited.
class XsdManualFields {
  final bool subcontratacao;
  final bool lei13121;
  final int lrfArtigo;
  final List<XsdComissaoMembro> comissao;
  final String numAtoDesignacao;
  final int anoAtoDesignacao;
  final DateTime? atoDesignacaoDt;
  final int tipoComissao;
  final DateTime? publicacaoHomologacaoDt;
  final List<Map<String, dynamic>> atestadosDesempenho;

  const XsdManualFields({
    required this.subcontratacao,
    required this.lei13121,
    required this.lrfArtigo,
    required this.comissao,
    required this.numAtoDesignacao,
    required this.anoAtoDesignacao,
    required this.atoDesignacaoDt,
    required this.tipoComissao,
    required this.publicacaoHomologacaoDt,
    this.atestadosDesempenho = const [],
  });

  XsdLicitacaoProfile toProfile({int? fundamentoLegalCodigo}) =>
      XsdLicitacaoProfile(
        subcontratacao: subcontratacao,
        lei13121: lei13121,
        lrf: switch (lrfArtigo) {
          1 => XsdLrfEnquadramento.artigo16,
          2 => XsdLrfEnquadramento.artigo17,
          _ => XsdLrfEnquadramento.naoSeEnquadra,
        },
        comissao: comissao,
        numAtoDesignacao: numAtoDesignacao,
        anoAtoDesignacao: anoAtoDesignacao,
        atoDesignacaoData: atoDesignacaoDt,
        tipoComissao: tipoComissao,
        homologacaoData: publicacaoHomologacaoDt,
        fundamentoLegalCodigo: fundamentoLegalCodigo,
        opcionais: {'atestadosDesempenho': atestadosDesempenho},
      );
}

int _asInt(Object? value, int fallback) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
double _asDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
DateTime? _nullableDate(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : DateTime.tryParse(text);
}

String _date(DateTime value) => value.toIso8601String().substring(0, 10);
String? _dateOrNull(DateTime? value) => value == null ? null : _date(value);
T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((e) => e.name == name).firstOrNull ?? fallback;
List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    (value as List? ?? const [])
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
