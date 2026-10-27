import 'licitacao_itens_resumo.dart';
import 'licitacao_pessoa.dart';

/// Regras condicionais da Licitação conforme o Modelo da Fase IV 2026 v04.
abstract final class LicitacaoRules {
  static DateTime dataMinimaSituacaoItem(DateTime hoje) {
    final ano = hoje.year - 30;
    final ultimoDia = DateTime(ano, hoje.month + 1, 0).day;
    return DateTime(
      ano,
      hoje.month,
      hoje.day > ultimoDia ? ultimoDia : hoje.day,
    );
  }

  static String? validarDataSituacaoItem(
    DateTime? data, {
    required DateTime hoje,
  }) {
    if (data == null) return 'Informe a data da situação do item.';
    final dia = DateTime(data.year, data.month, data.day);
    final diaHoje = DateTime(hoje.year, hoje.month, hoje.day);
    if (dia.isAfter(diaHoje)) {
      return 'A data da situação do item não pode ser posterior a hoje.';
    }
    if (dia.isBefore(dataMinimaSituacaoItem(hoje))) {
      return 'A data da situação do item deve estar nos últimos 30 anos.';
    }
    return null;
  }

  static String? validarValorOrcamento({
    required int? tipoOrcamento,
    required num? valor,
  }) {
    if (tipoOrcamento != null && tipoOrcamento != 0 && valor == null) {
      return 'Informe o valor médio dos orçamentos para o tipo de orçamento selecionado.';
    }
    return null;
  }

  static String? validarDataOrcamento({
    required num? valor,
    required DateTime? dataOrcamento,
  }) {
    if (valor != null && dataOrcamento == null) {
      return 'Informe a data do orçamento quando houver valor médio dos orçamentos.';
    }
    return null;
  }

  static String? validarLicitantesDuplicados(
    Iterable<Map<String, dynamic>> licitantes, {
    required Object? numeroItem,
  }) {
    final identificacoes = <String>{};
    for (final licitante in licitantes) {
      final tipo = licitante['tipoPessoaId'] as String? ?? '';
      final ni = normalizarNiPessoa(
        tipo,
        licitante['niPessoa'] as String? ?? '',
      );
      if (!identificacoes.add('$tipo|$ni')) {
        return 'Item $numeroItem: o licitante $tipo $ni foi informado mais de uma vez.';
      }
    }
    return null;
  }

  static String? validarLicitantesItem(
    Map<String, dynamic> item, {
    Map<String, dynamic>? edital,
  }) {
    final numero = item['numeroItem'];
    final licitantes = (item['licitantes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final erroDuplicados = validarLicitantesDuplicados(
      licitantes,
      numeroItem: numero,
    );
    if (erroDuplicados != null) return erroDuplicados;

    final modalidade = edital?['modalidadeId'] as int?;
    if (modalidade != null &&
        !{8, 9, 12}.contains(modalidade) &&
        item['situacaoCompraItemId'] == 2 &&
        licitantes.isEmpty) {
      return 'Item $numero homologado: informe ao menos um licitante.';
    }

    final itemEdital = (edital?['itensCompra'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((e) => e['numeroItem'] == numero)
        .firstOrNull;
    // Sem a referência local de SRP/benefício, a quantidade fica a cargo do servidor.
    if (edital?['srp'] == false && itemEdital?['tipoBeneficioId'] != null) {
      final limite = itemEdital!['tipoBeneficioId'] == 3 ? 2 : 1;
      if (quantidadeVencedoresDoItem(item) > limite) {
        return 'Item $numero: permitido no máximo $limite vencedor(es)${limite == 2 ? ' para cota reservada ME/EPP' : ''} em edital sem SRP.';
      }
    }
    return null;
  }

  static String? validarItens(
    Iterable<Map<String, dynamic>> itens, {
    Map<String, dynamic>? edital,
    required DateTime hoje,
  }) {
    final lista = itens.toList();
    final numeros = <int>{};
    for (final item in lista) {
      final numero = (item['numeroItem'] as num?)?.toInt();
      if (numero != null && !numeros.add(numero)) {
        return 'Item $numero repetido. Não é permitido enviar itens duplicados.';
      }
    }
    for (final itemEdital in edital?['itensCompra'] as List<dynamic>? ?? []) {
      final numero = (itemEdital['numeroItem'] as num?)?.toInt();
      if (numero != null && !numeros.contains(numero)) {
        return 'Item $numero do edital não foi informado na licitação.';
      }
    }
    for (final item in lista) {
      final numero = item['numeroItem'];
      final erroDados =
          validarDataSituacaoItem(
            _lerData(item['dataSituacaoItem']),
            hoje: hoje,
          ) ??
          validarValorOrcamento(
            tipoOrcamento: item['tipoOrcamento'] as int?,
            valor: item['valor'] as num?,
          ) ??
          validarDataOrcamento(
            valor: item['valor'] as num?,
            dataOrcamento: _lerData(item['dataOrcamento']),
          );
      if (erroDados != null) return 'Item $numero: $erroDados';
      final erroLicitantes = validarLicitantesItem(item, edital: edital);
      if (erroLicitantes != null) return erroLicitantes;
    }
    return null;
  }

  static DateTime? _lerData(dynamic value) {
    if (value is! String) return null;
    final data = DateTime.tryParse(value);
    if (data == null || data.toIso8601String().substring(0, 10) != value) {
      return null;
    }
    return data;
  }

  static String? validarPercentualGarantia({
    required int? exigenciaGarantiaLicitantes,
    required num? percentualValor,
  }) {
    if (exigenciaGarantiaLicitantes != 1) return null;
    if (percentualValor == null) {
      return 'Informe o percentual da garantia quando a exigência for "Sim".';
    }
    if (!percentualValor.isFinite ||
        percentualValor < 0 ||
        percentualValor > 100) {
      return 'O percentual da garantia deve estar entre 0 e 100.';
    }
    return null;
  }

  static String? validarNomeIndice({
    required int? tipoIndice,
    required String? nomeIndice,
  }) {
    if (tipoIndice != 8) return null;
    final nome = nomeIndice?.trim() ?? '';
    if (nome.length < 3 || nome.length > 50) {
      return 'Informe o nome do índice "Outro" com 3 a 50 caracteres.';
    }
    return null;
  }

  static String? validarEnvio(
    Map<String, dynamic> documento, {
    Map<String, dynamic>? edital,
    required DateTime hoje,
  }) {
    final erroGarantia = validarPercentualGarantia(
      exigenciaGarantiaLicitantes:
          documento['exigenciaGarantiaLicitantes'] as int?,
      percentualValor: documento['percentualValor'] as num?,
    );
    if (erroGarantia != null) return erroGarantia;

    for (final indice
        in documento['indicesEconomicos'] as List<dynamic>? ?? []) {
      final erroNome = validarNomeIndice(
        tipoIndice: indice['tipoIndice'] as int?,
        nomeIndice: indice['nomeIndice'] as String?,
      );
      if (erroNome != null) return erroNome;
    }
    return validarItens(
      (documento['itens'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      edital: edital,
      hoje: hoje,
    );
  }
}
