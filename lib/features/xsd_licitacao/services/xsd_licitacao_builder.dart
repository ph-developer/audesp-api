// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/xsd_licitacao_models.dart';
import 'xsd_domain_rules.dart';
import 'xsd_source_normalizer.dart';

class XsdLicitacaoBuilder {
  static String buildXml({
    required Map<String, dynamic> licitacaoJson,
    required Map<String, dynamic> editalJson,
    required XsdManualFields manualFields,
    required List<Map<String, dynamic>> licitacaoItens,
  }) {
    final source = const XsdSourceNormalizer().normalize(
      edital: editalJson,
      licitacao: {...licitacaoJson, 'itens': licitacaoItens},
    );
    return build(source: source, profile: manualFields.toProfile());
  }

  static String build({
    required XsdLicitacaoSource source,
    required XsdLicitacaoProfile profile,
    DateTime? createdAt,
  }) {
    final variant = XsdDomainRules.selectVariant(source);
    final effectiveProfile = const XsdSourceNormalizer().mergeProfile(
      source: source,
      persisted: profile,
    );
    XsdDomainRules.validate(source, effectiveProfile, variant);
    _validateLatinFields(source, effectiveProfile);
    final now = createdAt ?? DateTime.now();
    final ns = variant == XsdLicitacaoVariant.nao1
        ? 'http://www.tce.sp.gov.br/audesp/xml/licitacao1'
        : 'http://www.tce.sp.gov.br/audesp/xml/licitacao3';
    final builder = XmlBuilder()
      ..processing('xml', 'version="1.0" encoding="ISO-8859-1"');
    builder.element(
      'Licitacao',
      namespaces: {
        ns: null,
        'http://www.tce.sp.gov.br/audesp/xml/tagcomum': 'tag',
        'http://www.tce.sp.gov.br/audesp/xml/generico': 'gen',
      },
      nest: () {
        builder.element(
          'Descritor',
          nest: () {
            builder.element('gen:AnoExercicio', nest: 2026);
            builder.element(
              'gen:TipoDocumento',
              nest: variant == XsdLicitacaoVariant.nao1
                  ? 'LICITACAO-REGISTRO-PRECOS-NAO-TODAS-MODALIDADES-MENOS-INTERNACIONAL'
                  : 'LICITACAO-REGISTRO-PRECOS-NAO-CONTRATACAO-DIRETA',
            );
            builder.element('gen:Entidade', nest: source.entidade);
            builder.element('gen:Municipio', nest: source.municipio);
            builder.element('gen:DataCriacaoXML', nest: _date(now));
          },
        );
        if (variant == XsdLicitacaoVariant.nao1) {
          _nao1(builder, source, effectiveProfile);
        } else {
          _nao3(builder, source, effectiveProfile);
        }
      },
    );
    final xml = builder.buildDocument().toXmlString(pretty: true, indent: '  ');
    ensureLatin1(xml);
    return xml;
  }

