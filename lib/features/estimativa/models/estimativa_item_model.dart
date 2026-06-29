import 'package:audesp_api/core/utils/rounding_utils.dart';

import 'estimativa_orcamento_model.dart';

class EstimativaItem {
  final int numero;
  final String descricao;
  final String unidade;
  final double quantidade;

  // Periodicidade
  final String tipoFornecimento; // 'unica' ou 'mensal'
  final int quantidadeMeses; // Relevante se tipoFornecimento == 'mensal'

  // Configurações e Dados
  // Configurações e Dados
  final String materialOuServico; // 'M' ou 'S'
  final int? itemCategoriaId;
  final bool
  exclusivoMeEpp; // Aplicável apenas quando a estimativa é "Por Item"
  final List<EstimativaOrcamento> orcamentos;

  EstimativaItem({
    required this.numero,
    required this.descricao,
    required this.unidade,
    required this.quantidade,
    this.tipoFornecimento = 'unica',
    this.quantidadeMeses = 1,

    this.materialOuServico = 'M',
    this.itemCategoriaId,
    this.exclusivoMeEpp = false,
    this.orcamentos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'descricao': descricao,
      'unidade': unidade,
      'quantidade': quantidade,
      'tipoFornecimento': tipoFornecimento,
      'quantidadeMeses': quantidadeMeses,
      'materialOuServico': materialOuServico,
      'itemCategoriaId': itemCategoriaId,
      'exclusivoMeEpp': exclusivoMeEpp,
      'orcamentos': orcamentos.map((x) => x.toMap()).toList(),
    };
  }

  factory EstimativaItem.fromMap(Map<String, dynamic> map) {
    return EstimativaItem(
      numero: map['numero']?.toInt() ?? 0,
      descricao: map['descricao'] ?? '',
      unidade: map['unidade'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0.0,
      tipoFornecimento: map['tipoFornecimento'] ?? 'unica',
      quantidadeMeses: map['quantidadeMeses']?.toInt() ?? 1,
      materialOuServico: map['materialOuServico'] ?? 'M',
      itemCategoriaId: map['itemCategoriaId']?.toInt(),
      exclusivoMeEpp: map['exclusivoMeEpp'] ?? false,
      orcamentos: List<EstimativaOrcamento>.from(
        (map['orcamentos'] as List<dynamic>? ?? []).map(
          (x) => EstimativaOrcamento.fromMap(x),
        ),
      ),
    );
  }

  EstimativaItem copyWith({
    int? numero,
    String? descricao,
    String? unidade,
    double? quantidade,
    String? tipoFornecimento,
    int? quantidadeMeses,
    String? materialOuServico,
    int? itemCategoriaId,
    bool? exclusivoMeEpp,
    List<EstimativaOrcamento>? orcamentos,
  }) {
    return EstimativaItem(
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      unidade: unidade ?? this.unidade,
      quantidade: quantidade ?? this.quantidade,
      tipoFornecimento: tipoFornecimento ?? this.tipoFornecimento,
      quantidadeMeses: quantidadeMeses ?? this.quantidadeMeses,
      materialOuServico: materialOuServico ?? this.materialOuServico,
      itemCategoriaId: itemCategoriaId ?? this.itemCategoriaId,
      exclusivoMeEpp: exclusivoMeEpp ?? this.exclusivoMeEpp,
      orcamentos: orcamentos ?? this.orcamentos,
    );
  }

  double get valorReferenciaUnitarioBase {
    if (orcamentos.isEmpty) return 0.0;

    // Fallback to min if no specific config logic is applied yet.
    // In actual usage, pass the global calc to a method, or do it outside.
    // We will provide a helper method to calculate based on the chosen strategy.
    return 0.0;
  }

  double getValorReferenciaUnitario(String calculoGlobal, {int casasDecimais = 2}) {
    if (orcamentos.isEmpty) return 0.0;

    final strategy = calculoGlobal;
    final valores = orcamentos.map((e) => e.valorUnitario).toList();

    double raw;
    if (strategy == 'min') {
      raw = valores.reduce((a, b) => a < b ? a : b);
    } else if (strategy == 'avg') {
      final sum = valores.reduce((a, b) => a + b);
      raw = sum / valores.length;
    } else if (strategy == 'median') {
      valores.sort();
      final middle = valores.length ~/ 2;
      if (valores.length % 2 == 1) {
        raw = valores[middle];
      } else {
        raw = (valores[middle - 1] + valores[middle]) / 2.0;
      }
    } else if (strategy == 'desc') {
      raw = valores.reduce((a, b) => a > b ? a : b);
    } else {
      raw = valores.reduce((a, b) => a < b ? a : b);
    }

    return arredondarParaCima(raw, casasDecimais);
  }

  double getValorMensal(String calculoGlobal, {int casasDecimais = 2}) {
    if (tipoFornecimento != 'mensal') return 0.0;
    final vUnit = getValorReferenciaUnitario(calculoGlobal, casasDecimais: casasDecimais);
    return arredondarParaCima(quantidade * vUnit, casasDecimais);
  }

  double getValorTotal(String calculoGlobal, {int casasDecimais = 2}) {
    final vUnit = getValorReferenciaUnitario(calculoGlobal, casasDecimais: casasDecimais);
    if (tipoFornecimento == 'mensal') {
      final vMensal = quantidade * vUnit;
      return arredondarParaCima(vMensal * quantidadeMeses, casasDecimais);
    }
    return arredondarParaCima(quantidade * vUnit, casasDecimais);
  }
}
