import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_providers.dart';

/// Stream of all editais ordered by updatedAt desc.
final editaisStreamProvider = StreamProvider<List<Editai>>((ref) {
  return ref.watch(editaisDaoProvider).watchAll();
});

/// Stream filtered by status.
final editaisDraftProvider = StreamProvider<List<Editai>>((ref) {
  return ref.watch(editaisDaoProvider).watchByStatus('draft');
});

final editaisEnviadosProvider = StreamProvider<List<Editai>>((ref) {
  return ref.watch(editaisDaoProvider).watchByStatus('sent');
});