  static void _nao1(XmlBuilder b, XsdLicitacaoSource s, XsdLicitacaoProfile p) {
    b.element(
      'RegistroPrecosNao1',
      nest: () {
        final participantes = _groupParticipants(s.itens);
        b.element(
          'LicitacaoPossuiParticipantes',
          nest: _sn(participantes.isNotEmpty),
        );
        b.element('CodigoLicitacao', nest: _codigoLicitacao(s));
        b.element('NumeroProcessoAdm', nest: s.numeroProcesso);
        b.element('AnoProcessoAdm', nest: s.anoCompra);
        b.element('NumeroLicitacao', nest: s.numeroCompra);
        b.element('AnoLicitacao', nest: s.anoCompra);
        if (p.lei13121) b.element('Lei13121', nest: 'S');
        b.element('DescricaoObjeto', nest: s.objeto);
        final justificativa = p.opcionais['justificativaContratacao']
            ?.toString();
        if (justificativa?.isNotEmpty == true)
          b.element('JustificativaContratacao', nest: justificativa);
        b.element(
          'TotalLicitacaoValor',
          nest: XsdDomainRules.calculateTotal(s.itens).toStringAsFixed(2),
        );
        b.element(
          'TipoLicitacao',
          nest: XsdDomainRules.mapTipoLicitacao(s.criterioJulgamentoId),
        );
        b.element('Subcontratacao', nest: _sn(p.subcontratacao));
        final editalItens = (s.editalJson['itensCompra'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e));
        b.element(
          'BeneficioLei1232006',
          nest: XsdDomainRules.mapBeneficio(editalItens),
        );
        _recursos(b, p.recursos);
        b.element('QuantidadeLotes', nest: s.itens.length);
        _objeto(b, s, p, includeDados: false);
        _modalidade(b, s, p, participantes);
        _lrf(b, p, prefix: 'LRF');
        b.element(
          'ParecerTecnicoJuridico',
          nest: _sn(p.parecerTecnicoJuridico),
        );
        if (p.opcionais['audienciaPublicaData'] != null) {
          b.element(
            'AudienciaPublicaDt',
            nest: p.opcionais['audienciaPublicaData'],
          );
        }
        if (s.entregaPropostaData != null)
          b.element(
            'Datas-EntregaPropostaDt',
            nest: _date(s.entregaPropostaData!),
          );
        if (s.aberturaData != null)
          b.element('Datas-AberturaLicitacaoDt', nest: _date(s.aberturaData!));
        if (p.julgamentoData != null)
          b.element('Datas-JulgamentoDt', nest: _date(p.julgamentoData!));
        _comissao(b, p);
        _atestados(b, p);
        _indicesEconomicos(b, s, p);
        b.element('TributosFederais', nest: _sn(p.tributosFederais));
        b.element('TributosEstaduais', nest: _sn(p.tributosEstaduais));
        b.element('TributosMunicipais', nest: _sn(p.tributosMunicipais));
        _julgamento(b, p);
        if (p.homologacaoData != null)
          b.element(
            'Homologacao-PublicacaoDt',
            nest: _date(p.homologacaoData!),
          );
        if (p.adjudicacaoData != null)
          b.element('Adjudicacao-Dt', nest: _date(p.adjudicacaoData!));
        b.element('SituacaoLicitacao', nest: _situacao(s.itens));
        b.element('DtSituacaoLicitacao', nest: _date(p.situacaoData!));
        final descricao = p.opcionais['descricaoSituacao']?.toString();
        if (descricao?.isNotEmpty == true)
          b.element('DescricaoSituacaoLicitacao', nest: descricao);
      },
    );
  }

  static void _nao3(XmlBuilder b, XsdLicitacaoSource s, XsdLicitacaoProfile p) {
    b.element(
      'RegistroPrecosNao3',
      nest: () {
        _objeto(b, s, p, includeDados: true);
        if (p.ratificacaoData != null) {
          b.element(
            'PublicacaoAtoRatificacaoDt',
            nest: _date(p.ratificacaoData!),
          );
        } else {
          b.element(
            'PublicacaoAtoRatificacaoNao',
            nest: () {
              b.element('PublicacaoAtoRatificacao', nest: 'N');
              b.element(
                'DataFinalizacaoProcesso',
                nest: _date(p.finalizacaoProcessoData!),
              );
            },
          );
        }
        _recursos(b, p.recursos);
        _lrf(b, p);
        b.element(
          'ExisteParecerTecnicoJuridico',
          nest: _sn(p.parecerTecnicoJuridico),
        );
        final audiencia = p.opcionais['audienciaPublicaData']?.toString();
        if (audiencia?.isNotEmpty == true) {
          b.element('AudienciaPublicaProcLicDt', nest: audiencia);
        } else {
          b.element('AudienciaPublicaProcLicNao', nest: 'N');
        }
        final fundamento = XsdDomainRules.mapFundamento(
          s.modalidadeId,
          s.amparoLegalId,
          p.fundamentoLegalCodigo,
        );
        b.element(
          s.modalidadeId == 8
              ? 'ContratacaoDiretaDispensaLicitacao'
              : 'ContratacaoDiretaInexigibilidadeLicitacao',
          nest: () {
            b.element(
              'ModalidadeLicitacao',
              nest: s.modalidadeId == 8 ? 10 : 11,
            );
            b.element(
              fundamento.element,
              nest: () {
                b.element('FundamentoLegal', nest: fundamento.code);
              },
            );
          },
        );
        if (p.opcionais.containsKey('justificativaContratacaoDireta')) {
          b.element(
            'ExisteJustificativaContratacaoDireta',
            nest: _sn(p.opcionais['justificativaContratacaoDireta'] == true),
          );
        }
        b.element(
          'TrataContratacaoFundArt3Resolucao07-2014',
          nest: _sn(p.resolucao072014),
        );
      },
    );
  }

