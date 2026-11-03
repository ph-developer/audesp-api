/// Itens do edital que não vieram na importação da licitação (o relatório do
/// portal não traz itens sem propostas) podem ser incluídos como desertos.
abstract final class LicitacaoItensFaltantes {
  static const situacaoDeserto = 4;

  /// Números dos itens/lotes do edital ausentes na licitação, em ordem.
  static List<int> numeros(
    Iterable<Map<String, dynamic>> itensEdital,
    Iterable<Map<String, dynamic>> itensLicitacao,
  ) {
    final existentes = itensLicitacao
        .map((item) => (item['numeroItem'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
    return itensEdital
        .map((item) => (item['numeroItem'] as num?)?.toInt())
        .whereType<int>()
        .where((numero) => !existentes.contains(numero))
        .toSet()
        .toList()
      ..sort();
  }

  /// Monta os itens faltantes como desertos, sem licitantes.
  ///
  /// Tipo de orçamento/valor/proposta e as datas seguem o valor mais comum
  /// entre os itens já importados; o valor médio vem do valor unitário
  /// estimado no edital.
  static List<Map<String, dynamic>> desertos(
    Iterable<Map<String, dynamic>> itensEdital,
    Iterable<Map<String, dynamic>> itensLicitacao, {
    required DateTime hoje,
  }) {
    final existentes = itensLicitacao.toList();
    final faltantes = numeros(itensEdital, existentes).toSet();
    if (faltantes.isEmpty) return const [];

    final hojeIso = hoje.toIso8601String().substring(0, 10);
    final tipoOrcamento =
        _maisComum<int>(existentes, 'tipoOrcamento', _lerInt) ?? 2;
    final tipoProposta =
        _maisComum<int>(existentes, 'tipoProposta', _lerInt) ??
        (tipoOrcamento == 0 ? 2 : tipoOrcamento);
    final tipoValor =
        _maisComum<String>(existentes, 'tipoValor', _lerTipoValor) ??
        (tipoProposta == 3 ? 'P' : 'M');
    final dataSituacao =
        _maisComum<String>(existentes, 'dataSituacaoItem', _lerData) ?? hojeIso;
    final dataOrcamento =
        _maisComum<String>(existentes, 'dataOrcamento', _lerData) ??
        dataSituacao;

    final novos = <Map<String, dynamic>>[];
    final adicionados = <int>{};
    for (final itemEdital in itensEdital) {
      final numero = (itemEdital['numeroItem'] as num?)?.toInt();
      if (numero == null ||
          !faltantes.contains(numero) ||
          !adicionados.add(numero)) {
        continue;
      }
      final item = <String, dynamic>{
        'numeroItem': numero,
        'tipoOrcamento': tipoOrcamento,
        'situacaoCompraItemId': situacaoDeserto,
        'dataSituacaoItem': dataSituacao,
        'tipoValor': tipoValor,
        'tipoProposta': tipoProposta,
        'licitantes': <Map<String, dynamic>>[],
      };
      final valor = itemEdital['valorUnitarioEstimado'];
      if (tipoOrcamento != 0 && valor is num) {
        item['valor'] = double.parse(valor.toDouble().toStringAsFixed(4));
        item['dataOrcamento'] = dataOrcamento;
      }
      novos.add(item);
    }
    return novos;
  }

  static T? _maisComum<T>(
    List<Map<String, dynamic>> itens,
    String campo,
    T? Function(dynamic) ler,
  ) {
    final contagem = <T, int>{};
    for (final item in itens) {
      final valor = ler(item[campo]);
      if (valor != null) contagem[valor] = (contagem[valor] ?? 0) + 1;
    }
    T? melhor;
    var maior = 0;
    for (final entry in contagem.entries) {
      if (entry.value > maior) {
        melhor = entry.key;
        maior = entry.value;
      }
    }
    return melhor;
  }

  static int? _lerInt(dynamic valor) => valor is num ? valor.toInt() : null;

  static String? _lerTipoValor(dynamic valor) =>
      valor == 'M' || valor == 'P' ? valor as String : null;

  static String? _lerData(dynamic valor) {
    if (valor is! String) return null;
    final data = DateTime.tryParse(valor);
    if (data == null || data.toIso8601String().substring(0, 10) != valor) {
      return null;
    }
    return valor;
  }
}
