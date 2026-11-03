import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/condutores_dao.dart';
import '../../core/database/database_providers.dart';
import 'models/condutor.dart';

final licitacoesDraftProvider = FutureProvider<List<Licitacao>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('draft');
});

final licitacoesEnviadasProvider = FutureProvider<List<Licitacao>>((ref) {
  return ref.watch(licitacoesDaoProvider).watchByStatus('sent');
});

final condutoresProvider =
    AsyncNotifierProvider<CondutoresNotifier, List<Condutor>>(
      CondutoresNotifier.new,
    );

class CondutoresNotifier extends AsyncNotifier<List<Condutor>> {
  @override
  Future<List<Condutor>> build() {
    return ref.read(condutoresDaoProvider).getAll();
  }

  Future<Condutor> adicionar(String nome, String cpf) async {
    final novo = await ref.read(condutoresDaoProvider).insert(nome, cpf);
    final lista = [...await future, novo]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    state = AsyncData(lista);
    return novo;
  }

  Future<void> remover(int id) async {
    await ref.read(condutoresDaoProvider).delete(id);
    final lista = await future;
    state = AsyncData(lista.where((c) => c.id != id).toList());
  }
}