  static void _objeto(
    XmlBuilder b,
    XsdLicitacaoSource s,
    XsdLicitacaoProfile p, {
    required bool includeDados,
  }) {
    final (tag, objectTag, objectCode) = switch (p.objetoClassificacao) {
      XsdObjetoClassificacao.tecnologiaInformacao => (
        'ComprasServicosTI',
        'ObjetoLicitacaoTI',
        _int(p.opcionais['objetoCodigo'], 18),
      ),
      XsdObjetoClassificacao.obrasEngenharia => (
        'ObrasServicosEngenharia',
        'ObjetoLicitacaoEN',
        _int(p.opcionais['objetoCodigo'], 9),
      ),
      _ => (
        'ComprasServicos',
        'ObjetoLicitacao',
        _int(p.opcionais['objetoCodigo'], 17),
      ),
    };
    b.element(
      tag,
      nest: () {
        b.element(objectTag, nest: objectCode);
        if (includeDados) {
          b.element(
            'DadosLicitacao',
            nest: () {
              b.element('CodigoLicitacao', nest: _codigoLicitacao(s));
              b.element('NumeroProcessoAdm', nest: s.numeroProcesso);
              b.element('AnoProcessoAdm', nest: s.anoCompra);
              b.element('QuantidadeLotes', nest: s.itens.length);
              b.element('DescricaoObj', nest: s.objeto);
              b.element(
                'VlTotalLicitacao',
                nest: XsdDomainRules.calculateTotal(s.itens).toStringAsFixed(2),
              );
              b.element('Subcontratacao', nest: _sn(p.subcontratacao));
            },
          );
        }
        for (var i = 0; i < s.itens.length; i++) {
          _lote(
            b,
            s.itens[i],
            i + 1,
            p,
            p.objetoClassificacao == XsdObjetoClassificacao.obrasEngenharia,
          );
        }
        if (!includeDados) _edital(b, s, p);
        if (p.objetoClassificacao != XsdObjetoClassificacao.obrasEngenharia) {
          final item = p.opcionais['amostraItem']?.toString();
          item?.isNotEmpty == true
              ? b.element(
                  'Amostra',
                  nest: () => b.element('AmostrasItem', nest: item),
                )
              : b.element('AmostraNao', nest: 'N');
        }
      },
    );
  }

  static void _lote(
    XmlBuilder b,
    Map<String, dynamic> item,
    int fallback,
    XsdLicitacaoProfile p,
    bool obra,
  ) {
    final numero = _int(item['numeroItem'], fallback);
    final configured = p.lotes.where((e) => e.numero == numero).firstOrNull;
    b.element(
      'Lote',
      nest: () {
        b.element('NumeroLote', nest: numero);
        b.element(
          'DescricaoLote',
          nest: (item['descricao'] ?? item['descricaoItem']).toString(),
        );
        if (!obra) {
          b.element(
            'Quantidade',
            nest: _double(item['quantidade'], 1).toStringAsFixed(5),
          );
          b.element('UnidadeMedida', nest: _unit(item));
        }
        b.element('TipoExecucao', nest: configured?.tipoExecucao ?? 1);
        b.element(
          'ClassificacaoEconomica',
          nest: configured?.classificacaoEconomica ?? 1,
        );
        if (obra) {
          b.element(
            'TipoObraServicoEng',
            nest: _int(p.opcionais['tipoObraServicoEng'], 1),
          );
          b.element(
            'LocalizacaoObra',
            nest: () {
              b.element(
                'LocalObraServico',
                nest: p.opcionais['localObra'] ?? 'Não informado',
              );
              b.element('Latitude', nest: p.opcionais['latitude'] ?? '0');
              b.element('Longitude', nest: p.opcionais['longitude'] ?? '0');
            },
          );
        }
        final budgets = configured?.orcamentos ?? const <XsdOrcamento>[];
        if (budgets.isEmpty) {
          b.element('OrcamentoLoteNao', nest: 'N');
        } else {
          for (final budget in budgets) {
            b.element('OrcamentoLoteSim', nest: () => _orcamento(b, budget));
          }
        }
        if (!obra) b.element('LoteCompostoItensNao', nest: 'N');
      },
    );
  }

