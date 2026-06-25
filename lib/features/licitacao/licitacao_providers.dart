import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

final licitacoesDraftProvider = FutureProvider<List<Licitacao>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('draft');
});

final licitacoesEnviadasProvider = FutureProvider<List<Licitacao>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('sent');
});
