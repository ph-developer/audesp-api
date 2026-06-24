class EstimativaOrcamento {
  final String fornecedorId;
  final double valorUnitario;

  EstimativaOrcamento({
    required this.fornecedorId,
    required this.valorUnitario,
  });

  Map<String, dynamic> toMap() {
    return {'fornecedorId': fornecedorId, 'valorUnitario': valorUnitario};
  }

  factory EstimativaOrcamento.fromMap(Map<String, dynamic> map) {
    return EstimativaOrcamento(
      fornecedorId: map['fornecedorId'] ?? '',
      valorUnitario: (map['valorUnitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  EstimativaOrcamento copyWith({String? fornecedorId, double? valorUnitario}) {
    return EstimativaOrcamento(
      fornecedorId: fornecedorId ?? this.fornecedorId,
      valorUnitario: valorUnitario ?? this.valorUnitario,
    );
  }
}
