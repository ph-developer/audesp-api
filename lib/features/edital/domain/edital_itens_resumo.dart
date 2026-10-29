/// Totais dos itens de compra do edital, exibidos no resumo do formulário.
class EditalItensResumo {
  final int quantidadeItens;
  final int materiais;
  final int servicos;
  final int semValor;
  final int sigilosos;
  final double valorTotal;

  /// Itens e valor por tipo de benefício, em ordem de código. Itens sem
  /// benefício informado ficam de fora.
  final Map<int, ({int itens, double valor})> porBeneficio;

  const EditalItensResumo({
    required this.quantidadeItens,
    required this.materiais,
    required this.servicos,
    required this.semValor,
    required this.sigilosos,
    required this.valorTotal,
    required this.porBeneficio,
  });

  factory EditalItensResumo.calcular(Iterable<Map<String, dynamic>> itens) {
    var quantidade = 0;
    var materiais = 0;
    var servicos = 0;
    var semValor = 0;
    var sigilosos = 0;
    var total = 0.0;
    final porBeneficio = <int, ({int itens, double valor})>{};
    for (final item in itens) {
      final valor = (item['valorTotal'] as num?)?.toDouble() ?? 0;
      quantidade++;
      if (item['materialOuServico'] == 'S') {
        servicos++;
      } else {
        materiais++;
      }
      if (valor == 0) semValor++;
      if (item['orcamentoSigiloso'] == true) sigilosos++;
      total += valor;
      final beneficio = item['tipoBeneficioId'] as int?;
      if (beneficio != null) {
        final atual = porBeneficio[beneficio];
        porBeneficio[beneficio] = (
          itens: (atual?.itens ?? 0) + 1,
          valor: (atual?.valor ?? 0) + valor,
        );
      }
    }
    return EditalItensResumo(
      quantidadeItens: quantidade,
      materiais: materiais,
      servicos: servicos,
      semValor: semValor,
      sigilosos: sigilosos,
      valorTotal: total,
      porBeneficio: Map.fromEntries(
        porBeneficio.entries.toList()..sort((a, b) => a.key - b.key),
      ),
    );
  }

  /// Benefícios 1 a 3 são os voltados a ME/EPP.
  double get valorMeEpp => porBeneficio.entries
      .where((e) => e.key >= 1 && e.key <= 3)
      .fold(0.0, (soma, e) => soma + e.value.valor);

  double percentual(double valor) =>
      valorTotal == 0 ? 0 : (valor / valorTotal) * 100;
}
