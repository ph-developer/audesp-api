class EstimativaExclusividadeResumo {
  final double valorTotal;
  final double valorSelecionado;
  final double percentualSelecionado;

  const EstimativaExclusividadeResumo({
    required this.valorTotal,
    required this.valorSelecionado,
    required this.percentualSelecionado,
  });

  factory EstimativaExclusividadeResumo.calcular(
    Iterable<({double valor, bool selecionado})> entradas,
  ) {
    var total = 0.0;
    var selecionado = 0.0;
    for (final entrada in entradas) {
      total += entrada.valor;
      if (entrada.selecionado) {
        selecionado += entrada.valor;
      }
    }

    return EstimativaExclusividadeResumo(
      valorTotal: total,
      valorSelecionado: selecionado,
      percentualSelecionado: percentualDoTotal(selecionado, total),
    );
  }
}

double percentualDoTotal(double valor, double total) {
  if (total == 0) return 0;
  return (valor / total) * 100;
}