  static void _orcamento(XmlBuilder b, XsdOrcamento value) {
    final digits = value.documento.replaceAll(RegExp(r'\D'), '');
    b.element(
      digits.length == 11
          ? 'CPF'
          : digits.length == 14
          ? 'CNPJ'
          : 'OutroDoc',
      nest: digits.isEmpty ? value.documento : digits,
    );
    b.element('ValorUnitario', nest: value.valorUnitario.toStringAsFixed(5));
    b.element('Quantidade', nest: value.quantidade.toStringAsFixed(5));
    b.element('UnidadeMedida', nest: value.unidade);
    b.element('DtOrcamento', nest: _date(value.data));
  }

  static void _edital(
    XmlBuilder b,
    XsdLicitacaoSource s,
    XsdLicitacaoProfile p,
  ) {
    b.element(
      'Edital',
      nest: () {
        b.element('EditalNumero', nest: s.numeroCompra);
        b.element('EditalDt', nest: _date(s.editalData!));
        for (final publication in p.publicacoes) {
          b.element(
            'EditalPublicacao',
            nest: () {
              b.element('VeiculoPublicacao', nest: publication.veiculo);
              b.element('PublicacaoData', nest: _date(publication.data));
              if (publication.descricao?.isNotEmpty == true)
                b.element('PublicacaoDescr', nest: publication.descricao);
              b.element('PublicacaoOficial', nest: _sn(publication.oficial));
            },
          );
        }
      },
    );
  }

  static void _recursos(XmlBuilder b, XsdRecursosProfile r) {
    if (!r.declarados) {
      b.element('ExistenciaRecursosNao', nest: 'N');
      return;
    }
    b.element(
      'ExistenciaRecursosSim',
      nest: () {
        b.element('ExistenciaRecursosValor', nest: r.valor!.toStringAsFixed(2));
        b.element('ExistenciaRecursosDt', nest: _date(r.data!));
        if (r.fontes.contains(1)) b.element('Tesouro', nest: 'S');
        if (r.fontes.contains(3))
          b.element('RecursosPropriosFundosEspeciais', nest: 'S');
        if (r.fontes.contains(4))
          b.element('RecursosPropriosAdministracaoIndireta', nest: 'S');
        if (r.fontes.contains(6))
          b.element('OutrasFontesDescricao', nest: r.outrasFontesDescricao);
        if (r.fontes.contains(8))
          b.element('EmendasParlamentaresIndividuais', nest: 'S');
      },
    );
  }

  static void _lrf(XmlBuilder b, XsdLicitacaoProfile p, {String prefix = ''}) {
    switch (p.lrf) {
      case XsdLrfEnquadramento.artigo16:
        b.element(
          '${prefix}Artigo16',
          nest: () {
            b.element('Artigo16', nest: 'S');
            if (p.estimativaTrienal != null)
              b.element('EstimativaTrienal', nest: _sn(p.estimativaTrienal!));
            if (p.adequacaoPlano != null)
              b.element('AdequacaoPlano', nest: _sn(p.adequacaoPlano!));
          },
        );
      case XsdLrfEnquadramento.artigo17:
        b.element(
          '${prefix}Artigo17',
          nest: () {
            b.element('Artigo17', nest: 'S');
            if (p.metasResultado != null)
              b.element('MetasResultado', nest: _sn(p.metasResultado!));
            if (p.medidasCompensacao != null)
              b.element('MedidasCompensacao', nest: _sn(p.medidasCompensacao!));
            if (p.previsaoPpaLdo != null)
              b.element('PrevisaoPpaLdo', nest: _sn(p.previsaoPpaLdo!));
          },
        );
      case XsdLrfEnquadramento.naoSeEnquadra:
        b.element(
          prefix.isEmpty ? 'NaoSeEnquadra' : '${prefix}NaoSeEnquadra',
          nest: 'S',
        );
      case XsdLrfEnquadramento.omitido:
        break;
    }
  }

