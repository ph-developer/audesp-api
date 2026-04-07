import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

/// Stream de termos de contrato de um ajuste específico.
final termosByAjusteProvider =
    StreamProvider.family<List<TermosContratoData>, int>((ref, ajusteId) {
  return ref.watch(termosContratoDaoProvider).watchByAjuste(ajusteId);
});
