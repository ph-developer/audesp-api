class EstimativaOrcamento {
  final String razaoSocial;
  final String cnpj;
  final String data;
  final double valorUnitario;

  EstimativaOrcamento({
    required this.razaoSocial,
    required this.cnpj,
    required this.data,
    required this.valorUnitario,
  });

  Map<String, dynamic> toMap() {
    return {
      'razaoSocial': razaoSocial,
      'cnpj': cnpj,
      'data': data,
      'valorUnitario': valorUnitario,
    };
  }

  factory EstimativaOrcamento.fromMap(Map<String, dynamic> map) {
    return EstimativaOrcamento(
      razaoSocial: map['razaoSocial'] ?? '',
      cnpj: map['cnpj'] ?? '',
      data: map['data'] ?? '',
      valorUnitario: (map['valorUnitario'] as num?)?.toDouble() ?? 0.0,
    );
  }

  EstimativaOrcamento copyWith({
    String? razaoSocial,
    String? cnpj,
    String? data,
    double? valorUnitario,
  }) {
    return EstimativaOrcamento(
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      data: data ?? this.data,
      valorUnitario: valorUnitario ?? this.valorUnitario,
    );
  }
}