  static void _modalidade(
    XmlBuilder b,
    XsdLicitacaoSource s,
    XsdLicitacaoProfile p,
    List<Map<String, dynamic>> participants,
  ) {
    final mapping = XsdDomainRules.modalidadeNao1[s.modalidadeId]!;
    b.element(
      mapping.$1,
      nest: () {
        b.element('ModalidadeLicitacao', nest: mapping.$2);
        if ({
          'Concorrencia',
          'PregaoEletronico',
          'PregaoPresencial',
          'Outras',
        }.contains(mapping.$1)) {
          if (mapping.$1 == 'Outras')
            b.element(
              'ModalidadeLicitacaoOutros',
              nest: 'Modalidade PNCP ${s.modalidadeId}',
            );
          b.element(
            'NaturezaLicitacao',
            nest: _int(p.opcionais['naturezaLicitacao'], 1),
          );
        }
        if (mapping.$1 == 'Concorrencia')
          b.element('PreQualificacaoNao', nest: 'N');
        _participants(b, participants, convite: mapping.$1 == 'Convite');
      },
    );
  }

  static void _participants(
    XmlBuilder b,
    List<Map<String, dynamic>> values, {
    required bool convite,
  }) {
    if (values.isEmpty) return;
    b.element(
      'Licitante',
      nest: () {
        for (final value in values.where(
          (e) => e['documento'].toString().length <= 11,
        )) {
          _participant(
            b,
            value,
            convite ? 'LicitanteConviteCPF' : 'LicitanteCPF',
          );
        }
        for (final value in values.where(
          (e) => e['documento'].toString().length > 11,
        )) {
          _participant(
            b,
            value,
            convite ? 'LicitanteConviteCNPJ' : 'LicitanteCNPJ',
          );
        }
      },
    );
  }

  static void _participant(XmlBuilder b, Map<String, dynamic> p, String tag) {
    final cpf = tag.endsWith('CPF');
    b.element(
      tag,
      nest: () {
        b.element(cpf ? 'CPF' : 'CNPJ', nest: p['documento']);
        b.element(cpf ? 'Nome' : 'RazaoSocial', nest: p['nome']);
        b.element(
          'LicitanteDeclaracaoMicroEmpresa-PequenoPorte',
          nest: p['meEpp'],
        );
        for (final lot in p['lotes'] as List<Map<String, dynamic>>) {
          b.element(
            'LicitanteLoteItens',
            nest: () {
              b.element('LicitanteNumLote', nest: lot['numero']);
              b.element('ResultadoHabilitacao', nest: lot['resultado']);
              final percentual = lot['percentual'] == true;
              b.element(
                percentual ? 'ValorPropostaPercentual' : 'ValorProposta',
                nest: (lot['valor'] as double).toStringAsFixed(2),
              );
            },
          );
        }
        if (tag.contains('Convite'))
          b.element('IdentificacaoLicitante', nest: 1);
      },
    );
  }

  static List<Map<String, dynamic>> _groupParticipants(
    List<Map<String, dynamic>> items,
  ) {
    final grouped = <String, Map<String, dynamic>>{};
    for (var i = 0; i < items.length; i++) {
      for (final raw
          in (items[i]['licitantes'] as List? ?? const []).whereType<Map>()) {
        final lic = Map<String, dynamic>.from(raw);
        final document =
            (lic['niPessoa'] ?? lic['cnpjCpf'] ?? lic['cpfCnpj'] ?? '')
                .toString()
                .replaceAll(RegExp(r'\D'), '');
        if (document.isEmpty) continue;
        final record = grouped.putIfAbsent(
          document,
          () => {
            'documento': document,
            'nome': (lic['nomeRazaoSocial'] ?? lic['nome'] ?? 'Não informado')
                .toString(),
            'meEpp': {1, 2}.contains(_int(lic['declaracaoMEouEPP']))
                ? 'S'
                : 'N',
            'lotes': <Map<String, dynamic>>[],
          },
        );
        (record['lotes'] as List<Map<String, dynamic>>).add({
          'numero': _int(items[i]['numeroItem'], i + 1),
          'resultado': XsdDomainRules.mapResultado(
            _int(lic['resultadoHabilitacao'], 2),
          ),
          'valor': _double(lic['valor']),
          'percentual':
              lic['tipoValor']?.toString() == 'P' ||
              _int(lic['tipoProposta']) == 3,
        });
      }
    }
    return grouped.values.toList();
  }

