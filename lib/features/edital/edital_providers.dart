import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

final editaisDraftProvider = FutureProvider<List<Edital>>((ref) {
  return ref.watch(editaisDaoProvider).watchByStatus('draft');
});

final editaisEnviadosProvider = FutureProvider<List<Edital>>((ref) {
  return ref.watch(editaisDaoProvider).watchByStatus('sent');
});
