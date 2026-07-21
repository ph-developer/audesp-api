import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_providers.dart';
import '../models/xsd_licitacao_models.dart';

final xsdComissaoProvider =
    AsyncNotifierProvider<XsdComissaoNotifier, List<XsdComissaoMembro>>(() {
      return XsdComissaoNotifier();
    });

class XsdComissaoNotifier extends AsyncNotifier<List<XsdComissaoMembro>> {
  @override
  Future<List<XsdComissaoMembro>> build() async {
    return _fetch();
  }

  Future<List<XsdComissaoMembro>> _fetch() async {
    final dao = ref.read(xsdComissaoDaoProvider);
    return dao.findAll();
  }

  Future<void> addMembro(XsdComissaoMembro membro) async {
    final dao = ref.read(xsdComissaoDaoProvider);
    await dao.insert(membro);

    // As the DAO doesn't return the inserted row with ID, we re-fetch everything
    // to make sure we have the correct IDs for deletion later.
    final list = await _fetch();
    state = AsyncData(list);
  }

  Future<void> removeMembro(int id) async {
    final dao = ref.read(xsdComissaoDaoProvider);
    await dao.delete(id);
    final previousState = await future;
    state = AsyncData(previousState.where((a) => a.id != id).toList());
  }
}