  static void _comissao(XmlBuilder b, XsdLicitacaoProfile p) {
    if (p.comissao.isEmpty) return;
    b.element(
      'ComissaoLicitacao',
      nest: () {
        for (final member in p.comissao) {
          b.element(
            'CPFIntegrante',
            nest: member.cpf.replaceAll(RegExp(r'\D'), ''),
          );
          b.element('NomeIntegrante', nest: member.nome);
          b.element('AtribuicaoIntegrante', nest: member.atribuicao);
          b.element('CargoOcupadoIntegrante', nest: member.cargo);
          b.element('NaturezaCargoOcupado', nest: member.naturezaCargo);
        }
        b.element('TipoComissaoLicitacao', nest: p.tipoComissao);
        b.element('NumAtoDesignacao', nest: p.numAtoDesignacao);
        b.element('AnoAtoDesignacao', nest: p.anoAtoDesignacao);
        if (p.atoDesignacaoData != null)
          b.element(
            'AtoDesignacaoComissaoDt',
            nest: _date(p.atoDesignacaoData!),
          );
        if (p.atoDesignacaoInicio != null) {
          b.element(
            'AtoDesignacaoComissaoInicio',
            nest: _date(p.atoDesignacaoInicio!),
          );
          if (p.atoDesignacaoFim != null)
            b.element(
              'AtoDesignacaoComissaoFim',
              nest: _date(p.atoDesignacaoFim!),
            );
        }
      },
    );
  }

  static void _atestados(XmlBuilder b, XsdLicitacaoProfile p) {
    for (final raw
        in (p.opcionais['atestadosDesempenho'] as List? ?? const [])
            .whereType<Map>()) {
      b.element(
        'AtestadoDesempenho',
        nest: () {
          b.element('NumeroLote', nest: raw['lote']);
          if (raw['descricao']?.toString().isNotEmpty == true)
            b.element('AtestadoDescricao', nest: raw['descricao']);
          b.element('AtestadoPercentual', nest: raw['percentual'] ?? 100);
          b.element('AtestadoQuantidade', nest: raw['quantidade'] ?? 1);
        },
      );
    }
  }

  static void _indicesEconomicos(
    XmlBuilder b,
    XsdLicitacaoSource source,
    XsdLicitacaoProfile profile,
  ) {
    final raw = source.licitacaoJson['indicesEconomicos'];
    final values = raw is String
        ? (jsonDecode(raw) as List? ?? const [])
        : (raw as List? ?? const []);
    for (final value in values.whereType<Map>()) {
      final id = _int(value['tipoIndice']);
      b.element(
        'IndiceEconomico',
        nest: () {
          final mapped = XsdDomainRules.mapIndiceEconomico(id);
          if (mapped == 8) {
            final description =
                (value['nomeIndice'] ??
                        profile.opcionais['indiceEconomicoOutro'])
                    ?.toString();
            if (description == null || description.trim().isEmpty) {
              throw const XsdDomainException([
                'Índice econômico "outro" exige uma descrição complementar.',
              ]);
            }
            b.element(
              'IndiceEconomicoOutro-Tipo',
              nest: () {
                b.element('Outro', nest: description);
              },
            );
          } else {
            b.element('IndiceEconomico-Tipo', nest: mapped);
          }
          b.element(
            'IndiceEconomico-Valor',
            nest: _double(value['valorIndice']).toStringAsFixed(2),
          );
        },
      );
    }
  }

  static void _julgamento(XmlBuilder b, XsdLicitacaoProfile p) {
    if (p.lei13121) {
      b.element('JulgamentoComInversao');
    } else {
      b.element(
        'JulgamentoSemInversao',
        nest: () {
          b.element('NaoExisteAtaAberturaDocumentosHabilitacao', nest: 'N');
          b.element('NaoExisteAtaJulgamentoDocumentosHabilitacao', nest: 'N');
        },
      );
    }
  }

