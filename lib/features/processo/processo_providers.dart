import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import 'domain/processo.dart';

final processosProvider = FutureProvider.autoDispose<List<Processo>>((
  ref,
) async {
  final (editais, licitacoes, atas, ajustes, estimativas) = await (
    ref.watch(editaisDaoProvider).watchAll(),
    ref.watch(licitacoesDaoProvider).watchAll(),
    ref.watch(atasDaoProvider).watchAll(),
    ref.watch(ajustesDaoProvider).watchAll(),
    ref.watch(estimativasDaoProvider).listResumo(),
  ).wait;

  return Processo.agrupar(
    editais: editais,
    licitacoes: licitacoes,
    atas: atas,
    ajustes: ajustes,
    estimativas: estimativas,
  );
});
