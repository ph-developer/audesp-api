// ignore_for_file: curly_braces_in_flow_control_structures

import '../models/xsd_licitacao_models.dart';

class XsdDomainException implements Exception {
  final List<String> errors;
  const XsdDomainException(this.errors);

  @override
  String toString() => errors.join('\n');
}

class XsdFundamento {
  final String element;
  final int code;
  const XsdFundamento(this.element, this.code);
}

class XsdDomainRules {
  static XsdLicitacaoVariant selectVariant(XsdLicitacaoSource source) {
    if (source.srp) {
      throw const XsdDomainException([
        'Editais com Sistema de Registro de Preços não são suportados pelos schemas NÃO1/NÃO3.',
      ]);
    }
    if (source.carona) {
      throw const XsdDomainException([
        'Carona/adesão não possui representação segura nos schemas NÃO1/NÃO3.',
      ]);
    }
    if ({16, 17, 18, 19}.contains(source.modalidadeId)) {
      throw const XsdDomainException([
        'Modalidades internacionais não são suportadas pelos schemas 2026.',
      ]);
    }
    if ({8, 9}.contains(source.modalidadeId)) return XsdLicitacaoVariant.nao3;
    if (!modalidadeNao1.containsKey(source.modalidadeId)) {
      throw XsdDomainException([
        'Modalidade PNCP ${source.modalidadeId} sem correspondência inequívoca no NÃO1.',
      ]);
    }
    return XsdLicitacaoVariant.nao1;
  }

  static String defaultFileName(
    XsdLicitacaoSource source,
    XsdLicitacaoVariant variant,
  ) {
    final number = source.numeroCompra.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final String prefix;
    switch (source.modalidadeId) {
      case 9:
        prefix = 'inexigibilidade';
        break;
      case 8:
        prefix = 'dispensa';
        break;
      case 4:
      case 5:
      case 16:
      case 17:
        prefix = 'concorrencia';
        break;
      case 6:
      case 18:
        prefix = 'pregao_eletronico';
        break;
      case 7:
      case 19:
        prefix = 'pregao_presencial';
        break;
      case 998:
        prefix = 'convite';
        break;
      case 999:
        prefix = 'tomada_precos';
        break;
      case 997:
        prefix = 'rdc';
        break;
      case 1:
      case 13:
        prefix = 'leilao';
        break;
      default:
        prefix = 'licitacao_${variant.name}';
    }
    return '${prefix}_${number}_${source.anoCompra}'.toLowerCase();
  }

  /// PNCP modalidade -> elemento do bloco e código fixo no XSD.
  static const modalidadeNao1 = <int, (String, int)>{
    4: ('Concorrencia', 1),
    5: ('Concorrencia', 1),
    6: ('PregaoEletronico', 5),
    7: ('PregaoPresencial', 6),
    998: ('Convite', 4),
    999: ('TomadaPrecos', 3),
    997: ('ContrratacaoRDC', 7),
    1: ('Outras', 13),
    2: ('Outras', 13),
    3: ('Outras', 13),
    12: ('Outras', 13),
    13: ('Outras', 13),
    14: ('Outras', 13),
    15: ('Outras', 13),
  };

  /// PNCP julgamento -> TipoLicitacao_t. Values without an XSD equivalent fail.
  static const tipoLicitacao = <int, int>{
    1: 1, // menor preço
    2: 6, // maior desconto
    4: 3, // técnica e preço
    5: 5, // maior lance
    6: 7, // maior retorno econômico
    8: 2, // melhor técnica
  };

  static int mapTipoLicitacao(int id) {
    final value = tipoLicitacao[id];
    if (value == null) {
      throw XsdDomainException([
        'Critério de julgamento $id sem correspondência no TipoLicitacao do XSD.',
      ]);
    }
    return value;
  }

  static int mapBeneficio(Iterable<Map<String, dynamic>> itens) {
    final ids = itens.map((e) => _int(e['tipoBeneficioId'])).toSet();
    if (ids.contains(1)) return 2; // Licitação exclusiva.
    if (ids.contains(2) || ids.contains(3))
      return 3; // Tratamento diferenciado.
    return 1; // Sem benefício ou não se aplica.
  }

  static const resultadoLicitante = <int, int>{
    1: 2,
    2: 6,
    3: 7,
    4: 1,
    5: 5,
    6: 8,
    7: 3,
  };

  /// Índice econômico do documento JSON -> TipoIndiceEconomico_t do XSD.
  static const indiceEconomico = <int, int>{
    1: 7, // capital social mínimo
    2: 5, // endividamento a curto prazo
    3: 6, // endividamento total
    4: 2, // liquidez corrente
    5: 4, // liquidez geral
    6: 1, // liquidez imediata
    7: 3, // liquidez seca
    8: 8, // outro
  };

  static int mapIndiceEconomico(int id) {
    final result = indiceEconomico[id];
    if (result == null) {
      throw XsdDomainException(['Índice econômico $id desconhecido.']);
    }
    return result;
  }

