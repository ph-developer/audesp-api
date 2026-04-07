import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

/// Stream de todas as atas em rascunho, ordenadas por updatedAt desc.
final atasDraftProvider = StreamProvider<List<Ata>>((ref) {
  return ref.watch(atasDaoProvider).watchByStatus('draft');
});

/// Stream de todas as atas enviadas, ordenadas por updatedAt desc.
final atasEnviadasProvider = StreamProvider<List<Ata>>((ref) {
  return ref.watch(atasDaoProvider).watchByStatus('sent');
});
