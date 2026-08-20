import 'licitacao_domain.dart';

class LicitacaoFornecedorResumo {
  final String niPessoa;
  final String tipoPessoaId;
  final String nomeRazaoSocial;
  final int quantidadeItens;
  final List<int> numerosItens;
  final double valorTotal;

  const LicitacaoFornecedorResumo({
    required this.niPessoa,
    required this.tipoPessoaId,
    required this.nomeRazaoSocial,
    required this.quantidadeItens,
    required this.numerosItens,
    required this.valorTotal,
  });
}

class LicitacaoItensResumo {
  final int quantidadeItens;
  final int quantidadeLicitantesDistintos;
  final Map<int?, int> itensPorSituacao;
  final double valorMedioTodosItens;
  final double valorMedioItensComVencedor;
  final double valorVencedores;
  final List<LicitacaoFornecedorResumo> fornecedoresVencedores;

  const LicitacaoItensResumo({
    required this.quantidadeItens,
    required this.quantidadeLicitantesDistintos,
    required this.itensPorSituacao,
    required this.valorMedioTodosItens,
    required this.valorMedioItensComVencedor,
    required this.valorVencedores,
    this.fornecedoresVencedores = const [],
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
    final fornecedoresMap = <String, _FornecedorAcumulador>{};
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

      final isLote = isItemLote(item);
      final licitantes = _licitantesDoItem(item);
      for (final licitante in licitantes) {
        final ni = (licitante['niPessoa'] as String? ?? '')
            .trim()
            .toUpperCase()
            .replaceAll(RegExp(r'[.\-/\s]'), '');
        final tipo = licitante['tipoPessoaId'] as String? ?? '';
        if (ni.isNotEmpty) {
          licitantesDistintos.add('$tipo|$ni');
        }

        if (_isVencedor(licitante)) {
          final key = ni.isNotEmpty
              ? '$tipo|$ni'
              : (licitante['nomeRazaoSocial'] as String? ?? 'Desconhecido');
          final nome = (licitante['nomeRazaoSocial'] as String? ?? '').trim();
          final val = _toDouble(licitante['valor']) ?? 0.0;
          final totalItem = isLote ? val : (val * quantidade);

          final acum = fornecedoresMap.putIfAbsent(
            key,
            () => _FornecedorAcumulador(
              niPessoa: licitante['niPessoa'] as String? ?? ni,
              tipoPessoaId: tipo,
              nomeRazaoSocial: nome,
            ),
          );

          if (acum.nomeRazaoSocial.isEmpty && nome.isNotEmpty) {
            acum.nomeRazaoSocial = nome;
          }
          if (!acum.numerosItens.contains(numeroItem)) {
            acum.numerosItens.add(numeroItem);
          }
          acum.valorTotal += totalItem;
        }
      }

      if (licitantes.any(_isVencedor)) {
        valorMedioComVencedor += valorMedio * quantidade;
        valorVencedoresTotal += (valorVencedorDoItem(item) ?? 0.0) * quantidade;
      }
    }

    final listaFornecedores =
        fornecedoresMap.values.map((f) => f.toResumo()).toList()
          ..sort((a, b) => b.valorTotal.compareTo(a.valorTotal));

    return LicitacaoItensResumo(
      quantidadeItens: lista.length,
      quantidadeLicitantesDistintos: licitantesDistintos.length,
      itensPorSituacao: porSituacao,
      valorMedioTodosItens: valorMedioTotal,
      valorMedioItensComVencedor: valorMedioComVencedor,
      valorVencedores: valorVencedoresTotal,
      fornecedoresVencedores: listaFornecedores,
    );
  }
}

class _FornecedorAcumulador {
  final String niPessoa;
  final String tipoPessoaId;
  String nomeRazaoSocial;
  final List<int> numerosItens = [];
  double valorTotal = 0.0;

  _FornecedorAcumulador({
    required this.niPessoa,
    required this.tipoPessoaId,
    required this.nomeRazaoSocial,
  });

  LicitacaoFornecedorResumo toResumo() {
    return LicitacaoFornecedorResumo(
      niPessoa: niPessoa,
      tipoPessoaId: tipoPessoaId,
      nomeRazaoSocial: nomeRazaoSocial,
      quantidadeItens: numerosItens.length,
      numerosItens: List.unmodifiable(numerosItens..sort()),
      valorTotal: valorTotal,
    );
  }
}
bool isItemLote(Map<String, dynamic> item) {
  final tipoOrcamento = (item['tipoOrcamento'] as num?)?.toInt();
  final tipoProposta = (item['tipoProposta'] as num?)?.toInt();
  if (tipoOrcamento == 1 || tipoProposta == 1) return true;
  if (item['tipoEstimativa'] == 'lote') return true;
  return false;
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
        (licitante) => (licitante['nomeRazaoSocial'] as String? ?? '').trim(),
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