  static int mapResultado(int id) {
    final result = resultadoLicitante[id];
    if (result == null) {
      throw XsdDomainException(['Resultado de habilitação $id desconhecido.']);
    }
    return result;
  }

  /// Current PNCP amparo ids mapped to the enumerated child code in the XSD.
  static XsdFundamento mapFundamento(
    int modalidade,
    int? amparoId,
    int? override,
  ) {
    // O edital vinculado é a fonte oficial do amparo. O valor persistido
    // continua sendo aceito apenas para perfis antigos cujo edital não o tinha.
    final id = amparoId ?? override;
    if (id == null || id <= 0) {
      throw const XsdDomainException([
        'Informe um amparo legal válido no edital vinculado.',
      ]);
    }
    if (modalidade == 9) {
      if (id == 50) return const XsdFundamento('FundamentoLei14133Art74', 57);
      if (id >= 6 && id <= 17) {
        return XsdFundamento('FundamentoLei14133Art74', id + 52);
      }
      if (id == 102 || id == 103) {
        return const XsdFundamento('FundamentoLei13303Art30', 1);
      }
      if (id >= 104 && id <= 111) {
        return XsdFundamento('FundamentoLei13303Art30', id - 102);
      }
    } else if (modalidade == 8) {
      // Tabela explícita PNCP → XSD FundamentoLei14133_Art75_t (63-78).
      // O PNCP expande subitens (ex.: Art. 75, III a/b, Art. 75, IV a-m)
      // enquanto o XSD agrupa por inciso: I=63, II=64, ..., XVI=78.
      const pncpToArt75 = <int, int>{
        18: 63, // I
        19: 64, // II
        20: 65, 21: 65, // III (a, b)
        22: 66, 23: 66, 24: 66, 25: 66, 26: 66, 27: 66, // IV (a-f)
        28: 66, 29: 66, 30: 66, 31: 66, 32: 66, 33: 66, 34: 66, // IV (g-m)
        35: 67, // V
        36: 68, // VI
        37: 69, // VII
        38: 70, // VIII
        39: 71, // IX
        40: 72, // X
        41: 73, // XI
        42: 74, // XII
        43: 75, // XIII
        44: 76, // XIV
        45: 77, // XV
        46: 78, // XVI
      };
      if (pncpToArt75.containsKey(id)) {
        return XsdFundamento('FundamentoLei14133Art75', pncpToArt75[id]!);
      }
      // XVII e XVIII foram adicionados por leis posteriores e não possuem
      // enumerações dedicadas no XSD 2026_A; mapeiam para XV/XVI como
      // aproximação aceita pelo AUDESP em piloto.
      if (id == 60) {
        return const XsdFundamento('FundamentoLei14133Art75', 77);
      }
      if (id == 77) {
        return const XsdFundamento('FundamentoLei14133Art75', 78);
      }
      if (id == 78) {
        return const XsdFundamento('FundamentoLei14133Art75', 78);
      }
      if (id >= 61 && id <= 76) {
        return XsdFundamento('FundamentoLei14133Art76', id + 18);
      }
      if (id >= 84 && id <= 101) {
        return XsdFundamento('FundamentoLei13303Art29', id - 83);
      }
    }
    throw XsdDomainException([
      'Amparo legal $id do edital incompatível com a modalidade $modalidade.',
    ]);
  }

