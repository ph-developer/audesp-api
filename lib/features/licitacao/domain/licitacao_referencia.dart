import 'dart:convert';

import '../../../core/database/models/licitacao.dart';

/// Referência local para conferir os itens de Ata e Ajuste.
abstract final class LicitacaoReferencia {
  static Licitacao? selecionar(Iterable<Licitacao> licitacoes) {
    final ordenadas = licitacoes.where((l) => l.status == 'sent').toList()
      ..sort((a, b) {
        final data = b.updatedAt.compareTo(a.updatedAt);
        return data != 0 ? data : b.id.compareTo(a.id);
      });
    return ordenadas.firstOrNull;
  }

  /// null indica ausência de referência legível; lista vazia é conferível.
  static Set<int>? numerosItens(Iterable<Licitacao> licitacoes) {
    final licitacao = selecionar(licitacoes);
    if (licitacao == null) return null;
    try {
      final documento =
          jsonDecode(licitacao.documentoJson) as Map<String, dynamic>;
      final itens = documento['itens'];
      if (itens is! List) return null;
      if (itens.any((item) => item is! Map || item['numeroItem'] is! int)) {
        return null;
      }
      return {for (final item in itens) item['numeroItem'] as int};
    } catch (_) {
      return null;
    }
  }

  static String? validarItens(
    Iterable<int> numeros, {
    Set<int>? numerosLicitacao,
  }) {
    final encontrados = <int>{};
    for (final numero in numeros) {
      if (!encontrados.add(numero)) {
        return 'Item $numero repetido. Não é permitido enviar itens duplicados.';
      }
      if (numerosLicitacao != null && !numerosLicitacao.contains(numero)) {
        return 'Item $numero não consta na licitação vinculada ao edital.';
      }
    }
    return null;
  }
}
