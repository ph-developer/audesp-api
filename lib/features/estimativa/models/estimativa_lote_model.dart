import 'estimativa_item_model.dart';

class EstimativaLote {
  final int numero;
  final String descricao;
  final bool exclusivoMeEpp;
  final List<EstimativaItem> itens;

  EstimativaLote({
    required this.numero,
    required this.descricao,
    this.exclusivoMeEpp = false,
    this.itens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'descricao': descricao,
      'exclusivoMeEpp': exclusivoMeEpp,
      'itens': itens.map((x) => x.toMap()).toList(),
    };
  }

  factory EstimativaLote.fromMap(Map<String, dynamic> map) {
    return EstimativaLote(
      numero: map['numero']?.toInt() ?? 0,
      descricao: map['descricao'] ?? '',
      exclusivoMeEpp: map['exclusivoMeEpp'] ?? false,
      itens: List<EstimativaItem>.from(
        (map['itens'] as List<dynamic>? ?? []).map((x) => EstimativaItem.fromMap(x)),
      ),
    );
  }

  EstimativaLote copyWith({
    int? numero,
    String? descricao,
    bool? exclusivoMeEpp,
    List<EstimativaItem>? itens,
  }) {
    return EstimativaLote(
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      exclusivoMeEpp: exclusivoMeEpp ?? this.exclusivoMeEpp,
      itens: itens ?? this.itens,
    );
  }

  double getValorTotal(String calculoGlobal) {
    return itens.fold(0.0, (sum, item) => sum + item.getValorTotal(calculoGlobal));
  }
}
