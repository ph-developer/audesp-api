import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

/// Stream de empenhos de um ajuste específico.
final empenhosByAjusteProvider =
    StreamProvider.family<List<Empenho>, int>((ref, ajusteId) {
  return ref.watch(empenhosDaoProvider).watchByAjuste(ajusteId);
});
