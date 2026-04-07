import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

/// Stream de ajustes em rascunho, ordenados por updatedAt desc.
final ajustesDraftProvider = StreamProvider<List<Ajuste>>((ref) {
  return ref.watch(ajustesDaoProvider).watchByStatus('draft');
});

/// Stream de ajustes enviados, ordenados por updatedAt desc.
final ajustesEnviadosProvider = StreamProvider<List<Ajuste>>((ref) {
  return ref.watch(ajustesDaoProvider).watchByStatus('sent');
});
