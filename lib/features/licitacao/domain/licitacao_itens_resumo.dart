import 'licitacao_domain.dart';

class LicitacaoItensResumo {
  final int quantidadeItens;
  final int quantidadeLicitantesDistintos;
  final Map<int?, int> itensPorSituacao;
  final double valorMedioTodosItens;
  final double valorMedioItensComVencedor;
  final double valorVencedores;

  const LicitacaoItensResumo({
    required this.quantidadeItens,
    required this.quantidadeLicitantesDistintos,
    required this.itensPorSituacao,
    required this.valorMedioTodosItens,
    required this.valorMedioItensComVencedor,
    required this.valorVencedores,
  });

  factory LicitacaoItensResumo.calcular(
    Iterable<Map<String, dynamic>> itens, {
    required Map<int, double> quantidadesPorNumeroItem,
  }) {
    final lista = itens.toList();
    final licitantesDistintos = <String>{};
    final porSituacao = <int?, int>{
      for (final situacaoId in kSituacaoCompraItem.keys) situacaoId: 0,
    };
    var valorMedioTotal = 0.0;
    var valorMedioComVencedor = 0.0;
    var valorVencedoresTotal = 0.0;

    for (final item in lista) {
      final numeroItem = (item['numeroItem'] as num).toInt();
      final quantidade = quantidadesPorNumeroItem[numeroItem]!;
      final situacaoId = (item['situacaoCompraItemId'] as num?)?.toInt();
      porSituacao[situacaoId] = (porSituacao[situacaoId] ?? 0) + 1;

      final valorMedio = valorMedioDoItem(item) ?? 0.0;
      valorMedioTotal += valorMedio * quantidade;

      final licitantes = _licitantesDoItem(item);
      for (final licitante in licitantes) {
        final ni = (licitante['niPessoa'] as String? ?? '')
            .trim()
            .toUpperCase()
            .replaceAll(RegExp(r'[.\-/\s]'), '');
        if (ni.isNotEmpty) {
          final tipo = licitante['tipoPessoaId'] as String? ?? '';
          licitantesDistintos.add('$tipo|$ni');
        }
      }

      if (licitantes.any(_isVencedor)) {
        valorMedioComVencedor += valorMedio * quantidade;
        valorVencedoresTotal +=
            (valorVencedorDoItem(item) ?? 0.0) * quantidade;
      }
    }

    return LicitacaoItensResumo(
      quantidadeItens: lista.length,
      quantidadeLicitantesDistintos: licitantesDistintos.length,
      itensPorSituacao: porSituacao,
      valorMedioTodosItens: valorMedioTotal,
      valorMedioItensComVencedor: valorMedioComVencedor,
      valorVencedores: valorVencedoresTotal,
    );
  }
}

double? valorMedioDoItem(Map<String, dynamic> item) => _toDouble(item['valor']);

double? valorVencedorDoItem(Map<String, dynamic> item) {
  final valores = _licitantesDoItem(item)
      .where(_isVencedor)
      .map((licitante) => _toDouble(licitante['valor']))
      .whereType<double>()
      .toList();
  if (valores.isEmpty) return null;
  return valores.fold<double>(0.0, (total, valor) => total + valor);
}

List<String> nomesVencedoresDoItem(Map<String, dynamic> item) {
  return _licitantesDoItem(item)
      .where(_isVencedor)
      .map(
        (licitante) =>
            (licitante['nomeRazaoSocial'] as String? ?? '').trim(),
      )
      .where((nome) => nome.isNotEmpty)
      .toSet()
      .toList();
}

List<Map<String, dynamic>> _licitantesDoItem(Map<String, dynamic> item) {
  return (item['licitantes'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
}

bool _isVencedor(Map<String, dynamic> licitante) =>
    (licitante['resultadoHabilitacao'] as num?)?.toInt() == 1;

double? _toDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '');
}
