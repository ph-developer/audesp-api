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
    if (ids.contains(1)) return 1;
    if (ids.contains(2)) return 2;
    if (ids.contains(3)) return 3;
    return 4;
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
      if (id == 50) return const XsdFundamento('FundamentoLei14133Art74', 1);
      if (id >= 6 && id <= 17) {
        return XsdFundamento('FundamentoLei14133Art74', id - 4);
      }
      if (id == 102 || id == 103) {
        return const XsdFundamento('FundamentoLei13303Art30', 1);
      }
      if (id >= 104 && id <= 111) {
        return XsdFundamento('FundamentoLei13303Art30', id - 102);
      }
    } else if (modalidade == 8) {
      if (id >= 18 && id <= 46) {
        return XsdFundamento('FundamentoLei14133Art75', id - 17);
      }
      if (id == 60 || id == 77) {
        return XsdFundamento('FundamentoLei14133Art75', id == 60 ? 30 : 31);
      }
      if (id >= 61 && id <= 76) {
        return XsdFundamento('FundamentoLei14133Art76', id - 60);
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
      if (profile.recursos.fontes.any({2, 5, 7}.contains)) {
        errors.add(
          'Convênios e operações de crédito exigem informações complementares.',
        );
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
