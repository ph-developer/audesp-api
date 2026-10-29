import 'estimativa_item_model.dart';

class EstimativaLote {
  final int numero;
  final String descricao;
  final double quantidade;
  final String unidade;
  final String materialOuServico;
  final bool exclusivoMeEpp;
  final List<EstimativaItem> itens;

  EstimativaLote({
    required this.numero,
    required this.descricao,
    this.quantidade = 1.0,
    this.unidade = 'UN',
    this.materialOuServico = 'M',
    this.exclusivoMeEpp = false,
    this.itens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'materialOuServico': materialOuServico,
      'exclusivoMeEpp': exclusivoMeEpp,
      'itens': itens.map((x) => x.toMap()).toList(),
    };
  }

  factory EstimativaLote.fromMap(Map<String, dynamic> map) {
    return EstimativaLote(
      numero: map['numero']?.toInt() ?? 0,
      descricao: map['descricao'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 1.0,
      unidade: map['unidade'] ?? 'UN',
      materialOuServico: map['materialOuServico'] ?? 'M',
      exclusivoMeEpp: map['exclusivoMeEpp'] ?? false,
      itens: List<EstimativaItem>.from(
        (map['itens'] as List<dynamic>? ?? []).map(
          (x) => EstimativaItem.fromMap(x),
        ),
      ),
    );
  }

  EstimativaLote copyWith({
    int? numero,
    String? descricao,
    double? quantidade,
    String? unidade,
    String? materialOuServico,
    bool? exclusivoMeEpp,
    List<EstimativaItem>? itens,
  }) {
    return EstimativaLote(
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      materialOuServico: materialOuServico ?? this.materialOuServico,
      exclusivoMeEpp: exclusivoMeEpp ?? this.exclusivoMeEpp,
      itens: itens ?? this.itens,
    );
  }

  /// Retorna o ID do fornecedor com menor valor global para o lote,
  /// considerando apenas fornecedores válidos (não desclassificados)
  /// que cotaram todos os itens do lote.
  String? getFornecedorMenorPrecoGlobalId({
    List<String> desclassificadosIds = const [],
  }) {
    if (itens.isEmpty) return null;

    final todosFornecedores = <String>{};
    for (final item in itens) {
      for (final o in item.orcamentos) {
        if (!desclassificadosIds.contains(o.fornecedorId)) {
          todosFornecedores.add(o.fornecedorId);
        }
      }
    }

    String? bestFornecedorId;
    double? minTotal;

    for (final fId in todosFornecedores) {
      bool cotouTodos = true;
      double totalFornecedor = 0.0;

      for (final item in itens) {
        final orc = item.orcamentos
            .where((o) => o.fornecedorId == fId)
            .firstOrNull;
        if (orc == null || orc.valorUnitario <= 0) {
          cotouTodos = false;
          break;
        }
        final isMensal = item.tipoFornecimento == 'mensal';
        final vTotalItem = isMensal
            ? item.quantidade * orc.valorUnitario * item.quantidadeMeses
            : item.quantidade * orc.valorUnitario;
        totalFornecedor += vTotalItem;
      }

      if (cotouTodos) {
        if (minTotal == null || totalFornecedor < minTotal) {
          minTotal = totalFornecedor;
          bestFornecedorId = fId;
        }
      }
    }

    return bestFornecedorId;
  }

  double getValorTotal(
    String calculoGlobal, {
    int casasDecimais = 2,
    List<String> desclassificadosIds = const [],
  }) {
    final fId = calculoGlobal == 'min_global'
        ? getFornecedorMenorPrecoGlobalId(
            desclassificadosIds: desclassificadosIds,
          )
        : null;

    return itens.fold(
      0.0,
      (sum, item) =>
          sum +
          item.getValorTotal(
            calculoGlobal,
            casasDecimais: casasDecimais,
            desclassificadosIds: desclassificadosIds,
            fornecedorVencedorId: fId,
          ),
    );
  }
}
