import 'licitacao_itens_resumo.dart';
import 'licitacao_pessoa.dart';

class FornecedorVencedor {
  final String niPessoa;
  final String tipoPessoaId;
  final String nomeRazaoSocial;
  final List<int> itens;
  final double? valorSugerido;

  const FornecedorVencedor({
    required this.niPessoa,
    required this.tipoPessoaId,
    required this.nomeRazaoSocial,
    required this.itens,
    required this.valorSugerido,
  });
}

/// Sugestões editáveis para Ata e Ajuste, a partir da licitação enviada.
abstract final class LicitacaoResultado {
  static Set<int> itensHomologados(Map<String, dynamic> licitacaoDoc) => {
    for (final item in _itens(licitacaoDoc))
      if (item['situacaoCompraItemId'] == 2 && item['numeroItem'] is num)
        (item['numeroItem'] as num).toInt(),
  };

  static List<FornecedorVencedor> fornecedoresVencedores(
    Map<String, dynamic> licitacaoDoc,
    Map<String, dynamic> editalDoc, {
    Set<int>? limitarItens,
  }) {
    final quantidades = <int, double?>{
      for (final item
          in (editalDoc['itensCompra'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>())
        if (item['numeroItem'] is num)
          (item['numeroItem'] as num).toInt(): _numero(item['quantidade']),
    };
    final fornecedores = <(String, String), _FornecedorAcumulador>{};

    for (final item in _itens(licitacaoDoc)) {
      final numeroItem = (item['numeroItem'] as num?)?.toInt();
      if (numeroItem == null ||
          item['situacaoCompraItemId'] != 2 ||
          (limitarItens != null && !limitarItens.contains(numeroItem))) {
        continue;
      }
      final lote = isItemLote(item);
      final quantidade = quantidades[numeroItem];
      for (final licitante
          in (item['licitantes'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()) {
        if (licitante['resultadoHabilitacao'] != 1) continue;
        final tipo = licitante['tipoPessoaId'] as String? ?? '';
        final ni = normalizarNiPessoa(
          tipo,
          licitante['niPessoa'] as String? ?? '',
        );
        final fornecedor = fornecedores.putIfAbsent((
          tipo,
          ni,
        ), () => _FornecedorAcumulador(niPessoa: ni, tipoPessoaId: tipo));
        final nome = (licitante['nomeRazaoSocial'] as String? ?? '').trim();
        if (fornecedor.nomeRazaoSocial.isEmpty && nome.isNotEmpty) {
          fornecedor.nomeRazaoSocial = nome;
        }
        fornecedor.itens.add(numeroItem);

        final valor = _numero(licitante['valor']);
        if (item['tipoValor'] == 'P' ||
            item['tipoProposta'] == 3 ||
            valor == null ||
            (!lote && quantidade == null)) {
          // Um item ambíguo invalida a sugestão total do fornecedor.
          fornecedor.valorSugerido = null;
        } else if (fornecedor.valorSugerido != null) {
          fornecedor.valorSugerido =
              fornecedor.valorSugerido! + (lote ? valor : valor * quantidade!);
        }
      }
    }

    return fornecedores.values.map((f) => f.toFornecedor()).toList()
      ..sort((a, b) => a.itens.first.compareTo(b.itens.first));
  }

  static Iterable<Map<String, dynamic>> _itens(
    Map<String, dynamic> documento,
  ) => (documento['itens'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>();

  static double? _numero(dynamic valor) => valor is num
      ? valor.toDouble()
      : double.tryParse(valor?.toString() ?? '');
}

class _FornecedorAcumulador {
  final String niPessoa;
  final String tipoPessoaId;
  String nomeRazaoSocial = '';
  final Set<int> itens = {};
  double? valorSugerido = 0;

  _FornecedorAcumulador({required this.niPessoa, required this.tipoPessoaId});

  FornecedorVencedor toFornecedor() => FornecedorVencedor(
    niPessoa: niPessoa,
    tipoPessoaId: tipoPessoaId,
    nomeRazaoSocial: nomeRazaoSocial,
    itens: List.unmodifiable(itens.toList()..sort()),
    valorSugerido: valorSugerido,
  );
}
