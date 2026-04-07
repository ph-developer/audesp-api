import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

/// Stream de todas as licitações ordenadas por updatedAt desc.
final licitacoesStreamProvider = StreamProvider<List<Licitacoe>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchAll();
});

/// Stream filtrado por status.
final licitacoesDraftProvider = StreamProvider<List<Licitacoe>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('draft');
});

final licitacoesEnviadasProvider = StreamProvider<List<Licitacoe>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('sent');
});
