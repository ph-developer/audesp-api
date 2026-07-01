import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos/assinaturas_dao.dart';
import '../models/assinatura_model.dart';

final assinaturasProvider = AsyncNotifierProvider<AssinaturasNotifier, List<AssinaturaModel>>(() {
  return AssinaturasNotifier();
});

class AssinaturasNotifier extends AsyncNotifier<List<AssinaturaModel>> {
  @override
  Future<List<AssinaturaModel>> build() async {
    return _fetch();
  }

  Future<List<AssinaturaModel>> _fetch() async {
    final dao = ref.read(assinaturasDaoProvider);
    return dao.getAll();
  }

  Future<void> addAssinatura(String nome, String cargo) async {
    final dao = ref.read(assinaturasDaoProvider);
    final novaAssinatura = await dao.insert(nome, cargo);
    final previousState = await future;
    final newState = [...previousState, novaAssinatura];
    newState.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    state = AsyncData(newState);
  }

  Future<void> removeAssinatura(int id) async {
    final dao = ref.read(assinaturasDaoProvider);
    await dao.delete(id);
    final previousState = await future;
    state = AsyncData(previousState.where((a) => a.id != id).toList());
  }
}