  static int _situacao(List<Map<String, dynamic>> items) {
    final states = items.map((e) => _int(e['situacaoCompraItemId'])).toSet();
    if (states.contains(2)) return 11;
    if (states.contains(5)) return 1;
    if (states.contains(4)) return 2;
    if (states.contains(3)) return 4;
    return 5;
  }

  static String buildMarkdownSummary(String xmlString, String modalidadeNome) =>
      XsdMarkdownBuilder.build(xmlString, title: modalidadeNome);

  static String _codigoLicitacao(XsdLicitacaoSource source) {
    final digits = source.codigoEdital.replaceAll(RegExp(r'\D'), '');
    final number = digits.substring(15, 21);
    final year = digits.substring(21, 25);
    return '${source.anoCompra}9$number${year.substring(2)}';
  }

  static String _unit(Map<String, dynamic> item) {
    final value = (item['unidade'] ?? item['unidadeMedida'] ?? 'UN').toString();
    return value.length <= 20 ? value : value.substring(0, 20);
  }

  static void ensureLatin1(String value, {String field = 'XML'}) {
    for (var i = 0; i < value.runes.length; i++) {
      final rune = value.runes.elementAt(i);
      if (rune > 255) {
        throw FormatException(
          '$field contém caractere não representável em ISO-8859-1: ${String.fromCharCode(rune)}.',
        );
      }
    }
  }

  static void _validateLatinFields(
    XsdLicitacaoSource source,
    XsdLicitacaoProfile profile,
  ) {
    final fields = <String, Object?>{
      'Edital.objetoCompra': source.objeto,
      'Edital.numeroProcesso': source.numeroProcesso,
      'Edital.numeroCompra': source.numeroCompra,
      'Licitação.itens': source.itens,
      'Perfil XSD': profile.toJson(),
    };
    void walk(String path, Object? value) {
      if (value is String) {
        ensureLatin1(value, field: path);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk('$path[$i]', value[i]);
        }
      } else if (value is Map) {
        for (final entry in value.entries) {
          walk('$path.${entry.key}', entry.value);
        }
      }
    }

    for (final entry in fields.entries) {
      walk(entry.key, entry.value);
    }
  }
}

class XsdMarkdownBuilder {
  static const translations = <String, Map<String, String>>{
    'ResultadoHabilitacao': {
      '1': 'Desclassificado',
      '2': 'Vencedor',
      '3': 'Inabilitado',
      '5': 'Desistiu/não compareceu',
      '6': 'Classificado',
      '7': 'Habilitado',
      '8': 'Proposta não analisada',
    },
    'SituacaoLicitacao': {
      '1': 'Fracassada',
      '2': 'Deserta',
      '3': 'Adjudicada',
      '4': 'Revogada',
      '5': 'Outra',
      '6': 'Anulada',
      '7': 'Homologação parcial',
      '11': 'Homologada',
    },
    'Subcontratacao': {'S': 'Sim', 'N': 'Não'},
  };

  static String build(String xml, {String title = 'Licitação'}) {
    final doc = XmlDocument.parse(xml);
    final out = StringBuffer('# $title\n\n');
    void walk(XmlElement element, int depth) {
      final children = element.childElements.toList();
      if (children.isEmpty) {
        final value = element.innerText;
        final translated = translations[element.name.local]?[value];
        out.writeln(
          '${'  ' * depth}- **${element.name.local}:** ${translated == null ? value : '$translated (`$value`)'}',
        );
        return;
      }
      out.writeln('${'#' * (depth.clamp(1, 5))} ${element.name.local}');
      out.writeln();
      for (final child in children) walk(child, depth + 1);
      out.writeln();
    }

    for (final child in doc.rootElement.childElements) walk(child, 2);
    return out.toString();
  }
}

String _date(DateTime value) => value.toIso8601String().substring(0, 10);
String _sn(bool value) => value ? 'S' : 'N';
int _int(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value, [double fallback = 0]) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? fallback;
