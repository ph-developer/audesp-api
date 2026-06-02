import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

final atasDraftProvider = FutureProvider<List<Ata>>((ref) {
  return ref.watch(atasDaoProvider).watchByStatus('draft');
});

final atasEnviadasProvider = FutureProvider<List<Ata>>((ref) {
  return ref.watch(atasDaoProvider).watchByStatus('sent');
});
