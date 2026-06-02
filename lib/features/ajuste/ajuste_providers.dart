import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

final ajustesDraftProvider = FutureProvider<List<Ajuste>>((ref) {
  return ref.watch(ajustesDaoProvider).watchByStatus('draft');
});

final ajustesEnviadosProvider = FutureProvider<List<Ajuste>>((ref) {
  return ref.watch(ajustesDaoProvider).watchByStatus('sent');
});