  static void validate(
    XsdLicitacaoSource source,
    XsdLicitacaoProfile profile,
    XsdLicitacaoVariant variant,
  ) {
    final errors = <String>[];
    if (source.itens.isEmpty)
      errors.add('A licitação deve possuir ao menos um item/lote.');
    if (source.objeto.trim().isEmpty)
      errors.add('O objeto da licitação é obrigatório.');
    if (source.numeroProcesso.trim().isEmpty)
      errors.add('O número do processo é obrigatório.');
    if (source.codigoEdital.replaceAll(RegExp(r'\D'), '').length != 25) {
      errors.add('O código PNCP do edital deve conter exatamente 25 dígitos.');
    }
    for (var i = 0; i < source.itens.length; i++) {
      final item = source.itens[i];
      final quantidade = _double(item['quantidade']);
      if (quantidade <= 0)
        errors.add('Lote ${i + 1}: quantidade deve ser maior que zero.');
      if ((item['descricao'] ?? item['descricaoItem'] ?? '')
          .toString()
          .trim()
          .isEmpty) {
        errors.add('Lote ${i + 1}: descrição obrigatória.');
      }
    }
    if (variant == XsdLicitacaoVariant.nao1) {
      if (source.editalData == null) {
        errors.add(
          'O edital deve possuir data do documento, publicação ou abertura para gerar o NÃO1.',
        );
      }
      try {
        mapTipoLicitacao(source.criterioJulgamentoId);
      } on XsdDomainException catch (e) {
        errors.addAll(e.errors);
      }
      if (calculateTotal(source.itens) <= 0) {
        errors.add('O valor total adjudicado do NÃO1 deve ser maior que zero.');
      }
      if (profile.situacaoData == null) {
        errors.add('A data da situação não foi encontrada na licitação.');
      }
    } else {
      if (profile.finalizacaoProcessoData == null &&
          profile.ratificacaoData == null) {
        errors.add(
          'Informe a publicação da ratificação ou a data de finalização do processo.',
        );
      }
      try {
        mapFundamento(
          source.modalidadeId,
          source.amparoLegalId,
          profile.fundamentoLegalCodigo,
        );
      } on XsdDomainException catch (e) {
        errors.addAll(e.errors);
      }
    }
    if (profile.recursos.declarados) {
      if ((profile.recursos.valor ?? 0) <= 0)
        errors.add('Recursos: informe valor maior que zero.');
      if (profile.recursos.data == null)
        errors.add('Recursos: informe a data da declaração.');
      if (profile.recursos.fontes.isEmpty)
        errors.add('Recursos: informe ao menos uma fonte.');
      if (profile.recursos.fontes.contains(6) &&
          (profile.recursos.outrasFontesDescricao?.trim().isEmpty ?? true)) {
        errors.add('Recursos: descreva as outras fontes.');
      }
      _validateConvenios(
        errors,
        label: 'Convênios estaduais',
        selected: profile.recursos.fontes.contains(2),
        values: profile.recursos.conveniosEstaduais,
      );
      _validateConvenios(
        errors,
        label: 'Convênios federais',
        selected: profile.recursos.fontes.contains(5),
        values: profile.recursos.conveniosFederais,
      );
      if (profile.recursos.fontes.contains(7) &&
          profile.recursos.operacoesCredito.isEmpty) {
        errors.add('Operações de crédito: informe ao menos um contrato.');
      }
      for (var i = 0; i < profile.recursos.operacoesCredito.length; i++) {
        final value = profile.recursos.operacoesCredito[i];
        final prefix = 'Operação de crédito ${i + 1}';
        if (value.contratoNumero.trim().isEmpty ||
            value.contratoNumero.length > 20) {
          errors.add(
            '$prefix: informe o número do contrato (até 20 caracteres).',
          );
        }
        if (value.contratoAno < 1000 || value.contratoAno > 9999)
          errors.add('$prefix: informe um ano com quatro dígitos.');
        if (value.valorRepasse < 0)
          errors.add('$prefix: o valor do repasse não pode ser negativo.');
        if (value.agenteFinanceiro.length > 50)
          errors.add('$prefix: agente financeiro limitado a 50 caracteres.');
      }
    }
    if (profile.comissao.isNotEmpty) {
      if (profile.numAtoDesignacao.trim().isEmpty)
        errors.add('Comissão: número do ato é obrigatório.');
      if (profile.atoDesignacaoData == null &&
          profile.atoDesignacaoInicio == null) {
        errors.add('Comissão: informe a data ou o início da vigência do ato.');
      }
    }
    if (errors.isNotEmpty) throw XsdDomainException(errors);
  }

  static void _validateConvenios(
    List<String> errors, {
    required String label,
    required bool selected,
    required List<XsdConvenio> values,
  }) {
    if (selected && values.isEmpty) {
      errors.add('$label: informe ao menos um convênio.');
    }
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final prefix = '$label ${i + 1}';
      if (!RegExp(r'^[a-zA-Z0-9-]{1,12}$').hasMatch(value.numero)) {
        errors.add('$prefix: número deve ter até 12 letras, números ou hífen.');
      }
      if (value.ano < 1000 || value.ano > 9999)
        errors.add('$prefix: informe um ano com quatro dígitos.');
      if (value.valorRepasse < 0 || value.valorContrapartida < 0) {
        errors.add('$prefix: os valores não podem ser negativos.');
      }
    }
  }

  static double calculateTotal(List<Map<String, dynamic>> itens) {
    var total = 0.0;
    for (final item in itens) {
      final quantidade = _double(item['quantidade']);
      final estimado = _double(
        item['valorUnitarioEstimado'] ?? item['valorTotal'],
      );
      final licitantes = (item['licitantes'] as List? ?? const [])
          .whereType<Map>();
      for (final raw in licitantes) {
        final lic = Map<String, dynamic>.from(raw);
        if (_int(lic['resultadoHabilitacao']) != 1) continue;
        final valor = _double(lic['valor']);
        final tipo = _int(lic['tipoProposta'], 1);
        final percentual = (lic['tipoValor']?.toString() == 'P') || tipo == 3;
        if (percentual) {
          total += estimado * (1 - (valor / 100));
        } else if (tipo == 2) {
          total += valor * quantidade;
        } else {
          total += valor;
        }
      }
    }
    return total;
  }
}

int _int(Object? value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
