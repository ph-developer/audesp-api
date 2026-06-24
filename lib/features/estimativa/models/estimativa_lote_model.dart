import 'estimativa_item_model.dart';

class EstimativaLote {
  final int numero;
  final String descricao;
  final double quantidade;
  final String unidade;
  final String materialOuServico;
  final int? itemCategoriaId;
  final bool exclusivoMeEpp;
  final List<EstimativaItem> itens;

  EstimativaLote({
    required this.numero,
    required this.descricao,
    this.quantidade = 1.0,
    this.unidade = 'UN',
    this.materialOuServico = 'M',
    this.itemCategoriaId,
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
      'itemCategoriaId': itemCategoriaId,
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
      itemCategoriaId: map['itemCategoriaId']?.toInt(),
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
    int? itemCategoriaId,
    bool? exclusivoMeEpp,
    List<EstimativaItem>? itens,
  }) {
    return EstimativaLote(
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      materialOuServico: materialOuServico ?? this.materialOuServico,
      itemCategoriaId: itemCategoriaId ?? this.itemCategoriaId,
      exclusivoMeEpp: exclusivoMeEpp ?? this.exclusivoMeEpp,
      itens: itens ?? this.itens,
    );
  }

  double getValorTotal(String calculoGlobal) {
    return itens.fold(
      0.0,
      (sum, item) => sum + item.getValorTotal(calculoGlobal),
    );
  }
}
